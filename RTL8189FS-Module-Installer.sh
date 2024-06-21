#!/bin/bash

echo "Begin patching the dtb & u-boot file"
sudo cp meson-gxl-s905x-p212.dtb /boot/dtb/amlogic/
sudo cp u-boot-p212.bin /boot/

echo "Installing necessary dependencies"
sudo apt-get update
sudo apt-get install -y git build-essential gcc-aarch64-linux-gnu

echo "Begin cloning the repository"
git clone https://github.com/jwrdegoede/rtl8189ES_linux.git -b rtl8189fs

echo "Begin copying the linux build-header"
cp -r /usr/lib/modules/$(uname -r)/build /tmp/
mv /tmp/build /tmp/build-header
echo "Preparing header environments"
cd /tmp/build-header
sudo chown -R $(whoami):$(whoami) .

cd scripts/kconfig
aarch64-linux-gnu-gcc -c -o confdata.o confdata.c
aarch64-linux-gnu-gcc -c -o expr.o expr.c
aarch64-linux-gnu-gcc -c -o conf.o conf.c
aarch64-linux-gnu-gcc -c -o symbol.o symbol.c
aarch64-linux-gnu-gcc -c -o util.o util.c
aarch64-linux-gnu-gcc -c -o lexer.lex.o lexer.lex.c
aarch64-linux-gnu-gcc -c -o menu.o menu.c

cd ../..

cd /tmp/build-header/scripts/basic
aarch64-linux-gnu-gcc -o fixdep fixdep.c
cd ../..

cd scripts/mod
aarch64-linux-gnu-gcc -c modpost.c -o modpost

echo "Begin compiling modules"
cd ~/HG680P-Drivers-Installer/rtl8189ES_linux
sudo make -j4 ARCH=arm64 KSRC=/tmp/build-header

# Build kernel and modules
sudo cp 8189fs.ko /usr/lib/modules/$(uname -r)/kernel/drivers/net/wireless/realtek/
sudo depmod -a
sudo modprobe 8189fs

cd ../..
rm -rf rtl8189ES_linux

echo -e "Kernel module installation complete.\nPlease reboot the system"
