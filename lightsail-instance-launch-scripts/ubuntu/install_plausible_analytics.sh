#!/bin/bash

# Use with the Ubuntu OS Lightsail Blueprint
# This will install Plausible Analytics on your instance
# You will need to open TCP 8000 to connect to the instance
# Update the ADMIN values in the plausible-conf.env section of the script below

sudo apt update -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli docker-compose containerd.io -y

sudo mkdir /var/www
cd /var/www
sudo git clone https://github.com/plausible/hosting

# Elevate permissions to be able to run the cat command
sudo su
PUBLICIP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
SECRET_KB=$(openssl rand -base64 64)
# Update plausible-configuration file
cat << EOF >> /var/www/hosting/plausible-conf.env

ADMIN_USER_EMAIL=plausible@example.com"
ADMIN_USER_NAME=admin"
ADMIN_USER_PWD=ExamplePWD123!"
BASE_URL=http://$PUBLICIP
SECRET_KEY_BASE=$SECRET_KB

EOF


# Change directories to the Plausible files
cd /var/www/hosting

# Kick off the Docker container
sudo docker-compose up --detach
# Wait about 10-20 seconds after the above command completes then run the final command. If it gives an error. Wait another 10 seconds and try it again.
# 
sudo docker-compose exec plausible_db psql -U postgres -d plausible_db -c "UPDATE users SET email_verified = true;"
