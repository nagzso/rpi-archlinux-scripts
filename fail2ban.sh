#!/bin/bash

XSERVICE_DIR='/etc/systemd/system/fail2ban.service.d';

pacman -S --needed --noconfirm fail2ban;

mkdir -p "${XSERVICE_DIR}";

cat > "${XSERVICE_DIR}/fail2ban.conf" << EOF
[Service]
CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_ADMIN CAP_NET_RAW
EOF

cat > "/etc/fail2ban/jail.local" << EOF
[INCLUDES]
before = paths-arch.conf

[DEFAULT]
ignorself = true
ignoreip = 127.0.0.1/8 ::1
bantime  = 12h
findtime  = 10m
maxretry = 5

[sshd]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
           sendmail-whois[name=SSH, dest=your@mail.org, sender=fail2ban@mail.com]
backend  = systemd
maxretry = 5
findtime = 1d
bantime  = 2w
EOF

systemctl daemon-reload;
systemctl enable fail2ban.service;
systemctl restart fail2ban.service;

exit 0;
