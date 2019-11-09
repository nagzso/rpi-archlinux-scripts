#!/bin/bash

# Configured to work with gmail account
# Google application password can be requested at: https://myaccount.google.com/apppasswords
#
# ./msmtp.sh 'your@email.com' 'the_app_password' 'Sender name'

XMAIL_ACCOUNT="${1}"
XAPP_PASSWORD="${2}"
XFROM_NAME="${3}"

function install() {
  pacman -Syu --noconfirm;
  pacman -S --needed --noconfirm msmtp;
  pacman -S --needed --noconfirm msmtp-mta;
}

function configure() {
  local XMSMTP_CONF_FILE='/etc/msmtprc';

  cat << EOF > "${XMSMTP_CONF_FILE}";
# Default values for accounts
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /var/log/msmtp.log
aliases /etc/aliases

# Gmail account
account gmail
host smtp.gmail.com
port 587
tls_starttls on
from ${XFROM_NAME}
user ${XMAIL_ACCOUNT}
password ${XAPP_PASSWORD}

account default : gmail
EOF
}

install;
configure;

exit 0;
