#!/bin/bash

XUSERS=( ${1} );
XUSER_NAMES=( ${2} );
XGROUP="${3}";
XSYSADMIN="${4}";

function addStorageGroup() {
  groupadd "${XGROUP}";
}

function addUsers() {
  for XINDEX in "${!XUSER_NAMES[@]}"; do
    useradd -c "${XUSER_NAMES[${XINDEX}]}" -d "/mnt/${XUSERS[${XINDEX}]}" -m -g "${XGROUP}" "${XUSERS[${XINDEX}]}";
  done

  usermod -a -G "${XGROUP}" "${XSYSADMIN}";
}

function initUserStorages() {
  for XUSER in "${XUSERS[@]}"; do
    chmod -v 0750 "/mnt/${XUSER}";

    mkdir -v -m 0700 -p "/mnt/${XUSER}/Private";

    chown -v -R "${XUSER}":"${XGROUP}" "/mnt/${XUSER}";
  done
}

addStorageGroup;
addUsers;
initUserStorages;

(return 0 2>/dev/null) && return 0 || exit 0;
