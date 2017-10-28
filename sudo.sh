#!/bin/bash

XDEFAULT_EDITOR="${1}"
XSUDOERS_DIR='/etc/sudoers.d';

pacman -S --needed --noconfirm sudo;

[ -z "${XDEFAULT_EDITOR}" ] && exit 0;

/usr/bin/${XDEFAULT_EDITOR} --version &>/dev/null;

[ ${?} -ne 0 ] && echo 'Warning: Default editor does not exists.' && exit 0;

echo "Defaults editor=/usr/bin/${XDEFAULT_EDITOR}, !env_editor" > "${XSUDOERS_DIR}/editor";

chown -c -R root:root "${XSUDOERS_DIR}";
chmod -c -R 0440 ${XSUDOERS_DIR}/*;

exit 0;
