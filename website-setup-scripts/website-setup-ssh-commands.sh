# This file contains all the SSH commands run as part of Lightsail Website Setup.
# These commands are for informational purposes only.

# Update apt-get and install python & pip dependencies.
sudo apt-get update \
&& sudo apt-get install -y python3 python3-venv libaugeas0 \
&& sudo apt-get remove certbot \
&& sudo python3 -m venv /opt/certbot/ \
&& sudo /opt/certbot/bin/pip install --upgrade pip \
&& echo Lightsail Website Setup: Updated software needed for Certbot Lets Encrypt client installation.


# Create Lightsail working directory.
# Install certbot client dependency for generating Let's Encrypt SSL certificate.
# RequirementsTxtGitHubURL defines the checksum values of the specific certbot version & dependency versions.
sudo mkdir -p /opt/bitnami/lightsail \
&& sudo curl -o /opt/bitnami/lightsail/requirements.txt #RequirementsTxtGitHubURL# \
&& sudo /opt/certbot/bin/pip install -r /opt/bitnami/lightsail/requirements.txt \
&& sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot \
&& echo Lightsail Website Setup: Installed Certbot Lets Encrypt client.


# Download certbot license to lightsail working directory.
sudo curl -o /opt/bitnami/lightsail/certbot-LICENSE.txt https://raw.githubusercontent.com/certbot/certbot/v1.0.0/LICENSE.txt \
&& echo Lightsail Website Setup: Downloaded certbot license to instance.


# Stop Bitnami background service.
sudo /opt/bitnami/ctlscript.sh stop \
&& echo Lightsail Website Setup: Stopped bitnami service.


# Start Bitnami background service.
sudo /opt/bitnami/ctlscript.sh start \
&& echo Lightsail Website Setup: Started bitnami service.


# Backup existing wordpress files on instance.
export BACKUP_PATH=/opt/bitnami/lightsail \
&& sudo cp /opt/bitnami/wordpress/wp-config.php $BACKUP_PATH/wp-config.php.backup \
&& sudo cp /opt/bitnami/apache/conf/vhosts/wordpress-vhost.conf $BACKUP_PATH/wordpress-vhost.conf.backup \
&& echo Lightsail Website Setup: Backed up WordPress files.


# Call certbot to generate the Let's Encrypt SSL certificate for the target domain & subdomain(s).
# #DomainNameList#, #EmailAddress# are pass in user parameters.
# #LECertName# is the Let's Encrypt certificate name defined as "WebsiteSetupLECert"
sudo certbot certonly --agree-tos --standalone -d #DomainNameList# \
--cert-name #LECertName# --preferred-challenges http --webroot-path /opt/bitnami/wordpress \
--email #EmailAddress# --no-eff-email --force-renewal \
&& echo Lightsail Website Setup: Generated HTTPS certificate via certbot client.


# Return back the Let's Encrypt failure message when the certificate generation fails.
# It is only run on the target instance when the previous certbot command fails.
if sudo [ -f /var/log/letsencrypt/letsencrypt.log ]; \
then sudo tail -n 30 /var/log/letsencrypt/letsencrypt.log \
&& echo Lightsail Website Setup: HTTPS certificate generation failed - see the standardIO output for details.; \
else echo Lightsail Website Setup: HTTPS certificate generation failed - please try again later.; \
fi


# Return back the target instance WordPress version.
sudo wp core version --allow-root \
&& echo Lightsail Website Setup: Fetched WordPress Version.


# Back up the existing certificate files on the target instance to the Lightsail working directory.
export BACKUP_PATH=/opt/bitnami/lightsail \
&& if [ -f /opt/bitnami/apache/conf/bitnami/certs/server.crt ] && [ -f /opt/bitnami/apache/conf/bitnami/certs/server.key ]; \
then sudo mv /opt/bitnami/apache/conf/bitnami/certs/server.crt $BACKUP_PATH/server.crt.backup; \
sudo mv /opt/bitnami/apache/conf/bitnami/certs/server.key $BACKUP_PATH/server.key.backup; \
echo Lightsail Website Setup: Backed up cert files.; \
else echo Lightsail Website Setup: Backup cert files not found - skipped backup step.; \
exit 0; \
fi


# Restore original certificate and wordpress backup files & reboot the target instance.
# Only run when Lightsail Website Setup encounters an error and performs a rollback.
echo Lightsail Website Setup: Restored original backup files and rebooted the instance. \
&& export BACKUP_PATH=/opt/bitnami/lightsail \
&& sudo mv $BACKUP_PATH/server.crt.backup /opt/bitnami/apache/conf/bitnami/certs/server.crt \
&& sudo mv $BACKUP_PATH/server.key.backup /opt/bitnami/apache/conf/bitnami/certs/server.key \
&& sudo cp $BACKUP_PATH/wp-config.php.backup /opt/bitnami/wordpress/wp-config.php \
&& sudo cp $BACKUP_PATH/wordpress-vhost.conf.backup /opt/bitnami/apache/conf/vhosts/wordpress-vhost.conf \
&& sudo reboot


# Finalize Let's Encrypt certificate configuration.
sudo ln -sf /etc/letsencrypt/live/#LECertName#/fullchain.pem /opt/bitnami/apache/conf/bitnami/certs/server.crt \
&& sudo ln -sf /etc/letsencrypt/live/#LECertName#/privkey.pem /opt/bitnami/apache/conf/bitnami/certs/server.key \
&& echo Lightsail Website Setup: Finalized Lets Encrypt certificate configuration.


# Download and execute HTTPS rewrite script.
sudo curl -o /opt/bitnami/lightsail/website-setup-https-rewrite.py #HttpsRewriteScriptGithubURL# \
&& sudo python3 /opt/bitnami/lightsail/website-setup-https-rewrite.py #LECertName# \
&& echo Lightsail Website Setup: HTTP to HTTPS redirect has been successfully configured.


# Download and execute Let's Encrypt renewal script.
sudo curl -o /opt/bitnami/lightsail/website-setup-le-cert-renewal.py #LERenewalScriptGithubURL# \
&& if [ $(sudo grep -c "website-setup-le-cert-renewal.py"  /etc/crontab) -eq 0 ]; then echo "0 0,12 * * * root /usr/bin/python3 /opt/bitnami/lightsail/website-setup-le-cert-renewal.py" | sudo tee -a /etc/crontab > /dev/null; \
echo Lightsail Website Setup: Set up LE auto renewal service.; \
else echo Lightsail Website Setup: LE auto renewal service already setup - skipping.;
