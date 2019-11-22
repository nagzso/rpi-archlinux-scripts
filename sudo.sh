#!/bin/bash

XDEFAULT_EDITOR="${1}"
XSUDOERS_DIR='/etc/sudoers.d';

function install() {
  pacman -Syu --needed --noconfirm sudo;
}

function configureDefaultEditor {
  local XEDITOR_PATH="${XSUDOERS_DIR}/editor";

  [ -z "${XDEFAULT_EDITOR}" ] && exit 0;

  /usr/bin/${XDEFAULT_EDITOR} --version &>/dev/null;

  [ ${?} -ne 0 ] && echo 'Warning: Default editor does not exists.' && exit 0;

  echo "Defaults editor=/usr/bin/${XDEFAULT_EDITOR}, !env_editor" > "${XEDITOR_PATH}";

  chown -R root:root "${XEDITOR_PATH}";
}

function configure() {
  chmod -R 0440 ${XSUDOERS_DIR}/*;
}

install;
configureDefaultEditor;
configure;

(return 0 2>/dev/null) && return 0 || exit 0;
