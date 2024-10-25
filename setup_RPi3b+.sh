#!/bin/bash

# Set variables
USERNAME="chewy"
HOSTNAME="czw-server-pi.local"

# Function to display messages
function echo_message {
    echo -e "\n\033[1;32m$1\033[0m\n"
}

# Connect via SSH
echo_message "Connecting to $HOSTNAME as $USERNAME..."
ssh $USERNAME@$HOSTNAME << 'ENDSSH'

# Update the system
echo_message "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo_message "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo_message "Installing Docker Compose..."
sudo apt install -y python3-pip
sudo pip3 install docker-compose

# Install Portainer
echo_message "Setting up Portainer..."
docker volume create portainer_data
docker run -d \
  --name portainer \
  --restart always \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Install Openbox
echo_message "Installing Openbox..."
sudo apt install -y openbox

# Install Firefox
echo_message "Installing Firefox..."
sudo apt install -y firefox

# Install Thunar (lightweight file browser)
echo_message "Installing Thunar..."
sudo apt install -y thunar

echo_message "Setup completed successfully!"

ENDSSH
