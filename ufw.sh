#!/bin/bash

pacman -S --needed --noconfirm ufw;

ufw default deny incoming;
ufw default allow outgoing;
ufw allow from 192.168.0.0/24;
ufw limit SSH;

yes | ufw enable;

systemctl enable ufw.service;
systemctl restart ufw.service;

exit 0;
