#!/bin/bash

# getting latest releases
DOCKER_COMPOSE_RELEASE=$(curl https://github.com/docker/compose/releases/latest 2>/dev/null | cut -d '"' -f2 | awk -F'/' '{print $NF}')
VMS_LATEST_RELEASE=$(curl https://github.com/DefectDojo/django-DefectDojo/releases/latest 2>/dev/null | cut -d '"' -f2 | awk -F'/' '{print $NF}')

# Remove old docker engine versions
function remove_de_old() {
    version=$(docker -v 2>/dev/null)
    if [ ! -z "$version" ]; then
      echo "[!] Existing Docker engine version detected ($version)!"
      read -p "[!] Do you want to uninstall it [Y/y]? " -r
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "[!] Stopping existing services"
        sudo systemctl stop docker.socket
        read -p "[!] Do you want clean all the previous Docker engine content (This will remove Images, containers, volumes, or customized configuration files on your host) [Y/y]? " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          # ref : https://docs.docker.com/engine/install/ubuntu/#uninstall-docker-engine
          sudo apt purge docker-ce docker-ce-cli containerd.io
          sudo apt remove docker docker-engine docker.io containerd runc
          sudo apt autoremove
          echo "[!] Removing content : /var/lib/docker, /var/lib/containerd"
          sudo rm -rf /var/lib/docker
          sudo rm -rf /var/lib/containerd
        else
          sudo apt-get purge docker-ce docker-ce-cli containerd.io
          sudo apt remove docker docker-engine docker.io containerd runc
          sudo apt autoremove
        fi
      else
        echo "[!] Skipping removal process.."
      fi
    else
      echo "[!] No existing Docker versions were found! Skipping removal process.."
    fi
}


# Install docker engine
function install_de_ubuntu() {
  if [ -z "$(docker -v 2>/dev/null)" ]; then
    echo -e "[!] Installing necessary packages"
    sudo apt update
    sudo apt install ca-certificates curl gnupg lsb-release -y
    echo -e "[!] Adding Docker's official GPG key"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo -e "[!] Setting up stable repository"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo -e "[!] Installing Docker engine"
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io
  else
    echo "[!] Docker engine already existing. Skipping installation process!"
  fi
}


function install_docker_compose(){
  current_dc_version=$(docker-compose -v 2>/dev/null | awk '{print $NF}')
  if [[ ! -z "$current_dc_version" && "$current_dc_version" != "$DOCKER_COMPOSE_RELEASE" ]]; then
    read -p "[!] New version detected! (current : $current_dc_version, latest: $DOCKER_COMPOSE_RELEASE) Do you want to update it [Y/y]? " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "[!] Installing latest Docker compose ($DOCKER_COMPOSE_RELEASE)"
      sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_RELEASE/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
    fi
  else
    echo "[!] Latest docker-compose version already exists! Skipping installation.."
  fi
}


function install_vms_latest() {
  echo "[!] Downloading latest release ($VMS_LATEST_RELEASE)"
  if [[ -f "/tmp/$VMS_LATEST_RELEASE.tar.gz" ]]; then
    echo "[!] File exists. Skipping downloading.."
  else
    wget "https://github.com/DefectDojo/django-DefectDojo/archive/refs/tags/$VMS_LATEST_RELEASE.tar.gz" -P /tmp
  fi

  echo "[!] Extracting VMS to /opt"
  if [ -d "/opt/django-DefectDojo-$VMS_LATEST_RELEASE" ]; then
    read -p "[!] Folder exists. Do you want to replace the content [Y/y]? " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo tar zxvf /tmp/2.6.2.tar.gz -C /opt
    else
      echo "[!] Skipping extracting the content"
    fi
  fi
  # sudo docker-compose build : NO NEED
  # sudo docker/setEnv.sh release
  # sudo docker-compose up
  # ask if the user wants to change the password
  # sudo docker exec -it $(sudo docker ps --format '{{.Names}}' --filter 'name=uwsgi') ./manage.py changepassword admin
}
remove_de_old
install_de_ubuntu
install_docker_compose
install_vms_latest
