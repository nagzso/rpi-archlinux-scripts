#!/bin/bash

# The passwords (SHA-512) are generated via mkpasswd
# The passwd uses SHA-512 encrypted passwords
# Example: mkpasswd 'KerekAsztal' -S 'h3LSvD1XanC' -R 10000 -m sha-512
# For more information: man mkpasswd
# mkpasswd is accessible in the whois package (sudo apt-get install whois)
# If you want to hardcode your password without encryption, then use: echo "username:password" | chpasswd;
#
# ./init_pi.sh 'the_encrypted_password_of_root' 'en_US.UTF-8 UTF-8' 'en_US.UTF-8' 'Europe/Budapest' 'homeServer-RPI3' 'Hungary' 'hu' 'sysadmin' 'the_encrypted_password_of_sysadmin'

XPASSWORD="${1}";
XLOCALE_LANGUAGE_GEN="${2}";
XLOCALE_LANGUAGE="${3}";
XTIMEZONE="${4}";
XHOSTNAME="${5}";
XLOCATION="${6}";
XKEYBOARD="${7}";
XSYSADMIN="${8}";
XSYSADMIN_PASSWORD="${9}";

function initPacman() {
  pacman-key --init;
  pacman-key --populate archlinuxarm;

  local XPACMAN_CONF_FILE='/etc/pacman.conf';

  if [ -e "${XPACMAN_CONF_FILE}.bak" ]; then
    cp -v "${XPACMAN_CONF_FILE}.bak" "${XPACMAN_CONF_FILE}";
  else
    cp -v "${XPACMAN_CONF_FILE}" "${XPACMAN_CONF_FILE}.bak";
  fi
  
  sed -i 's/^#Color.*/Color/' "${XPACMAN_CONF_FILE}";
  
  cat << EOF >> "${XPACMAN_CONF_FILE}";
# Defined by user
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/i686
EOF
}

function initPackages() {
  pacman -Syu --noconfirm;
  pacman -S --needed --noconfirm base-devel;
  pacman -S --needed --noconfirm lsb-release;
  pacman -S --needed --noconfirm openssh;
  pacman -S --needed --noconfirm ntfs-3g;
  pacman -S --needed --noconfirm wget;
  pacman -S --needed --noconfirm whois;
}

function addSysadmin() {
  if [ ! $(getent passwd "${XSYSADMIN}") ]; then
    useradd -c 'System administrator' -m -r "${XSYSADMIN}";

    echo "${XSYSADMIN}:${XSYSADMIN_PASSWORD}" | chpasswd -e;

    cat << EOF > "/etc/sudoers.d/${XSYSADMIN}";
Defaults:%${XSYSADMIN} targetpw
%${XSYSADMIN} ALL=(ALL) ALL
EOF

    chown -c -R root:root /etc/sudoers.d;
    chmod -c 0440 /etc/sudoers.d/*;
  fi
}

function initLogout() {
  local XBASH_LOGOUT_FILE='/etc/bash.bash_logout';

  if [ -e "${XBASH_LOGOUT_FILE}.bak" ]; then
    cp -v "${XBASH_LOGOUT_FILE}.bak" "${XBASH_LOGOUT_FILE}";
  else
    cp -v "${XBASH_LOGOUT_FILE}" "${XBASH_LOGOUT_FILE}.bak";
  fi

  cat << EOF >> "${XBASH_LOGOUT_FILE}";
reset;
EOF
}

function initTime() {
  timedatectl set-ntp true;
  timedatectl set-local-rtc 0;
  timedatectl set-timezone "${XTIMEZONE}";
}

function initLocale() {
  local XLOCALE_GEN_FILE='/etc/locale.gen';

  if [ -e "${XLOCALE_GEN_FILE}.bak" ]; then
    cp -v "${XLOCALE_GEN_FILE}.bak" "${XLOCALE_GEN_FILE}";
  else
    cp -v "${XLOCALE_GEN_FILE}" "${XLOCALE_GEN_FILE}.bak";
  fi
  
  sed -i "s/^#${XLOCALE_LANGUAGE_GEN}.*/${XLOCALE_LANGUAGE_GEN}/" "${XLOCALE_GEN_FILE}";

  chmod 0644 "${XLOCALE_GEN_FILE}";

  locale-gen;
  
  rm -v /etc/locale.conf;
  rm -v /etc/vconsole.conf;

  localectl set-locale LANG="${XLOCALE_LANGUAGE}" LC_COLLATE=C;

  localectl set-keymap --no-convert "${XKEYBOARD}";
  
  cat << EOF >> /etc/vconsole.conf;
FONT=lat2-16
FONT_MAP=8859-2
EOF
}

function initHost() {
  hostnamectl set-hostname "${XHOSTNAME}";
  hostnamectl set-location "${XLOCATION}";

  systemctl enable dhcpcd.service;
  systemctl enable systemd-networkd.service;
  systemctl enable systemd-resolved.service;
}

function addAliases() {
  local XBASHRC_FILE='/etc/bash.bashrc';

  if [ -e "${XBASHRC_FILE}.bak" ]; then
    cp -v "${XBASHRC_FILE}.bak" "${XBASHRC_FILE}";
  else
    cp -v "${XBASHRC_FILE}" "${XBASHRC_FILE}.bak";
  fi

  cat << EOF >> "${XBASHRC_FILE}";

# Defined by user
alias aliases='cat /etc/bash.bashrc | grep alias'
alias ll='ls -lAh --color'
alias ls='ls -A --color'
alias rm='rm -Irv'
alias mac='cat /sys/class/net/eth0/address'
alias usb='lsusb -tv'
alias version='/opt/vc/bin/vcgencmd version'
alias packages_list='pacman -Qe'
alias packages_update='pacman -Syu'
alias packages_remove='pacman -Rsu'
alias samba_users='pdbedit -L -v'
alias pip_update_all='pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install -U'
alias psof='ps aux | grep'
alias psc='ps xawf -eo pid,user,cgroup,args'
EOF
}

function removeAlarm() {
  [ $(getent passwd alarm) ] && userdel -r alarm;
}

######################
# Script starts here #
######################

echo "root:${XPASSWORD}" | chpasswd -e;

initPacman;
initPackages;
initLogout;
initTime;
initLocale;
initHost;
addAliases;
addSysadmin;
removeAlarm;

reboot;
