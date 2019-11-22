#!/bin/bash

# ./fail2ban.sh '192.168.0.0/24' 'name@domain.com'

XLAN="${1}";
XSENDER="${2}";
XDIR='/etc/fail2ban'
XSERVICE_DIR='/etc/systemd/system/fail2ban.service.d';
XLOG_DIR='/var/log/fail2ban';
XUFW_LOCK='/run/ufw.lock';

pacman -Syu --needed --noconfirm fail2ban;

mkdir -p "${XSERVICE_DIR}";
mkdir -p "${XLOG_DIR}";
touch "${XUFW_LOCK}";

cat > "${XSERVICE_DIR}/override.conf" << EOF
[Service]
PrivateDevices=yes
PrivateTmp=yes
ProtectHome=read-only
ProtectSystem=strict
NoNewPrivileges=yes
ReadWritePaths=-/etc/ufw
ReadWritePaths=-${XUFW_LOCK}
ReadWritePaths=-/var/run/fail2ban
ReadWritePaths=-/var/lib/fail2ban
ReadWritePaths=-${XLOG_DIR}
ReadWritePaths=-/var/spool/postfix/maildrop
CapabilityBoundingSet=CAP_AUDIT_READ CAP_DAC_READ_SEARCH CAP_NET_ADMIN CAP_NET_RAW
EOF

cat > "${XDIR}/jail.local" << EOF
[INCLUDES]
before = paths-arch.conf

[DEFAULT]
ignorself = true
ignoreip  = 127.0.0.1/8 ::1 ${XLAN}
bantime   = 12h
findtime  = 10m
maxretry  = 5
# root is just an alias see /etc/aliases
destemail = root

[sshd]
enabled   = true
filter    = sshd
banaction = ufw
action    = %(action_mwl)s
backend   = systemd
maxretry  = 5
findtime  = 1d
bantime   = 2w
EOF

cat > "${XDIR}/fail2ban.local" << EOF
[Definition]
logtarget = ${XLOG_DIR}/fail2ban.log
EOF

cat > "/etc/aliases" << EOF
# Aliases file

# Send root to
root: ${XSENDER}

# Send everything else to
default: ${XSENDER}
EOF

systemctl daemon-reload;
systemctl enable fail2ban.service;
systemctl restart fail2ban.service;

(return 0 2>/dev/null) && return 0 || exit 0;
