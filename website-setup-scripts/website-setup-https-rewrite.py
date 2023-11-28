# This file defines the Apache rewrite rules for configuring HTTP to HTTPS redirect on the target instance.
# It is needed as part of the Lightsail Website Setup for setting up a secure WordPress website.
# This file can be safely removed after Lightsail Website Setup is completed by running: sudo rm /opt/bitnami/lightsail/website-setup-https-rewrite.py

# To disable HTTP to HTTPS rewrite, run the following commands in a SSH session:
# sudo cp /opt/bitnami/lightsail/wp-config.php.backup /opt/bitnami/wordpress/wp-config.php
# sudo cp /opt/bitnami/lightsail/wordpress-vhost.conf.backup /opt/bitnami/apache/conf/vhosts/wordpress-vhost.conf
# sudo /opt/bitnami/ctlscript.sh restart

# To enable HTTP to HTTPS rewrite, run the following commands in a SSH session:
# sudo python3 /opt/bitnami/lightsail/website-setup-https-rewrite.py WebsiteSetupLECert

import logging
import os
from sys import argv
import subprocess
from datetime import datetime
import sys

WORKING_FOLDER = "/opt/bitnami/lightsail"
LINES_AFTER = 5
VHOSTS_FOLDER = "/opt/bitnami/apache/conf/vhosts"
VHOST_FILE = "wordpress-vhost.conf"
WP_CONFIG_PHP_PATH = "/opt/bitnami/wordpress/wp-config.php"
LEADING_SPACE = "  "
NEWLINE = '\n'

rewrite_lines = [
    "RewriteEngine On",
    "RewriteCond %{HTTPS} !=on",
    "RewriteCond %{HTTP_HOST} !^(localhost|127.0.0.1)",
    "RewriteRule ^/(.*) https://%{SERVER_NAME}/$1 [R=permanent,L]"
]

def log_init():
    if os.path.exists(WORKING_FOLDER) == False:
        os.mkdir(WORKING_FOLDER)
    datetime_str = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    log_file_path = f"{WORKING_FOLDER}/https_rewrite_{datetime_str}.log"
    logging.basicConfig(filename=log_file_path, filemode='a', format='%(asctime)s - %(levelname)s: %(message)s', level=logging.INFO)

def log_info(str):
    print(str)
    logging.info(str)

def log_error(str):
    print(str, file=sys.stderr)
    logging.error(str)

def run_cmd(cmd):
    log_info(f"Execute command: {cmd}")
    result = subprocess.run(cmd, capture_output=True, shell=True)
    if result.returncode != 0:
        err_msg = result.stderr.decode()
        log_error(err_msg)
    return result.returncode, result.stdout.decode(), result.stderr.decode()

def update_wp_config_php():
    if os.path.exists(WP_CONFIG_PHP_PATH) == False:
        logging.error(f"{WP_CONFIG_PHP_PATH} is not found")
        return
    returncode, stdout, stderr = run_cmd(f'cp {WP_CONFIG_PHP_PATH} {WP_CONFIG_PHP_PATH}.backup')
    if returncode != 0:
        return returncode

    with open(WP_CONFIG_PHP_PATH, "r") as fh:
        lines = fh.readlines()
        fh.close()

    # replace the follow two lines with 'https://'
    # define( 'WP_HOME', 'http://' . $_SERVER['HTTP_HOST'] . '/' );
    # define( 'WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST'] . '/' );
    logging.info(f"Update {WP_CONFIG_PHP_PATH}")
    try:
        with open(WP_CONFIG_PHP_PATH, "w") as fh:
            for line in lines:
                if line.strip().startswith("define(") and line.find("'http://'") > 0:
                    if line.find("'WP_HOME'") > 0 or line.find("'WP_SITEURL'") > 0:
                        logging.info(f"replace http:// with https:// in line {line}")
                        line = line.replace("'http://'", "'https://'")
                fh.writelines(line)
            fh.close()
    except Exception as ex:
        log_info(f"Error in writing {WP_CONFIG_PHP_PATH}, roll back to backup file.")
        log_error(ex)
        run_cmd(f'cp {WP_CONFIG_PHP_PATH}.backup {WP_CONFIG_PHP_PATH}')
        return 1
    logging.info(f"Update {WP_CONFIG_PHP_PATH} completed.")
    return 0

def roll_back_wp_config_php():
    run_cmd(f'mv {WP_CONFIG_PHP_PATH}.backup {WP_CONFIG_PHP_PATH}')
    run_cmd(f"sudo chown bitnami {WP_CONFIG_PHP_PATH}")
    run_cmd(f"sudo chgrp daemon {WP_CONFIG_PHP_PATH}")

def modify_vhost_conf(file_path, domain_list):
    default_domain = domain_list[0]
    domain_list.remove(domain_list[0])
    aliases = "*"
    if len(domain_list) > 0:
        aliases = " ".join(domain_list)

    lines_before_directory_block = []
    lines_after_directory_tag = []
    before_directory_block = True

    with open(file_path, "r") as fh:
        while True:
            line = fh.readline()
            if not line:
                break
            if line.find("<Directory ") >= 0:
                before_directory_block = False
            if before_directory_block:
                lines_before_directory_block.append(line.strip())
            else:
                lines_after_directory_tag.append(line)
        fh.close()

    for line in rewrite_lines:
        if line not in lines_before_directory_block:
            log_info(f"inserting: {line}")
            lines_before_directory_block.append(f"{LEADING_SPACE}{line}")

    with open(file_path, "w") as fh:
        for line in lines_before_directory_block:
            if line.startswith("ServerName "):
                log_info(f"Writing ServerName: {default_domain}")
                line = f"{LEADING_SPACE}ServerName {default_domain}"
            if line.startswith("ServerAlias "):
                log_info(f"Writing ServerAlias: {aliases}")
                line = f"{LEADING_SPACE}ServerAlias {aliases}"
            fh.writelines(f"{line}{NEWLINE}")
        fh.writelines(lines_after_directory_tag)
        fh.close()

def main():
    if len(argv) == 1:
        print("usage: sudo <python/python3> website-setup-https-rewrite.py <target_cert_name>")
        print("Expecting certificate name as the input parameter.  Exit.")
        return 1

    cert_name = argv[1]
    log_init()
    returncode, stdout, stderr = run_cmd(f'certbot certificates | grep "Certificate Name: {cert_name}" -A{LINES_AFTER} | grep "Domains: "')
    if returncode != 0:
        return 1

    log_info(f"Found {stdout}")
    domain_list = stdout.split()

    if len(domain_list) < 2: #this situation shouldn't happen, but just in case
        log_error("can't find expected domain info: ")
        log_error(domain_list)
        return 1

    domain_list.remove(domain_list[0]) # remove: 'Domains:'

    vhost_full_path = f"{VHOSTS_FOLDER}/{VHOST_FILE}"
    returncode, stdout, stderr = run_cmd(f'cp {vhost_full_path} {vhost_full_path}.backup')
    if returncode != 0:
        return 1

    log_info(f"Modifying {vhost_full_path}")
    try:
        modify_vhost_conf(vhost_full_path, domain_list)
    except Exception as ex:
        log_error(ex)
        log_info(f"Rolling back the vhost file: {vhost_full_path}")
        run_cmd(f'cp {vhost_full_path}.backup {vhost_full_path}')
        return 1

    log_info("vhost file modification completed.")
    update_wp_config_php()
    log_info("Restarting bitnami service...")


    returncode, stdout, stderr = run_cmd("/opt/bitnami/ctlscript.sh restart")
    if returncode != 0:
        log_info(f"Rolling back the vhost file: {vhost_full_path}")
        run_cmd(f'cp {vhost_full_path}.backup {vhost_full_path}')
        run_cmd(f"sudo chown bitnami {vhost_full_path}")
        log_info(f"Rolling back the wp-config.php file: {WP_CONFIG_PHP_PATH}")
        roll_back_wp_config_php()
        run_cmd("/opt/bitnami/ctlscript.sh restart")
        log_info("Rollback completed.")
        return 1

    log_info("Rewrite operation completed.")

    return 0

if __name__ == "__main__":
    main()
