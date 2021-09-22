#!/bin/bash

echo "This is a test code for auto start"
password="12345678"

if [[ $EUID ne 0 ]]; then
    echo "This script must be run as root (use sudo)" 1>&2
    exit 1
    fi

#3.
#description:creat two directories and download two .deb files in respective directory
mkdir raspberrypi-kernel-headers_1.20210303-1_arm64 raspberrypi-kernel_1.20210303-1_arm64
wget -P raspberrypi-kernel-headers_1.20210303-1_arm64 http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel-headers_1.20210303-1_arm64.deb
wget -P raspberrypi-kernel_1.20210303-1_arm64 http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel_1.20210303-1_arm64.deb

sudo dpkg -i ./raspberrypi-kernel-headers_1.20210303-1_arm64/raspberrypi-kernel-headers_1.20210303-1_arm64.deb
sudo dpkg -i ./raspberrypi-kernel_1.20210303-1_arm64/raspberrypi-kernel_1.20210303-1_arm64.deb

#description:copy bcm2711-rpi-4-b.dtb to the specified directory,then install again
echo $password | sudo -S cp /boot/bcm2711-rpi-4-b.dtb /etc/flash-kernel/dtbs/
echo $password | sudo -S dpkg -i ./raspberrypi-kernel_1.20210303-1_arm64/raspberrypi-kernel_1.20210303-1_arm64.deb

#description:delate the two temporary directories
rm -r -f raspberrypi-kernel-headers_1.20210303-1_arm64 raspberrypi-kernel_1.20210303-1_arm64

#description:change the running kernel to 5.10.17
cd /boot/
echo $password | sudo -S cp vmlinuz-5.4.0-1042-raspi vmlinuz-5.4.0-1042-raspi.bak
echo $password | sudo -S cp kernel8.img vmlinuz-5.4.0-1042-raspi
echo $password | sudo -S cp bcm2711-rpi-cm4.dtb dtbs/5.10.17-v8+/./
echo $password | sudo -S rm dtb-5.10.17-v8+
echo $password | sudo -S ln -s dtbs/5.10.17-v8+/./bcm2711-rpi-cm4.dtb dtb-5.10.17-v8+
echo $password | sudo -S update-initramfs -u
sync
#temporary annotation
#echo $password | sudo -S reboot
cd ~

#4.
#description:install seeed-linux-dtoverlay driver
echo $password | sudo -S apt install make
echo $password | sudo -S apt -y install build-essential

git clone https://github.com/Seeed-Studio/seeed-linux-dtoverlays
cd seeed-linux-dtoverlays
echo $password | sudo -S make all_rpi
echo $password | sudo -S make install_rpi

#description:add the following code into /boot/firmware/config.txt
echo "#-------------------------------------------
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

echo $password | sduo -S cp /boot/overlays/reTerminal.dtbo /boot/firmware/overlays/reTerminal.dtbo

git clone https://github.com/raspberrypi/linux
#description:there is something wrong with the hdmi driver.So we need to disable it now.
sed '32,45 s/okay/disabled/g' /home/ubuntu/linux/arch/arm/boot/dts/overlays/vc4-kms-v3d-pi4-overlay.dts

cp /home/ubuntu/linux/arch/arm/boot/dts/overlays/vc4-kms-v3d-pi4-overlay.dts /home/ubuntu/seeed-linux-dtoverlays/overlays/rpi/
cp /home/ubuntu/linux/arch/arm/boot/dts/overlays/cma-overlay.dts /home/ubuntu/seeed-linux-dtoverlays/overlays
cd /home/ubuntu/seeed-linux-dtoverlays
make all_rpi
cd /boot/firmware/overlays/
echo $password | sudo -S cp vc4-kms-v3d-pi4.dtbo vc4-kms-v3d-pi4.dtbo.bak
echo $password | sudo -S cp /home/ubuntu/seeed-linux-dtoverlays/overlays/rpi/vc4-kms-v3d-pi4-overlay.dtbo /boot/firmware/overlays/vc4-kms-v3d-pi4.dtbo


#5.
echo $password | sudo -S apt install ubuntu-desktop
echo $password | sudo -S reboot

