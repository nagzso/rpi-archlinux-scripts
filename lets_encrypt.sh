#!/bin/bash

function install() {
  pacman -Syu --needed --noconfirm certbot;
  pacman -S --needed --noconfirm certbot-nginx;
}

function configureRenewal() {
  echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew" | sudo tee -a /etc/crontab > /dev/null;
}

install;
configureRenewal;

systemctl restart nginx.service;

exit 0;
