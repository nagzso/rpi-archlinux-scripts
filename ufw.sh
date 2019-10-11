#!/bin/bash

## XLAN value e.g.: 192.168.0.0/24

XLAN="${1}";

pacman -S --needed --noconfirm ufw;

modprobe ip_tables;

ufw default deny incoming;
ufw default allow outgoing;
ufw allow from "${XLAN}";
ufw limit SSH;
ufw logging off;

yes | ufw enable;

systemctl enable ufw.service;
systemctl restart ufw.service;

exit 0;
