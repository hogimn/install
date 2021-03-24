#!/bin/bash

D_CUR=$(pwd)
D_BIN=$D_CUR/bin
mkdir -p $D_BIN
D_AOSP=$D_CUR/android-4.4.4_r2
mkdir -p $D_AOSP
D_ANDROID_15=$D_CUR/android-15
D_DOWNLOAD=$D_BIN/src/download
D_TOOL=$D_BIN/arm-2013.11
D_JDK=$D_BIN/jdk1.6.0_45

CODEBENCH_EABI_IMAGE=arm-2013.11-24-arm-none-eabi-i686-pc-linux-gnu.tar.bz2
CODEBENCH_LINUX_IMAGE=arm-2013.11-33-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2

CODEBENCH_EABI_URL=https://sourceforge.net/projects/epwa/files/arm-2013.11-24-arm-none-eabi-i686-pc-linux-gnu.tar.bz2/download
CODEBENCH_LINUX_URL=https://sourceforge.net/projects/epwa/files/arm-2013.11-33-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2/download

# CODEBENCH_EABI_URL=https://sourcery.mentor.com/public/gnu_toolchain/arm-none-eabi/arm-2013.11-24-arm-none-eabi-i686-pc-linux-gnu.tar.bz2
# CODEBENCH_LINUX_URL=http://sourcery.mentor.com/public/gnu_toolchain/arm-none-linux-gnueabi/arm-2013.11-33-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2

ORACLE_JDK_IMAGE=jdk-6u45-linux-x64.bin
ORACLE_JDK_URL=http://mirror.hostway.co.kr/Java/jdk-6u45-linux-x64.bin

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
echo -n "Do you want to start the installation? [y/n]?"
read choice 
if [ "$choice" == "y" ]; then
    echo "Starting the installation"
else
    echo "Return from the installation"
    return
fi

if [ -d $D_DOWNLOAD ]; then
    echo "You already have download folder."
else
    echo "Create download folder."
    mkdir -p $D_DOWNLOAD
fi

echo "Downloading CodeBench Lite ..."
if [ -f $D_DOWNLOAD/$CODEBENCH_EABI_IMAGE ]; then
    echo $D_DOWNLOAD/$CODEBENCH_EABI_IMAGE
else
    wget -O $D_DOWNLOAD/$CODEBENCH_EABI_IMAGE $CODEBENCH_EABI_URL
fi

if [ -f $D_DOWNLOAD/$CODEBENCH_LINUX_IMAGE ]; then
    echo $D_DOWNLOAD/$CODEBENCH_LINUX_IMAGE
else
    wget -O $D_DOWNLOAD/$CODEBENCH_LINUX_IMAGE $CODEBENCH_LINUX_URL
fi

echo "Downloading Android SDK ..."
if [ -f $D_DOWNLOAD/$SDK_IMAGE ]; then
    echo $D_DOWNLOAD/$SDK_IMAGE
else
    wget -O $D_DOWNLOAD/$SDK_IMAGE $SDK_URL
fi

echo "Downloading Oracle JDK ..."
if [ -f $D_DOWNLOAD/$ORACLE_JDK_IMAGE ]; then
    echo $D_DOWNLOAD/$ORACLE_JDK_IMAGE
else
    wget -P $D_DOWNLOAD $ORACLE_JDK_URL
    chmod +x $D_DOWNLOAD/$ORACLE_JDK_IMAGE 
fi

# Install
cd $D_BIN
if [ -x $D_TOOL/arm-none-eabi ]; then
    echo "You already have $D_TOOL/arm-none-eabi."
else
    tar xvfj $D_DOWNLOAD/$CODEBENCH_EABI_IMAGE
fi

if [ -x $D_TOOL/arm-none-linux-gnueabi ]; then
    echo "You already have $D_TOOL/arm-none-linux-gnueabi."
else
    tar xvfj $D_DOWNLOAD/$CODEBENCH_LINUX_IMAGE
fi

if [ -x $AndroidSDK ]; then
    echo "You already have Android SDK."
else
    unzip $D_DOWNLOAD/$SDK_IMAGE
fi

if [ -d $D_JDK ]; then
    echo "You already have Oracle JDK."
else
    $D_DOWNLOAD/$ORACLE_JDK_IMAGE
fi

# Install android-15 to $AndroidSDK
cd $D_ANDROID_15

unzip tools_r15-linux.zip
rm -rf $AndroidSDK/tools
mv tools $AndroidSDK

unzip sysimg_armv7a-15_r02.zip
rm -rf $AndroidSDK/system-images/android-15/armeabi-v7a
mkdir -p $AndroidSDK/system-images/android-15
mv armeabi-v7a $AndroidSDK/system-images/android-15

unzip android-15_r03.zip
rm -rf $AndroidSDK/platforms/android-15
mv android-4.0.4  $AndroidSDK/platforms/android-15

cd $D_CUR

# Clone git repository
git clone https://github.com/hogimn/build -b goldfish2
git clone https://github.com/hogimn/sdk_hack
git clone https://github.com/hogimn/bo

# Download AOSP android 4.4.4_r2 source tree + goldfish2 specific
curl https://storage.googleapis.com/git-repo-downloads/repo-1 > $D_BIN/repo
chmod a+x $D_BIN/repo

echo "Starting the installation..."
cd $D_AOSP
$D_BIN/repo init --depth=1 -u https://github.com/hogimn/platform_manifest -b goldfish2
$D_BIN/repo sync  -f --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
cd $D_CUR
