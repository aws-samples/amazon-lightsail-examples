
#!/bin/bash

# Update the package lists
sudo apt-get update -y

# Install software to manage independent software vendor sources
sudo apt install software-properties-common -y

# Add the repository for all PHP versions
sudo add-apt-repository ppa:ondrej/php -y

# Install Web server, mySQL client, PHP (and packages), unzip, and curl
sudo apt-get install apache2 mysql-client-core-8.0  php8.0 libapache2-mod-php8.0 php8.0-common php8.0-imap php8.0-mbstring php8.0-xmlrpc php8.0-soap php8.0-gd php8.0-xml php8.0-intl php8.0-mysql php8.0-cli php8.0-bcmath php8.0-ldap php8.0-zip php8.0-curl unzip curl -y

# restart apache just to make sure we're good
sudo systemctl restart apache2

# Download the latest version of Akaunting from their site
curl -O -J -L https://akaunting.com/download.php?version=latest

# Make a directory in our web server folder
sudo mkdir -p /var/www/html/akaunting

# Unpack the files from the downloaded zip
sudo unzip Akaunting_*.zip -d /var/www/html/akaunting/

# Change directory permissions for the software
sudo chown -R www-data:www-data /var/www/html/akaunting/
sudo chmod -R 755 /var/www/html/akaunting/

# Save the Instance Public IP as a variable to use in the apache configuration
PUBLICIP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

# Elevate permissions to be able to run the cat command
sudo su

# Inject apache configuration (you may choose to update the ServerAdmin value)
cat << EOF >> /etc/apache2/sites-available/akaunting.conf
<VirtualHost *:80>
ServerAdmin admin@example.com
DocumentRoot /var/www/html/akaunting
ServerName http://$PUBLICIP
DirectoryIndex index.html index.php

<Directory /var/www/html/akaunting/>
Options +FollowSymlinks
AllowOverride All
Require all granted
</Directory>

ErrorLog ${APACHE_LOG_DIR}/akaunting_error.log
CustomLog ${APACHE_LOG_DIR}/akaunting_access.log combined
</VirtualHost>
EOF

# Enable Apache2 virtualhost configuration for Akaunting
sudo a2ensite akaunting

# Enable specified module in apache configuration
sudo a2enmod rewrite

# Restart the apache service to make changes live.
sudo systemctl restart apache2


