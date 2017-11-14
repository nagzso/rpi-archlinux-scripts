#!/bin/bash

XLAN="${1}";

pacman -S --needed --noconfirm ufw;

ufw default deny incoming;
ufw default allow outgoing;
ufw allow from "${XLAN}";
ufw limit SSH;

yes | ufw enable;

systemctl enable ufw.service;
systemctl restart ufw.service;

exit 0;
