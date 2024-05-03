#!/bin/bash

# script to get a linux system ready for development

echo "starting" &&
    echo "checking if script is running as root" &&
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
    fi &&
    echo "running as root" &&
    echo "updating system" &&
    apt update &&
    echo "upgrading system" &&
    apt upgrade -y &&

    # get user input
    echo "Enter the username for the new user: " &&
    read username &&
    echo "Enter the password for $username: " &&
    read password &&
    echo "Enter the password for root: " &&
    read root_password &&
    echo "Enter ssh port: " &&
    read ssh_port &&
    echo "Enter ssh passphrase: " &&
    read ssh_passphrase &&
    echo "Enter git name: " &&
    read git_name &&
    echo "Enter git email: " &&
    read git_email &&

    # install dependencies
    echo "installing dependencies" &&
    apt install -y \
        sudo \
        git \
        curl \
        wget \
        vim \
        nano \
        micro \
        htop \
        tree \
        nodejs \
        npm \
        python3 \
        python3-pip \
        zsh \
        ufw \
        build-essential &&

    # change default shell to zsh
    chsh -s $(which zsh) &&
    echo "dependencies installed" &&
    echo "setting up root" &&
    echo "root:$root_password" | chpasswd &&
    echo "root setup complete" &&

    # create a new user
    if id "$username" &>/dev/null; then
        echo "user exists"
    else
        echo "creating a new user" &&
            useradd -m -s /bin/zsh $username &&
            echo "$username:$password" | chpasswd &&
            echo "user created" &&
            # fix permissions
            echo "fixing permissions" &&
            chown -R $username:$username /home/$username &&
            echo "permissions fixed" &&

            # add user to sudo
            echo "adding $username to sudo group" &&
            usermod -aG sudo $username
    fi &&

    # check if docker is installed
    echo -e "\e[32mChecking if docker is installed" &&
    if [ -x "$(command -v docker)" ]; then
        echo "docker is installed"
    else
        echo "docker is not installed"
        echo "installing docker" &&
            echo "downloading docker install script" &&
            curl -fsSL https://get.docker.com -o get-docker.sh &&
            echo "running docker install script" &&
            sh get-docker.sh &&
            rm get-docker.sh
    fi &&

    # install docker-compose
    echo "installing docker-compose" &&
    apt install -y docker-compose &&

    # set up ssh
    echo "setting up ssh" &&
    echo "generating ssh key" &&

    # set up git
    echo "setting up git" &&
    git config --global user.name "$git_name" &&
    git config --global user.email "$git_email" &&
    echo "git setup complete" &&

    #  ssh key for the new user and root
    sudo -u $username ssh-keygen -t rsa -b 4096 -C "$username@$(hostname)" -f /home/$username/.ssh/id_rsa -N "$ssh_passphrase" &&
    ssh-keygen -t rsa -b 4096 -C "root@$(hostname)" -f /root/.ssh/id_rsa -N "$ssh_passphrase" &&

    # set up ssh config
    sed -i "s/#Port 22/Port $ssh_port/g" /etc/ssh/sshd_config &&
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config &&
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config &&
    sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config &&
    systemctl restart sshd &&
    echo "ssh setup complete" &&

    # display info
    echo "Server port: $ssh_port" &&
    echo "Server public key: /root/.ssh/id_rsa.pub" &&
    echo "
    User: $username
    User public key: $(/home/$username/.ssh/id_rsa.pub)
    Root public key: $(/root/.ssh/id_rsa.pub)
    "
