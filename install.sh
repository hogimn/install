#!/bin/bash

D_CUR=$(pwd)
D_BIN=$D_CUR/bin
D_AOSP=$D_CUR/android-7.1.2_r39
D_VBOX_CONFIG=~/.VirtualBox
D_TFTP=$D_VBOX_CONFIG/TFTP
D_DOWNLOAD=$D_BIN/src/download

OPENJDK_HEADLESS_URL=http://old-releases.ubuntu.com/ubuntu/pool/universe/o/openjdk-8/openjdk-8-jre-headless_8u45-b14-1_amd64.deb
OPENJDK_JRE_URL=http://old-releases.ubuntu.com/ubuntu/pool/universe/o/openjdk-8/openjdk-8-jre_8u45-b14-1_amd64.deb
OPENJDK_JDK_URL=http://old-releases.ubuntu.com/ubuntu/pool/universe/o/openjdk-8/openjdk-8-jdk_8u45-b14-1_amd64.deb

OPENJDK_HEADLESS=openjdk-8-jre-headless_8u45-b14-1_amd64.deb
OPENJDK_JRE=openjdk-8-jre_8u45-b14-1_amd64.deb
OPENJDK_JDK=openjdk-8-jdk_8u45-b14-1_amd64.deb

mkdir -p $D_BIN
mkdir -p $D_AOSP
mkdir -p $D_VBOX_CONFIG
mkdir -p $D_DOWNLOAD

####################
# Install Packages #
####################

# https://source.android.com/setup/build/initializing
# Based on Ubuntu 14.04
sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip libelf-dev

sudo apt-get install virtualbox minicom nfs-kernel-server git tftp tftpd

#   File "external/mesa/src/compiler/nir/nir_opcodes_h.py", line 44, in <module>
#     from mako.template import Template
# ImportError: No module named mako.template
#
# https://github.com/epinna/weevely3/issues/3
sudo apt-get python-pip libyaml-dev
sudo pip install prettytable Mako pyaml dateutils --upgrade
sudo apt-get install python-mako

#################
# Install JDK 8 #
#################

if [ -f $D_DOWNLOAD/$OPENJDK_HEADLESS ]; then
    echo $D_DOWNLOAD/$OPENJDK_HEADLESS
else
    wget -O $D_DOWNLOAD/$OPENJDK_HEADLESS $OPENJDK_HEADLESS_URL
fi

if [ -f $D_DOWNLOAD/$OPENJDK_JRE ]; then
    echo $D_DOWNLOAD/$OPENJDK_JRE
else
    wget -O $D_DOWNLOAD/$OPENJDK_JRE $OPENJDK_JRE_URL
fi

if [ -f $D_DOWNLOAD/$OPENJDK_JDK ]; then
    echo $D_DOWNLOAD/$OPENJDK_JDK
else
    wget -O $D_DOWNLOAD/$OPENJDK_JDK $OPENJDK_JDK_URL
fi

cd $D_DOWNLOAD
sudo dpkg -i $OPENJDK_HEADLESS
sudo dpkg -i $OPENJDK_JRE
sudo dpkg -i $OPENJDK_JDK

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
mkdir $D_TFTP/virtualbox
cd $D_TFTP/virtualbox
ln -s $D_AOSP/out/target/product/virtualbox/initrd.img
ln -s $D_AOSP/out/target/product/virtualbox/ramdisk.img
ln -s $D_AOSP/out/target/product/virtualbox/kernel
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
