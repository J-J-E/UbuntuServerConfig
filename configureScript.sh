#!/bin/bash

# Author: John Ehlen

# EXECUTE
# sudo chmod +x configureScript.sh
# ./configureScript.sh

#INSTRUCTIONS
# Change "true" to "false" to ignore software setup

#######
##TODO: ADD OPENPORTS,CLOSEPORTS VARIABLE TO UFW TO ALLOW MORE PORT CUSTOMIZATION
#######

# Required only in the first time to execute this script
UPDATE_REPOSITORIES=true
UPGRADE_PACKAGES=true
AUTO_CLEAN=true
AUTO_REMOVE=true

#Additional Repos:
DOCKER=true
DOCKERIO=true
DOCKERCOMPOSE=true

#Auto Mount network drive, suppy path and true/false
MOUNT_NFS=false
AUTO_MOUNT_NFS=false
NFS_PATH="" 

# build-essential, git, curl, libs
REQUIRED=false

# Add color for user, host, folder and git branch
COLORIZE_TERMINAL=true

# Configure GIT
CONFIGURE_GITHUB=false
GITHUB_NAME="YOUR_NAME"
GITHUB_MAIL="YOUR_GITHUB_EMAIL"
GITHUB_USER="YOUR_USERNAME"

# Configure GITLAB
CONFIGURE_GITLAB=false
GITLAB_HOSTNAME="YOUR_GITLAB_DOMAIN"
GITLAB_MAIL="YOUR_GITLAB_EMAIL"

#Add User
ADDUSER=false
USERNAME=
USERPASS=
USERGRPS=adm,sudo
COPYROOTSSH=false

#SSH Configuration
SETSSH=false
SSHPORT=22
UFWSSHRULE=true
ALLOWROOTLOGIN=true
ALLOWPASSAUTH=true

#Firewall Configuration
# a rule will be auto configured for the ssh if a new default
# was specified above
HTTPPORTS=true
OPENPORTS=
CLOSEPORTS=
UFWENABLE=true
FAIL2BAN=true

#Set Timezone
SETTIMEZONE=true
TZ=America/Phoenix

#Set Hostname
SETHOSTNAME=false
HOSTNAME=

# paths
LOG_SCRIPT=./log_script.txt
GITCONFIG=/etc/gitconfig
SSH_FOLDER=~/.ssh
SSHCONFIG="$SSH_FOLDER/config"
DOWNLOADS=~/Downloads
BASHRC=~/.bashrc
SSHDCONF=/etc/ssh/sshd_config


function aptinstall {
    echo installing $1
    shift
    sudo apt-get -y -f install "$@" >$LOG_SCRIPT 2>$LOG_SCRIPT
}

function snapinstall {
    echo installing $1
    shift
    sudo snap install "$@" >$LOG_SCRIPT 2>$LOG_SCRIPT
}


if $UPDATE_REPOSITORIES; then
  echo "*** Update Respositories"
  sudo apt-get update
fi

if $UPGRADE_PACKAGES; then
  echo "*** Upgrade Packages"
  sudo apt-get -y upgrade
fi

if $AUTO_CLEAN; then
  echo "*** Set AUTOCLEAN"
  sudo apt autoclean -y
fi

if $AUTO_REMOVE; then
  echo "*** Set AUTOREMOVE"
  sudo apt autoremove -y
fi


if $AUTO_MOUNT_NFS; then
  echo "*** MOUNTING NFS"
  echo $NFS_PATH >> /etc/fstab
fi


if $REQUIRED; then
	aptinstall "Build essential" build-essential
	aptinstall Git git-core
	aptinstall CURL curl
fi

if $DOCKER; then
	aptinstall Docker docker
fi

if $DOCKERIO; then
	aptinstall DockerIO docker.io
fi

if $DOCKERCOMPOSE; then
	aptinstall "Docker Compose" docker-compose
fi


if $COLORIZE_TERMINAL; then
	echo -e "function parse_git_branch () {" >> $BASHRC
	echo -e "  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'" >> $BASHRC
	echo -e "}" >> $BASHRC
	echo -e 'RED="\[\033[01;31m\]"' >> $BASHRC
	echo -e 'YELLOW="\[\033[01;33m\]"' >> $BASHRC
	echo -e 'GREEN="\[\033[01;32m\]"' >> $BASHRC
	echo -e 'BLUE="\[\033[01;34m\]"' >> $BASHRC
	echo -e 'NO_COLOR="\[\033[00m\]"' >> $BASHRC
	echo -e 'PS1="$GREEN\u@\h$NO_COLOR:$BLUE\w$YELLOW\$(parse_git_branch)$NO_COLOR\$ "' >> $BASHRC
	source $BASHRC
fi


echo "*** cleaning packages"
sudo apt-get clean


if $ADDUSER; then
	# Am i Root user?
	if [ $(id -u) -eq 0 ]; then
		egrep "^$USERNAME" /etc/passwd >/dev/null
		if [ $? -eq 0 ]; then
			echo "$USERNAME exists!"
		else
			pass=$(perl -e 'print crypt($ARGV[0], "password")' $USERPASS)
			sudo useradd -m -p "$pass" "$USERNAME"
			sudo usermod -aG $USERGRPS $USERNAME
			[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
			
			if $COPYROOTSSH; then 
				sudo mkdir -p /home/$USERNAME/.ssh/
				sudo cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys
				sudo chmod 600 /home/$USERNAME/.ssh/authorized_keys
				sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
			fi
		fi
	else
		echo "Only root may add a user to the system."
	fi
fi


if $CONFIGURE_GITHUB;then
  sudo rm $GITCONFIG || echo "$GITCONFIG didn't exist, couldn't remove. Continuing."
  sudo touch $GITCONFIG
  sudo chmod 777 $GITCONFIG
  echo -e "[user]" >> $GITCONFIG
  echo -e "  name = $GITHUB_NAME" >> $GITCONFIG
  echo -e "  email = $GITHUB_MAIL" >> $GITCONFIG
  echo -e "[core]" >> $GITCONFIG
  echo -e "  editor = vim -f" >> $GITCONFIG
  echo -e "[alias]" >> $GITCONFIG
  echo -e "  df = diff" >> $GITCONFIG
  echo -e "  st = status" >> $GITCONFIG
  echo -e "  cm = commit" >> $GITCONFIG
  echo -e "  ch = checkout" >> $GITCONFIG
  echo -e "  br = branch" >> $GITCONFIG
  echo -e "  lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative" >> $GITCONFIG
  echo -e "    ctags = !.git/hooks/ctags" >> $GITCONFIG
  echo -e "[color]" >> $GITCONFIG
  echo -e "  branch = auto" >> $GITCONFIG
  echo -e "  diff = auto" >> $GITCONFIG
  echo -e "  grep = auto" >> $GITCONFIG
  echo -e "  interactive = auto" >> $GITCONFIG
  echo -e "  status = auto" >> $GITCONFIG
  echo -e "  ui = 1" >> $GITCONFIG
  echo -e "[branch]" >> $GITCONFIG
  echo -e "  autosetuprebase = always" >> $GITCONFIG
  echo -e "[github]" >> $GITCONFIG
  echo -e "  user = $GITHUB_USER" >> $GITCONFIG

  ssh-keygen -t rsa -b 4096 -C "$GITHUB_MAIL" -N "" -f $SSH_FOLDER/id_rsa_github
	echo ""
	echo ""
	echo "**********************"
	echo "CONFIGURE GIT USER"
	echo ""
	echo "Add the public ssh key 'https://github.com/settings/ssh':"
	echo ""
	cat $SSH_FOLDER/id_rsa_github.pub
	echo ""
	echo "**********************"
	
  touch $SSHCONFIG
  echo -e "#Github (default)" >> $SSHCONFIG
  echo -e "  Host github" >> $SSHCONFIG
  echo -e "  HostName github.com" >> $SSHCONFIG
  echo -e "  User git" >> $SSHCONFIG
  echo -e "  IdentityFile $SSH_FOLDER/id_rsa_github" >> $SSHCONFIG
fi

if $CONFIGURE_GITLAB;then
  ssh-keygen -t rsa -b 4096 -C "$GITLAB_MAIL" -N "" -f $SSH_FOLDER/id_rsa_gitlab
	echo ""
	echo ""
	echo "**********************"
	echo "CONFIGURE GITLAB USER"
	echo ""
	echo "Adding public key to gitlab:"
	echo ""
	cat $SSH_FOLDER/id_rsa_gitlab.pub
	echo ""
	echo "**********************"

  touch $SSHCONFIG
  echo -e "#Gitlab" >> $SSHCONFIG
  echo -e "  Host gitlab" >> $SSHCONFIG
  echo -e "  HostName $GITLAB_HOSTNAME" >> $SSHCONFIG
  echo -e "  User git" >> $SSHCONFIG
  echo -e "  IdentityFile $SSH_FOLDER/id_rsa_gitlab" >> $SSHCONFIG
fi

#CONFIGURE SSHD FILE
if $SETSSH;then
	sudo sed -i "s/#Port 22/Port $SSHPORT/" $SSHDCONF
	sudo systemctl reload sshd
fi

if $UFWSSHRULE;then
	sudo ufw allow $SSHPORT/tcp
	sudo systemctl reload sshd
fi


if ! $ALLOWROOTLOGIN; then
	sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" $SSHDCONF
elif $ALLOWROOTLOGIN; then
	sudo sed -i "s/PermitRootLogin no/PermitRootLogin yes/" $SSHDCONF
fi


if ! $ALLOWPASSAUTH; then
	sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" $SSHDCONF
elif $ALLOWPASSAUTH; then
	sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" $SSHDCONF
fi



#Firewall Configuration

if $HTTPPORTS;then
	sudo ufw allow proto tcp from any to any port 80,443
fi

if $FAIL2BAN;then
	aptinstall fail2ban fail2ban
	sudo systemctl enable fail2ban --now
fi


#Set Timezone
if $SETTIMEZONE; then
        sudo timedatectl set-timezone $TZ
fi


#Set Hostname
if $SETHOSTNAME; then
        sudo hostnamectl set-hostname $HOSTNAME
fi

