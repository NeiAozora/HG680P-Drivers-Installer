#!/bin/bash

begin_installation() {
    echo "Begin patching the dtb & u-boot file"
    sudo cp meson-gxl-s905x-p212.dtb /boot/dtb/amlogic/
    sudo cp u-boot-p212.bin /boot/
    
    echo "Installing necessary dependencies"
    sudo apt-get update
    sudo apt-get install -y git build-essential gcc-aarch64-linux-gnu
    
    echo "Begin cloning the repository"
    git clone https://github.com/jwrdegoede/rtl8189ES_linux.git -b rtl8189fs
    
    echo "Begin copying the linux build-header"
    mkdir /tmp/build-header
    cp -r /usr/src/linux-headers-$(uname -r)/* /tmp/build-header
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
    aarch64-linux-gnu-gcc -c file2alias.c -o file2alias.o
    aarch64-linux-gnu-gcc -c modpost.c -o modpost.o
    aarch64-linux-gnu-gcc -c mk_elfconfig.c -o mk_elfconfig.o
    aarch64-linux-gnu-gcc -c sumversion.c -o sumversion.o
    aarch64-linux-gnu-gcc -c empty.c -o empty.o
    
    aarch64-linux-gnu-gcc -o modpost modpost.o file2alias.o sumversion.o
    aarch64-linux-gnu-gcc -o mk_elfconfig mk_elfconfig.o
    aarch64-linux-gnu-gcc -c empty.c -o empty.o
    
    
    chmod +x modpost
    echo "Begin compiling modules"
    cd ~/HG680P-Drivers-Installer/rtl8189ES_linux
    make -j4 ARCH=arm64 KSRC=/tmp/build-header
    
    # Build kernel and modules
    sudo cp 8189fs.ko /usr/lib/modules/$(uname -r)/kernel/drivers/net/wireless/realtek/
    sudo depmod -a
    
    # Apply the NetworkManager patch to ignore wlan1
    echo "Applying NetworkManager patch to ignore wlan1"
    sudo bash -c 'cat > /etc/NetworkManager/conf.d/ignore-wlan1.conf <<EOF
    [keyfile]
    unmanaged-devices=interface-name:wlan1
    EOF'
    
    
    sudo modprobe 8189fs
    
    sudo systemctl reload NetworkManager
    
    cd ../..
    rm -rf rtl8189ES_linux
    
    echo -e "Kernel module installation complete.\nPlease reboot the system"
}


echo "This version of the installer has a driver with a known bug that creates two virtual network interfaces (wlan0 and wlan1) when the module is modprobed. However, there is a patch that makes NetworkManager ignore wlan1, ensuring smooth operation. Do you want to proceed? (Y/n)"

read -p ">" answer

case $answer in
    [Yy]* ) 
        echo "Proceeding with the installation..."
        begin_installation
        ;;
    [Nn]* ) 
        echo "Installation aborted."
        exit 1
        ;;
    * ) 
        echo "Please answer yes or no."
        ;;
esac


