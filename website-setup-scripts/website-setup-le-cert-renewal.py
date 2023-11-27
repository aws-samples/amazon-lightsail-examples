# This file defines the logic needed to handle renewing the Let's Encrypt (LE) SSL certificate installed by Lightsail Website Setup.
# This file is executed by the following crontab entry: 0 0,12 * * * root /usr/bin/python3 /home/bitnami/lightsail/le_cert_renewal.py
# It checks the existing valid LE certificate expiration date. If eligible for renewal, it will call certbot to renew the certificate.
# This file should not be removed, even after Lightsail Website Setup completes, to ensure the renewal process succeeds.
# If the LE certificate is no longer needed and therefore does not need to be removed, this file can be removed.
# To remove this file, run: sudo rm /opt/bitnami/lightsail/le_cert_renewal.py

import logging
import time
from datetime import datetime, timezone
from sys import argv
import os
import random
import subprocess

VERBOSE_LOG = True
DAYS_WITHIN_RENEWAL = 30
IF_FORCE_RENEW = True

WORKING_FOLDER = "/opt/bitnami/lightsail"
CERT_LOG_FOLDER = "cert_info_log"
VERBOSE_LOG_FOLDER = "verbose_log"

DEFAULT_CERT_PATH = "/etc/letsencrypt"
FULLCHAIN_PEM = "fullchain.pem"
LETSENCRYPT_LOG_FOLDER = "/var/log/letsencrypt/"

DEFAULT_DAYS_OF_EXPIRY = 90
MAX_RANDOM_WAIT_SECONDS = 3600

def verbose_log_init():
    if VERBOSE_LOG == False:
        return
    if os.path.exists(f"{WORKING_FOLDER}/{VERBOSE_LOG_FOLDER}") == False:
        os.mkdir(f"{WORKING_FOLDER}/{VERBOSE_LOG_FOLDER}")
    datetime_str = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    log_file_path = f"{WORKING_FOLDER}/{VERBOSE_LOG_FOLDER}/cert_renew_{datetime_str}.log"
    logging.basicConfig(filename=log_file_path, filemode='a', format='%(asctime)s - %(levelname)s: %(message)s', level=logging.INFO)

def log_info(str):
    print(str)
    if VERBOSE_LOG:
        logging.info(str)

def log_error(str):
    print(str)
    if VERBOSE_LOG:
        logging.error(str)

def log_cert_info(cert_name):
    now = datetime.now()
    datetime_str = now.strftime('%Y%m%d-%H%M%S')
    log_path = f"{WORKING_FOLDER}/{CERT_LOG_FOLDER}/{cert_name}_{datetime_str}.log"
    if os.path.exists(f"{WORKING_FOLDER}/{CERT_LOG_FOLDER}") == False:
        os.mkdir(f"{WORKING_FOLDER}/{CERT_LOG_FOLDER}")
    run_cmd(f"certbot certificates > {log_path}")

def run_cmd(cmd):
    log_info(f"Execute command: {cmd}")
    result = subprocess.run(cmd, capture_output=True, shell=True)
    return result.returncode, result.stdout.decode(), result.stderr.decode()

def get_cert_modified_time(cert_name):
    live_fullchain_link_path = f"{DEFAULT_CERT_PATH}/live/{cert_name}/{FULLCHAIN_PEM}"
    if os.path.exists(live_fullchain_link_path) == False:
        raise Exception(f"fullchain.pem not found: {live_fullchain_link_path}")
    return datetime.fromtimestamp(os.stat(live_fullchain_link_path).st_mtime, tz=timezone.utc)

def main():
    verbose_log_init()

    if len(argv) == 1:
        log_info("usage: sudo <python/python3> cert_renew.py <target_cert_name>")
        log_info("Expecting certificate name as the input parameter.  Exit.")
        return

    cert_name = argv[1]
    log_info(f"Target certificate: {cert_name}")

    modified_time = None
    try:
        modified_time = get_cert_modified_time(cert_name)
    except Exception as ex:
        log_error(ex)
        return

    now = datetime.now(tz=timezone.utc)
    span = now - modified_time
    days_to_expiry = DEFAULT_DAYS_OF_EXPIRY - span.days
    if days_to_expiry > DAYS_WITHIN_RENEWAL:
        log_info(f"{days_to_expiry} days to certificate expiry. No need to renew.")
        return

    log_info(f"{days_to_expiry} days to certificate expiry. Attempt renewal...")

    seconds_to_wait = random.random() * MAX_RANDOM_WAIT_SECONDS
    log_info(f"Randomly waiting for {seconds_to_wait} seconds...")
    time.sleep(seconds_to_wait)

    log_cert_info(cert_name)

    log_info("Stopping bitnami service...")
    returncode, stdout, stderr = run_cmd("/opt/bitnami/ctlscript.sh stop")
    if returncode != 0:
        log_error(stderr)
        return 1

    log_info(f"Renewing cert: {cert_name}")
    renew_cmd = "certbot renew"
    if IF_FORCE_RENEW:
        renew_cmd += " --force-renewal"
    returncode, stdout, stderr = run_cmd(renew_cmd)
    if returncode != 0:
        log_error(stderr)
    else:
        log_info(f"Certificate [{cert_name}] has been renewed.")
        log_info(f"Check {LETSENCRYPT_LOG_FOLDER} for logs.")
        log_info(f"Check {WORKING_FOLDER}/{CERT_LOG_FOLDER} for cert info history.")

    log_info("Starting bitnami service...")
    returncode, stdout, stderr = run_cmd("/opt/bitnami/ctlscript.sh start")
    if returncode != 0:
        log_error(stderr)
    else:
        log_info("bitnami service restarted.  Operation complated.")

    log_cert_info(cert_name)

    return

if __name__ == "__main__":
    main()