#!/bin/bash

# Configured to work with gmail account
# Google application password can be requested at: https://myaccount.google.com/apppasswords
#
# ./ssmtp.sh 'your@email.com' 'the_app_password' 'localhost'

XMAIL_ACCOUNT="${1}"
XAPP_PASSWORD="${2}"
XHOSTNAME="${3}"
XSSMTP_CONF_FILE='/etc/ssmtp/ssmtp.conf';

function install() {
  pacman -Syu --needed --noconfirm ssmtp;
}

function configure() {
  [ ! -e "${XSSMTP_CONF_FILE}.bak" ] && cp "${XSSMTP_CONF_FILE}" "${XSSMTP_CONF_FILE}.bak";

  cat << EOF > "${XSSMTP_CONF_FILE}";
Root=${XMAIL_ACCOUNT}
Hostname=${XHOSTNAME}
Mailhub=smtp.gmail.com:587
FromLineOverride=yes

UseTLS=yes
UseSTARTTLS=yes
AuthUser=${XMAIL_ACCOUNT}
AuthPass=${XAPP_PASSWORD}
EOF
}

function secure() {
  groupadd ssmtp;

  chown :ssmtp "${XSSMTP_CONF_FILE}";
  chown :ssmtp /usr/bin/ssmtp;

  chmod 640 "${XSSMTP_CONF_FILE}";
  chmod g+s /usr/bin/ssmtp;

  mkdir /root/bin;

  cat << EOF > /root/bin/ssmtp-set-permissions
#!/bin/bash

chown :ssmtp /usr/bin/ssmtp
chmod g+s /usr/bin/ssmtp
EOF

  chmod u+x /root/bin/ssmtp-set-permissions;

  cat << EOF > /usr/share/libalpm/hooks/ssmtp-set-permissions.hook;
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = ssmtp

[Action]
Description = Set ssmtp permissions for security
When = PostTransaction
Exec = /root/bin/set-ssmtp-permissions
EOF
}

install;
configure;
secure;

exit 0;
