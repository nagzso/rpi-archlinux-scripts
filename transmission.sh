#!/bin/bash

## ./transmission.sh "password" "group" "192.168.0.*"

XPASSWORD="${1}";
XGROUP="${2}";
XWHITELISTED_HOSTS=( ${3} )

function install() {
  pacman -Syu --needed --noconfirm transmission-cli;
}

function configure() {
  local XSERVICE_DIR='/etc/systemd/system/transmission.service.d';
  local XLOG_FILE='/var/log/transmission.log';

  cat > '/var/lib/transmission/.config/transmission-daemon/settings.json' << EOF
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://www.example.com/blocklist",
    "cache-size-mb": 16,
    "dht-enabled": false,
    "download-dir": "/mnt/storage/Downloads/Completed",
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 2,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "/mnt/storage/Downloads/Incomplete",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "message-level": 2,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 1000,
    "peer-limit-per-torrent": 150,
    "peer-port": 58377,
    "peer-port-random-high": 58387,
    "peer-port-random-low": 58377,
    "peer-port-random-on-start": true,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": true,
    "preallocation": 2,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist": "",
    "rpc-host-whitelist-enabled": true,
    "rpc-password": "${XPASSWORD}",
    "rpc-port": 4752,
    "rpc-url": "/transmission/",
    "rpc-username": "RPI4-Remote",
    "rpc-whitelist": "127.0.0.1,${XWHITELISTED_HOSTS}",
    "rpc-whitelist-enabled": true,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": true,
    "seed-queue-size": 10,
    "speed-limit-down": 40960,
    "speed-limit-down-enabled": true,
    "speed-limit-up": 10,
    "speed-limit-up-enabled": true,
    "start-added-torrents": true,
    "trash-original-torrent-files": true,
    "umask": 18,
    "upload-slots-per-torrent": 14,
    "utp-enabled": false,
    "watch-dir": "/mnt/storage/Downloads/Torrents",
    "watch-dir-enabled": true
}
EOF

  mkdir "${XSERVICE_DIR}";

  touch "${XLOG_FILE}";
  chown transmission:root "${XLOG_FILE}";

  cat > "${XSERVICE_DIR}/override.conf" << EOF
[Unit]
Description=Transmission BitTorrent Daemon
After=network.target

[Service]
User=transmission
Type=notify
ExecStart=
ExecStart=/usr/bin/transmission-daemon -f -e ${XLOG_FILE}
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
}

function grantPermissions() {
  usermod -a -G "${XGROUP}" transmission;
}

function initialize() {
  systemctl daemon-reload;
  systemctl enable transmission;
  systemctl restart transmission;
}

install;
configure;
grantPermissions;
initialize;

(return 0 2>/dev/null) && return 0 || exit 0;
