#!/bin/bash

D_CUR=$(pwd)
D_BIN=$D_CUR/bin
mkdir -p $D_BIN
D_DOWNLOAD=$D_BIN/src/download
D_JDK=$D_BIN/jdk1.6.0_45
D_NDK=$D_BIN/android-ndk-r6
D_COMPILER=$D_BIN/arm-2010q1
D_AOSP=$D_CUR/../android-2.3.5_r1

ORACLE_JDK_IMAGE=jdk-6u45-linux-x64.bin
ORACLE_JDK_URL=http://mirror.hostway.co.kr/Java/jdk-6u45-linux-x64.bin

NDK_IMAGE=android-ndk-r6-linux-x86.tar.bz2
NDK_URL=http://dl.google.com/android/ndk/android-ndk-r6-linux-x86.tar.bz2

COMPILER_IMAGE=arm-2010q1-188-arm-none-eabi-i686-pc-linux-gnu.tar.bz2
COMPILER_URL=http://www.codesourcery.com/sgpp/lite/arm/portal/package6493/public/arm-none-eabi/arm-2010q1-188-arm-none-eabi-i686-pc-linux-gnu.tar.bz2

echo -n "Do you want to start the installation? [y/n]?"
read choice 
if [ "$choice" == "y" ]; then
    echo "Starting the installation..."
else echo "Return from the installation."
    return
fi

sudo apt-get install --only-upgrade wget

# Select SDK image between x86_64 and x86
if [ `uname -p` = "x86_64" ]; then
    echo "Initializing x86_64 version ..."
    AndroidSDK=$D_BIN/adt-bundle-linux-x86_64-20140702/sdk
    SDK_IMAGE=adt-bundle-linux-x86_64-20140702.zip
    SDK_URL=https://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140702.zip
else
    echo "Initializing x86 version ..."
    AndroidSDK=$D_BIN/adt-bundle-linux-x86-20140702/sdk
    SDK_IMAGE=adt-bundle-linux-x86-20140702.zip
    SDK_URL=https://dl.google.com/android/adt/adt-bundle-linux-x86-20140702.zip
fi

# Download
echo "Downloading Oracle JDK ..."
if [ -f $D_DOWNLOAD/$ORACLE_JDK_IMAGE ]; then
    echo $D_DOWNLOAD/$ORACLE_JDK_IMAGE
else
    wget -P $D_DOWNLOAD $ORACLE_JDK_URL
    chmod +x $D_DOWNLOAD/$ORACLE_JDK_IMAGE 
fi

echo "Downloading cross compiler ..."
if [ -f $D_DOWNLOAD/$COMPILER_IMAGE ]; then
    echo $D_DOWNLOAD/$COMPILER_IMAGE
else
    wget -O $D_DOWNLOAD/$COMPILER_IMAGE $COMPILER_URL
fi

echo "Downloading Android SDK ..."
if [ -f $D_DOWNLOAD/$SDK_IMAGE ]; then
    echo $D_DOWNLOAD/$SDK_IMAGE
else
    wget -O $D_DOWNLOAD/$SDK_IMAGE $SDK_URL
fi

echo "Downloading Android NDK ..."
if [ -f $D_DOWNLOAD/$NDK_IMAGE ]; then
    echo $D_DOWNLOAD/$NDK_IMAGE
else
    wget -O $D_DOWNLOAD/$NDK_IMAGE $NDK_URL
fi

# Install
cd $D_BIN

if [ -d $D_JDK ]; then
    echo "You already have Oracle JDK."
else
    $D_DOWNLOAD/$ORACLE_JDK_IMAGE
fi

if [ -x $D_COMPILER ]; then
    echo "You already have cross compiler."
else
    tar xjf $D_DOWNLOAD/$COMPILER_IMAGE
fi

if [ -x $AndroidSDK ]; then
    echo "You already have Android SDK."
else
    unzip $D_DOWNLOAD/$SDK_IMAGE
fi

if [ -x $D_NDK ]; then
    echo "You already have Android NDK"
else
    tar xjf $D_DOWNLOAD/$NDK_IMAGE
fi

cd $D_CUR

##############################
# Install necessary packages #
##############################

sudo apt-get install build-essential ddd libc6:i386 libncurses5:i386 libstdc++6:i386 u-boot-tools bison flex gperf libxml2-utils curl libncurses5-dev:i386 gcc libz-dev libz-dev:i386 gcc-multilib g++-multilib wine libx11-dev

##################
# Git repository #
##################

git clone https://github.com/hogimn/build -b s4210
git clone https://github.com/hogimn/u-boot -b s4210
git clone https://github.com/hogimn/kernel -b s4210-2.6.35 --depth=1

curl https://storage.googleapis.com/git-repo-downloads/repo-1 > $D_BIN/repo
chmod a+x $D_BIN/repo

mkdir -p $D_AOSP

cd $D_AOSP
$D_BIN/repo init --depth=1 -u https://github.com/hogimn/platform_manifest -b s4210
$D_BIN/repo sync  -f --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
cd $D_CUR
