#!/bin/bash

# ./ufw.sh '192.168.0.0/24'

XLAN="${1}";

function install() {
  pacman -Syu --needed --noconfirm ufw;

  modprobe ip_tables;
}

function configure() {
  ufw default deny incoming;
  ufw default allow outgoing;
  ufw allow from "${XLAN}";
  ufw limit SSH;
  ufw logging off;
}

function enable() {
  systemctl stop iptables ip6tables;
  systemctl disable iptables ip6tables;

  yes | ufw enable;

  systemctl enable ufw.service;
  systemctl restart ufw.service;
}

install;
configure;
enable;

(return 0 2>/dev/null) && return 0 || exit 0;
