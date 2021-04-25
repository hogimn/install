#!/bin/bash

D_CUR=$(pwd)
D_BIN=$D_CUR/bin
D_AOSP=$D_CUR/android-7.1.2_r39
D_VBOX_CONFIG=~/.VirtualBox
D_TFTP=$D_VBOX_CONFIG/TFTP
mkdir -p $D_BIN
mkdir -p $D_AOSP
mkdir -p $D_VBOX_CONFIG

####################
# Install Packages #
####################

# JDK install
sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install openjdk-8-jdk

# https://source.android.com/setup/build/initializing
# Based on Ubuntu 14.04
sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip libelf-dev

sudo apt-get install virtualbox minicom nfs-kernel-server git libssl-dev u-boot-tools libsdl1.2debian:i386 tftp tftpd ddd openjdk-8-jdk

mkdir -p $D_VBOX_CONFIG

##################
# Git repository #
##################

git clone https://github.com/hogimn/TFTP $D_TFTP
git clone https://github.com/hogimn/gpxe
git clone https://github.com/hogimn/build -b virtualbox

#####################
# VirtualBox Config #
#####################

# syslinux
cp /usr/lib/syslinux/pxelinux.0 $D_TFTP/pxeAndroid.pxe
cp /usr/lib/syslinux/menu.c32 $D_TFTP/menu.c32

# Virtualbox Setting
VBoxManage setextradata global \
VBoxInternal/Devices/pcbios/0/Config/LanBootRom \
$D_VBOX_CONFIG/1af41000.rom

# make TFTP links
cd $D_TFTP
ln -s $D_AOSP/out/target/product/virtualbox/initrd.img
ln -s $D_AOSP/out/target/product/virtualbox/ramdisk.img
ln -s $D_AOSP/out/target/product/virtualbox/kernel.img
cd $D_CUR

##############
# Build gPXE #
##############

cd gpxe/src
make bin/1af41000.rom -j8 
cd $D_CUR
echo "before executing fix_rom.py"
ls -l gpxe/src/bin/1af41000.rom | awk '{print $5}'
ROM_SIZE=$(ls -l gpxe/src/bin/1af41000.rom | awk '{print $5}' 2>&1)

python fix_rom.py $ROM_SIZE

echo "after executing fix_rom.py"
ls -l gpxe/src/bin/1af41000.rom | awk '{print $5}'

cp gpxe/src/bin/1af41000.rom $D_VBOX_CONFIG

########
# AOSP #
########

curl https://storage.googleapis.com/git-repo-downloads/repo-1 > $D_BIN/repo
chmod a+x $D_BIN/repo

cd $D_AOSP
$D_BIN/repo init --depth=1 -u https://github.com/hogimn/platform_manifest -b virtualbox
$D_BIN/repo sync  -f --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
cd $D_CUR
