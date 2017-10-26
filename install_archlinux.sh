#!/bin/bash

## How it works
#
#  Mode 1 (everything is on the SD-Card):
#    - delete SD-Card partitions and create new partitions
#    - format created partitions
#    - install Arch Linux
#    - prepare sshd_config for remote access
#
#  Mode 2 (boot partition is on the SD-Card and root partition is on external device):
#    - delete SD-Card partitions and create new partitions
#    - format created partitions
#    - format selected external device partition
#    - install Arch Linux
#    - configure boot routine (cmdline.txt) to point to the external device's partition
#    - prepare sshd_config for remote access
#
##

XURL_NAME='http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz';
XTAR_NAME='ArchLinuxARM.tar.gz';
XBOOT='boot';
XROOT='root';

function readPrompt() {
  while true; do
    read -r -p "${1} [Yes/No]: " XANSWER;

	  case "${XANSWER}" in
      [Yy]es ) return 0;;
      [Nn]* ) return 1;;
    esac
  done
}

function checkBsdtar() {
  echo -n 'Checking bsdtar installation...';

  bsdtar --version &>/dev/null;

  if [[ ${?} -ne 0 ]]; then
    echo '';

    $(readPrompt "bsdtar is not installed but required. Do you want to install it?") || exit 0;
  else
    echo -e " [OK]\n";

    return 0;
  fi

  local XDISTRIBUTION="$(cat /etc/*-release)";

  if [[ ${XDISTRIBUTION} =~ ^ID=[Aa]rch.* ]]; then
      sudo pacman -S --noconfirm bsdtar;
    else if [[ ${XDISTRIBUTION} =~ ^ID=[Uu]buntu.* ]]; then
        sudo apt-get install -y bsdtar;
      else if [[ ${XDISTRIBUTION} =~ ^ID=[Ff]edora.* ]]; then
        sudo yum install -y bsdtar;
      fi
    fi
  fi

  echo -e "bsdtar is installed successfully\n";
}

function isRoot() {
  [[ "$(whoami)" != "root" ]] && echo 'The script must be executed as root (sudo su root)!' && exit 1;
}

function unmountPartitions() {
  for XPARTITION in /dev/${1}*; do
    umount "${XPARTITION}";
  done
}

function setDesiredPartitions() {
  local XMODE1='Boot and root partitions are on the SD-Card';
  local XMODE2='Boot partition is on the SD-Card and root partition is on an external device';
  local XMODES=( "${XMODE1}" "${XMODE2}" 'Exit' );

  PS3='Select mode: ';

  select XMODE in "${XMODES[@]}"; do
    case "${XMODE}" in
      "${XMODE1}" )
        PS3='Select SD-Card: ';
        break;;

      "${XMODE2}" )
        PS3='Select SD-Card for boot installation: ';
        break;;

      'Exit' )
        exit 0;;

      * )
        echo "Invalid option";;
    esac
  done

  echo '';

  local XOLD_IFS=${IFS};

  IFS=$'\n';

  local XDEVICES=( $(lsblk -d -n -e 11,1 -o 'NAME,SIZE,TYPE') 'Exit' );

  select XDEVICE in "${XDEVICES[@]}"; do
    [[ "${XDEVICE}" == 'Exit' ]] && exit 0;

    for XITEM in "${XDEVICES[@]}"; do
      if [[ "${XITEM}" == "${XDEVICE}" ]]; then
        break 2;
      fi
    done

    echo '';
  done

  echo '';

  XBOOT_PARTITION="${XDEVICE%% *}";
  XROOT_PARTITION="${XBOOT_PARTITION}";

  [[ "${XMODE}" != "${XMODE2}" ]] && return 0;

  local XROOT_PARTITIONS=( $(lsblk -l -n -e 11,1 -o 'NAME,FSTYPE,SIZE,TYPE' | grep ".*part.*" | grep -v ".*${XBOOT_PARTITION}.*") 'Exit' );

  IFS=${XOLD_IFS};
  PS3="Select the external device's partition for root installation: ";

  select XROOT_PARTITION in "${XROOT_PARTITIONS[@]}"; do
    [[ "${XROOT_PARTITION}" == 'Exit' ]] && exit 0;

    for XITEM in "${XROOT_PARTITIONS[@]}"; do
      if [[ "${XITEM}" == "${XROOT_PARTITION}" ]]; then
        break 2;
      fi
    done
  done

  XROOT_PARTITION="${XROOT_PARTITION%% *}";
}

function createPartitions() {
  unmountPartitions "${XBOOT_PARTITION}";

  $(readPrompt "Do you really want to delete ${XBOOT_PARTITION}?") || exit 0;

  fdisk "/dev/${XBOOT_PARTITION}" << EOF
o
n
p
1

+100M
t
c
n
p
2


w
EOF

  [[ ${?} -ne 0 ]] && echo "Error, could not create partitions on ${XBOOT_PARTITION}" && exit 1;

  $(readPrompt "Do you really want to format /dev/${XBOOT_PARTITION}1?") || exit 0;

  mkfs.vfat "/dev/${XBOOT_PARTITION}1";

  [[ ${?} -ne 0 ]] && echo "Error, could not format ${XBOOT_PARTITION}1" && exit 1;

  if [[ "${XBOOT_PARTITION}" != "${XROOT_PARTITION}" ]]; then
    umount "/dev/${XROOT_PARTITION}";

    mkfs.ntfs -f "/dev/${XBOOT_PARTITION}2";
  else
    XROOT_PARTITION="${XBOOT_PARTITION}2";
  fi

  $(readPrompt "Do you really want to format /dev/${XROOT_PARTITION}?") || exit 0;

  mkfs.ext4 "/dev/${XROOT_PARTITION}";

  [[ ${?} -ne 0 ]] && echo "Error, could not format ${XROOT_PARTITION}" && exit 1;
}

function cleanup() {
  rm -r -f "${XTAR_NAME}";
  rm -r -f "${XBOOT}";
  rm -r -f "${XROOT}";
}

function configureBoot() {
  local XPARTUUID="$(blkid | grep .*${XROOT_PARTITION}.* | sed -e 's|^.*PARTUUID="\(.*\)"|\1|')";

  sed -i "s|root=[^\ ]*|root=PARTUUID=${XPARTUUID}|" "${XBOOT}/cmdline.txt";
}

function configureSshd() {
  local XSSHD_CONFIG_PATH="${XROOT}/etc/ssh/sshd_config";

  sed -i "s|^.*Port .*$|Port 22|" "${XSSHD_CONFIG_PATH}";
  sed -i "s|^.*Protocol .*$|Protocol 2|" "${XSSHD_CONFIG_PATH}";
  sed -i "s|^.*PermitRootLogin .*$|PermitRootLogin yes|" "${XSSHD_CONFIG_PATH}";
  sed -i "s|^.*PasswordAuthentication .*$|PasswordAuthentication yes|" "${XSSHD_CONFIG_PATH}";
  sed -i "s|^.*PermitEmptyPasswords .*$|PermitEmptyPasswords no|" "${XSSHD_CONFIG_PATH}";
  sed -i "s|^.*TCPKeepAlive .*$|TCPKeepAlive yes|" "${XSSHD_CONFIG_PATH}";

  echo "Note: Consider disabling root login (PermitRootLogin no) in ${XSSHD_CONFIG_PATH}";
}

function installPartitions() {
  cd /root;

  cleanup;

  mkdir "${XBOOT}";
  mkdir "${XROOT}";

  mount "/dev/${XBOOT_PARTITION}1" "${XBOOT}";
  mount "/dev/${XROOT_PARTITION}" "${XROOT}";

  echo "Downloading Arch Linux from ${XURL_NAME} ...";
  wget -O "${XTAR_NAME}" "${XURL_NAME}";

  echo 'Extracting Arch Linux ...';
  bsdtar -xpf "${XTAR_NAME}" -C "${XROOT}";

  [[ ${?} -ne 0 ]] && echo 'Error, could not extract Arch Linux' && exit 1;

  sync;

  mv ${XROOT}/${XBOOT}/* "${XBOOT}";

  [[ "${XBOOT_PARTITION}" != "${XROOT_PARTITION%?}" ]] && configureBoot;

  configureSshd;

  umount "${XBOOT}";
  umount "${XROOT}";

  cleanup;

  unmountPartitions "${XBOOT_PARTITION}";
  unmountPartitions "${XROOT_PARTITION%?}";

  echo "Done";
}

######################
# Script starts here #
######################

isRoot;
checkBsdtar;
setDesiredPartitions;
createPartitions;
installPartitions;

exit 0;
