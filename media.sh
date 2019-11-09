#!/bin/bash

function install() {
  pacman -Syu --noconfirm;
  pacman -S --needed --noconfirm mesa;
  pacman -S --needed --noconfirm ffmpeg;
  pacman -S --needed --noconfirm mpg123;
  pacman -S --needed --noconfirm lame;
  pacman -S --needed --noconfirm flac;
  pacman -S --needed --noconfirm libmpeg2;
  pacman -S --needed --noconfirm xvidcore;
  pacman -S --needed --noconfirm x264;
  pacman -S --needed --noconfirm x265;
  pacman -S --needed --noconfirm alsa-utils;
  pacman -S --needed --noconfirm alsa-plugins;
  pacman -S --needed --noconfirm alsa-firmware;
}

function configure() {
  echo "dtparam=audio=on" >> /boot/config.txt;
}

install;
configure;

exit 0;
