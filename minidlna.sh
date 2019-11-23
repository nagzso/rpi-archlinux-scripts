#!/bin/bash

# / characters MUST be escaped e.g. \/

XINTERFACE="${1}";
XMEDIA_DIRS=( ${2} );
XDLNA_NAME="${3}";
XGROUP="${4}";

function install() {
  pacman -Syu --needed --noconfirm minidlna;
}

function configure() {
  local XCONFIG_FILE='/etc/minidlna.conf';

  if [ -e "${XCONFIG_FILE}.bak" ]; then
    cp -v "${XCONFIG_FILE}.bak" "${XCONFIG_FILE}";
  else
    cp -v "${XCONFIG_FILE}" "${XCONFIG_FILE}.bak";
  fi

  sed -i -r "s/^.?network_interface=.*/network_interface=${XINTERFACE}/" "${XCONFIG_FILE}";
  sed -i -r "s/^.?media_dir=.*/media_dir=${XMEDIA_DIRS[0]}/" "${XCONFIG_FILE}";

  local XINDEX='1';

  while [[ "${XINDEX}" -lt "${#XMEDIA_DIRS[@]}" ]]; do
    sed -i -r "/^.?media_dir=${XMEDIA_DIRS[((${XINDEX} - 1))]}/a media_dir=${XMEDIA_DIRS[${XINDEX} + 1]}" "${XCONFIG_FILE}";

    ((XINDEX++));
  done

  sed -i -E "s/^.?merge_media_dirs=.*/merge_media_dirs=no/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?friendly_name=.*/friendly_name=${XDLNA_NAME}/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?db_dir=.*/db_dir=\/var\/cache\/minidlna/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?log_dir=.*/log_dir=\/var\/log/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?inotify=.*/inotify=yes/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?notify_interval=.*/notify_interval=300/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?serial=.*/serial=19159101/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?minissdpdsocket=.*/minissdpdsocket=\/var\/run\/minissdpd.sock/" "${XCONFIG_FILE}";
  sed -i -E "s/^.?root_container=.*/root_container=B/" "${XCONFIG_FILE}";
}

function grantPermissions() {
  usermod -a -G "${XGROUP}" minidlna;
}

function adjustFirewall() {
  cat > "/etc/ufw/applications.d/minidlna" << EOF
[miniDLNA]
title=miniDLNA
description=miniDLNA client
ports=8200/tcp|1900/udp
EOF

  ufw allow miniDLNA;
}

####################
# Main starts here #
####################

install;
configure;
grantPermissions;
adjustFirewall;

systemctl restart minidlna.service;
systemctl enable minidlna.service;

(return 0 2>/dev/null) && return 0 || exit 0;
