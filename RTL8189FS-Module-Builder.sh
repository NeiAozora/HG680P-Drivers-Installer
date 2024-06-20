#!/bin/bash

# Install necessary dependencies
#sudo apt-get update
#sudo apt-get install -y git build-essential gcc-aarch64-linux-gnu

# Clone the repository
git clone https://github.com/jwrdegoede/rtl8189ES_linux.git -b rtl8189fs
cd rtl8189ES_linux

cp -r /usr/src/linux-headers-6.1.52-ophub /tmp/

# Ensure kernel config file exists
KERNEL_DIR="/tmp/linux-headers-6.1.52-ophub"
if [ ! -f "$KERNEL_DIR/.config" ]; then
    echo ".config file not found! Copying the current kernel config."
    cp /boot/config-$(uname -r) $KERNEL_DIR/.config
fi

# Configure kernel
cd $KERNEL_DIR

cd scripts/kconfig
for file in *.c; do
    # Extract filename without extension
    filename=$(basename -- "$file" .c)
    
    # Compile .c file to .o
    aarch64-linux-gnu-gcc -c -o "$filename.o" "$file"
    
    # Check if compilation was successful
    if [ $? -eq 0 ]; then
        echo "Compiled $file to $filename.o successfully"
    else
        echo "Failed to compile $file"
    fi
done
cd ../../..

cd /tmp/linux-headers-6.1.52-ophub/scripts/basic
aarch64-linux-gnu-gcc -o fixdep fixdep.c
cd ../..


make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig

# Build kernel and modules
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Install module
sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_install INSTALL_MOD_PATH=/tmp/modules_install

# Clean up
cd ../..
rm -rf rtl8189ES_linux

echo "Kernel module installation complete."
