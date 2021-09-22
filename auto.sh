#!/bin/bash

uname_r=$(uname -r)
arch_r=$(dpkg --print-architecture)

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

#change the running kernel to 5.10.17
function change_kernel_version() {
  local vmlinuz
  mkdir temporary_dir
  
  wget -P temporary_dir http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel-headers_1.20210303-1_arm64.deb
  wget -P temporary_dir http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel_1.20210303-1_arm64.deb
  sudo dpkg -i temporary_dir/raspberrypi-kernel-headers_1.20210303-1_arm64.deb
  sudo dpkg -i temporary_dir/raspberrypi-kernel_1.20210303-1_arm64.deb

  #copy bcm2711-rpi-4-b.dtb to the specified directory,then install again
  sudo cp /boot/bcm2711-rpi-4-b.dtb /etc/flash-kernel/dtbs/
  sudo dpkg -i temporary_dir/raspberrypi-kernel_1.20210303-1_arm64.deb
  
  rm -r -f temporary_dir

  cd /boot/
  get_kernel_version
  vmlinuz="vmlinuz-$_VER_RUN"
  sudo cp $vmlinuz $vmlinuz.bak
  sudo cp kernel8.img $vmlinuz
  
  #sudo cp vmlinuz-5.4.0-1042-raspi vmlinuz-5.4.0-1042-raspi.bak
  #sudo cp kernel8.img vmlinuz-5.4.0-1042-raspi
  sudo cp bcm2711-rpi-cm4.dtb dtbs/5.10.17-v8+/./
  sudo rm dtb-5.10.17-v8+
  sudo ln -s dtbs/5.10.17-v8+/./bcm2711-rpi-cm4.dtb dtb-5.10.17-v8+
  sudo update-initramfs -u
  sync
  
  return 0
}

function install() {
  sudo apt install make 
  sudo apt install build-essential
  change_kernel_version
  
  echo "------------------------------------------------------"
  echo "Please reboot your device to apply all settings"
  echo "Enjoy!"
  echo "------------------------------------------------------"
}
install

