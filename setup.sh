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
        ssh-keygen \
        build-essential &&

    # install oh-my-zsh
    echo "installing oh-my-zsh" &&
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &&

    # create a new user
    echo "creating a new user" &&
    useradd -m -s /bin/zsh $username &&
    echo "$username:$password" | chpasswd &&

    # add user to sudo and docker group
    echo "adding $username to sudo group" &&
    usermod -aG sudo $username &&
    echo "adding $username to docker group" &&
    usermod -aG docker $username &&

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
            rm get-docker.sh &&
            sudo usermod -aG docker $USER
    fi &&

    # install docker-compose
    echo "installing docker-compose" &&
    apt install -y docker-compose &&

    # set up ssh
    echo "setting up ssh" &&
    echo "generating ssh key" &&
    # gemerate ssh key for the new user and root
    sudo -u $username ssh-keygen -t rsa -b 4096 -C "$username@$(hostname)" -f /home/$username/.ssh/id_rsa -N "" &&
    ssh-keygen -t rsa -b 4096 -C "root@$(hostname)" -f /root/.ssh/id_rsa -N "" &&
    EOF
