#!/bin/bash

XSELECTED_JAIL='';
XSELECTED_IP='';

function selectJail() {
  local XJAILS=( $(fail2ban-client status | grep "Jail list" | sed -e 's/^[^:]\+:[ \t]\+//' | sed 's/,//g') 'Exit' );

  PS3="Select jail: ";

  select XJAIL in "${XJAILS[@]}"; do
    [[ "${XJAIL}" == 'Exit' ]] && exit 0;

    for XITEM in "${XJAILS[@]}"; do
      if [[ "${XITEM}" == "${XJAIL}" ]]; then
        XSELECTED_JAIL="${XITEM}";

        break 2;
      fi
    done

    echo '';
  done

  echo '';
}

function selectIp() {
  local XBANNED_IPS=( $(fail2ban-client status "${XSELECTED_JAIL}" | grep "Banned IP list" | sed -e 's/^[^:]\+:[ \t]\+//' | sed 's/,//g') 'Exit' );

  PS3="Select IP address: ";

  select XBANNED_IP in "${XBANNED_IPS[@]}"; do
    [[ "${XBANNED_IP}" == 'Exit' ]] && exit 0;

    for XITEM in "${XBANNED_IPS[@]}"; do
      if [[ "${XITEM}" == "${XBANNED_IP}" ]]; then
        XSELECTED_IP="${XITEM}";

        break 2;
      fi
    done

    echo '';
  done

  echo '';
}

selectJail;
selectIp;

fail2ban-client set "${XSELECTED_JAIL}" unbanip "${XSELECTED_IP}" > /dev/null;

echo "Unbanned ${XSELECTED_IP} ip address from ${XSELECTED_JAIL} jail";

exit 0;
