#!/bin/bash

uname_r=$(uname -r)
arch_r=$(dpkg --print-architecture)

url="http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use sudo)" 1>&2
  exit 1
  fi

_VER_RUN=""
function get_kernel_version() {
  local ZIMAGE IMG_OFFSET

  [ -z "$_VER_RUN" ] && {
    ZIMAGE=/boot/kernel7l.img
    if [ $arch_r == "arm64" ]; then
      ZIMAGE=/boot/kernel8.img
    fi
    [ -f /boot/firmware/vmlinuz ] && ZIMAGE=/boot/firmware/vmlinuz
    IMG_OFFSET=$(LC_ALL=C grep -abo $'\x1f\x8b\x08\x00' $ZIMAGE | head -n 1 | cut -d ':' -f 1)
    _VER_RUN=$(dd if=$ZIMAGE obs=64K ibs=4 skip=$(( IMG_OFFSET / 4)) 2>/dev/null | zcat | grep -a -m1 "Linux version" | strings | awk '{ print $3; }')
  }
  echo "$_VER_RUN"
  
  return 0
}

function download_install_debpkg() {
  local version-kernel-headers version-kernel
  mkdir temporary_dir
  
  wget http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/ -O rpi-kernel-version-text 
  
  version_kernel_headers=`cat rpi-kernel-version-text  | grep raspberrypi-kernel-headers | grep arm64 | awk 'END { print }' | awk '{print $6}' | awk -F '\"' '{print $2} '`
  version_kernel=`cat rpi-kernel-version-text  | grep raspberrypi-kernel | grep arm64 | awk 'END { print }' | awk '{print $6}' | awk -F '\"' '{print $2} '`

  wget -P temporary_dir $url$version_kernel_headers
  wget -P temporary_dir $url$version_kernel
  
  sudo dpkg -i temporary_dir/$version_kernel_headers
  sudo dpkg -i temporary_dir/$version_kernel
  
  #copy bcm2711-rpi-4-b.dtb to the specified directory,then install again
  sudo cp /boot/bcm2711-rpi-4-b.dtb /etc/flash-kernel/dtbs/
  sudo dpkg -i temporary_dir/$version_kernel
  
  rm -r -f temporary_dir
}

#fix desktop
function fix_desktop () {
  git clone https://github.com/Seeed-Studio/seeed-linux-dtoverlays
  cd seeed-linux-dtoverlays
  
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
  cp /boot/overlays/reTerminal.dtbo /boot/firmware/overlays/reTerminal.dtbo
  
  make all_rpi
  cd /boot/firmware/overlays/
  cp vc4-kms-v3d-pi4.dtbo vc4-kms-v3d-pi4.dtbo.bak
  cp /home/ubuntu/seeed-linux-dtoverlays/overlays/rpi/reTerminal-overlay.dts /boot/firmware/overlays/vc4-kms-v3d-pi4.dtbo
  
  apt -y --force-yes install ubuntu-desktop
}

#change the running kernel to 5.10.
function install_kernel() {
  local vmlinuz kernel_name
  
  sudo apt install make
  sudo apt -y --force-yes install build-essential
  download_install_debpkg
  
  cd /boot/
  get_kernel_version
  vmlinuz="vmlinuz-$_VER_RUN"
  sudo cp $vmlinuz $vmlinuz.bak
  sudo cp kernel8.img $vmlinuz
  
  kernel_name=`find /boot/dtbs/ | grep + | awk 'END {print}' | awk -F "\/" '{print $4}'`
  
  sudo cp bcm2711-rpi-cm4.dtb dtbs./
  sudo rm dtb-$kernel_name
  sudo ln -s dtbs/$kernel_name/./bcm2711-rpi-cm4.dtb dtb-$kernel_name
  sudo update-initramfs -u
  sync
  
  return 0
}

function install() {
  
  install_kernel
  
  fix_desktop
  
  echo "------------------------------------------------------"
  echo "Please reboot your device to apply all settings"
  echo "Enjoy!"
  echo "------------------------------------------------------"
}
install

