#!/bin/bash

function install_driver() {
  sudo apt install -y --force-yes build-essential
  git clone https://github.com/Seeed-Studio/seeed-linux-dtoverlays/
  
  cd seeed-linux-dtoverlays
  
  sed -i "227 i \tfragment@8 {\n\ttarget = <&hdmi0>;\n\t\t__overlay__  {\n\t\t\tstatus = "disabled";\n\t\t\t};\n\t\t};\n\tfragment@9 {\n\t\ttarget = <&hdmi1>;\n\t\t__overlay__  {\n\t\t\tstatus = "disabled";\n\t\t};\n\t};" overlays/rpi/reTerminal-overlay.dts
  make all_rpi
  make install_rpi
  
  sudo echo "#-------------------------------------------
dtoverlay=vc4-fkms-v3d
enable_uart=1
dtoverlay=dwc2,dr_mode=host
dtparam=ant2
disable_splash=1
ignore_lcd=1
dtoverlay=vc4-kms-v3d-pi4
dtoverlay=i2c3,pins_4_5
gpio=13=pu
dtoverlay=reTerminal,tp_rotate=1
#------------------------------------------" >> /boot/firmware/config.txt
  
  sudo cp overlays/rpi/reTerminal-overlay.dtbo /boot/firmware/overlays/reTerminal.dtbo
}

function install() {
  install_driver
  sudo apt install ubuntu-desktop

  echo "------------------------------------------------------"
  echo "Enjoy!"
  echo "------------------------------------------------------"
}

# Check root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use sudo)" 1>&2
  exit 1
  fi

install

