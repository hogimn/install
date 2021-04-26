# Install for VirtualBox

This repository is about porting existing AOSP (7.1.2\_r39) to Virtualbox using minimum Android-x86 components. It contains install.sh script to install components of the project scattered over the other repositories and establish build environment conveniently.</br>

You can choose the final product between the two versions.</br>
1. Use the least number of Android-x86 components which are necessary to boot android on virtualbox (x86). it supports graphics but it has some strange color issue.</br>
2. On top of version 1, it supports proper graphics and audio. But it has limitation on video support</br>

Here are screenshots of these two versions

## Host Environment

Here is infomations about tested environment.

VM(Virtual Machine): VMWare Workstation Pro</br>
VM settings: Memory=8GB, CPU=4cores, Virtualize Intel VT-x/EPT or AMD-V/RVI</br>

VM OS: Ubuntu 14.04 x64</br>

## About install.sh script

You can install all the components of the project by following instruction.</br>

```
. install.sh
```

It installs following components.</br>
1. Necessary packages to build and run the project</br>
(editing...)
