#!/bin/bash

echo "This is a test code for auto start"
password="qwer1234"

#description:download the .deb file into ~/raspberrypi-kernel-headers_1.20210303-1_arm64/
mkdir raspberrypi-kernel-headers_1.20210303-1_arm64
wget -P raspberrypi-kernel-headers_1.20210303-1_arm64 http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel-headers_1.20210303-1_arm64.deb

#description:download the .deb file into ~/raspberrypi-kernel_1.20210303-1_arm64/
mkdir raspberrypi-kernel_1.20210303-1_arm64
wget -P raspberrypi-kernel_1.20210303-1_arm64 http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel_1.20210303-1_arm64.deb

echo "qwer1234" | -S sudo dpkg -i ~/raspberrypi-kernel-headers_1.20210303-1_arm64/raspberrypi-kernel-headers_1.20210303-1_arm64.deb
echo "qwer1234" | -S sudo dpkg -i ~/raspberrypi-kernel_1.20210303-1_arm64/raspberrypi-kernel_1.20210303-1_arm64.deb

#description:copy bcm2711-rpi-4-b.dtb to the specified directory
echo "qwer1234" | -S sudo cp /boot/bcm2711-rpi-4-b.dtb /etc/flash-kernel/dtbs/

#description:delate the two temporary directories
rm -r -f raspberrypi-kernel-headers_1.20210303-1_arm64 raspberrypi-kernel_1.20210303-1_arm64


