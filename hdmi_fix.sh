#!/bin/bash

############################
#        DEPRECATED        #
#                          #
# Only set in config.txt:  #
#   hdmi_force_hotplug=1   #
#   hdmi_ignore_cec_init=1 #
############################

##
# Some TVs/receivers only report their capabilities (EDID) through HDMI when powered on before the Raspberry PI.
#
# If TV does not get the right resolution or CEC does not work when Pi is powered before the TV/receiver then you can:
#   Step 1: Power on TVs/receivers
#   Step 2: Power on Raspberry PI
#   Step 3: Run sudo /opt/vc/bin/tvservice -d edid.dat
#   Step 4: Copy the edid.dat to the FAT partition
#   Step 5: Add to config.txt: hdmi_edid_file=1 and hdmi_force_hotplug=1
#
# Note: If you change TV/receiver or use a different HDMI input you should re-run this script.
##

XPARAM_RESET="${1}";
XCONFIG_FILE='/boot/config.txt';
XEDID_NAME='edid.dat';
XEDID_FILE="/boot/${XEDID_NAME}";

function readPrompt {
  while true; do
    read -r -p "${1} [Yes/No]: " XANSWER
    case "${XANSWER}" in
      [Yy]es ) return 0;;
      [Nn]* ) return 1;;
    esac
  done
}

function raiseError() {
  echo "Error: ${1}
Follow next steps:
  1. Power on Your TV/receiver
  2. Reboot Raspberry PI
  3. Re-run this script"

  exit 1;
}

function checkPreconditions() {
  $(readPrompt "Is Your TV/receiver turned on and is HDMI connected?") \
    || raiseError "Tv/receiver must be turned on!";

  $(readPrompt "Did You powered on Raspberry PI after the TV/receiver?") \
    || raiseError "Raspberry PI must be powered on after the TV/receiver!";

  [[ "$(whoami)" != 'root' ]] && echo "Run script as root or via sudo" && exit 1;

  [ ! -e "${XCONFIG_FILE}" ] && echo "Could not find ${XCONFIG_FILE}" && exit 1;

  [ -e "${XEDID_FILE}" ] && removeHdmiFix && raiseError "${XEDID_NAME} file is already exists.";
}

function addHdmiFix() {
  local XRESULT="$(/opt/vc/bin/tvservice -d ${XEDID_FILE})";

  [[ "${XRESULT}" == "Nothing written!" ]] && raiseError "Tv/receiver must be turned on!";

  grep -q '^hdmi_edid_file' "${XCONFIG_FILE}" \
    && sed -i 's/^hdmi_edid_file.*/hdmi_edid_file=1/' "${XCONFIG_FILE}" \
    || echo 'hdmi_edid_file=1' >> "${XCONFIG_FILE}";

  grep -q '^hdmi_force_hotplug' "${XCONFIG_FILE}" \
    && sed -i 's/^hdmi_force_hotplug.*/hdmi_force_hotplug=1/' "${XCONFIG_FILE}" \
    || echo 'hdmi_force_hotplug=1' >> "${XCONFIG_FILE}";

  grep -q '^hdmi_ignore_cec_init' "${XCONFIG_FILE}" \
    && sed -i 's/^hdmi_ignore_cec_init.*/hdmi_ignore_cec_init=1/' "${XCONFIG_FILE}" \
    || echo 'hdmi_ignore_cec_init=1' >> "${XCONFIG_FILE}";

  echo "Note: If you change TV/receiver or use a different HDMI input you should re-run this script.";
}

function removeHdmiFix() {
  rm -f "${XEDID_FILE}";

  sed -i '/^hdmi_edid_file/d' "${XCONFIG_FILE}";
  sed -i '/^hdmi_force_hotplug/d' "${XCONFIG_FILE}";
  sed -i '/^hdmi_ignore_cec_init/d' "${XCONFIG_FILE}";
}

######################
# Script starts here #
######################

checkPreconditions;

cp -v -i "${XCONFIG_FILE}" "${XCONFIG_FILE}.bak";

[[ "${XPARAM_RESET}" != '--reset' ]] && addHdmiFix || removeHdmiFix;

exit 0;
