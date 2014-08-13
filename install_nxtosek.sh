#!/bin/bash

# Download the required files
sudo apt-get install wine
wget -c http://downloads.sourceforge.net/project/lejos-osek/nxtOSEK/nxtOSEK_v218.zip
wget -c http://www.toppers.jp/download.cgi/atk1-1.0.lzh

# Uncompress them
unzip nxtOSEK_v218.zip
7z x atk1-1.0.lzh
# Move sg.exe to nxtOSEK required location
mv ./toppers_atk1/sg/sg.exe ./nxtOSEK/toppers_osek/sg/
# We don't need toppers_atk1 folder
rm -rf ./toppers_atk1

# Replace existing mak files with fixed ones
cp ecrobot.mak ./nxtOSEK/ecrobot/
cp ecrobot++.mak ./nxtOSEK/ecrobot/
cp tool_gcc.mak ./nxtOSEK/ecrobot/

# Move nxtOSEK to working directory, uncomment of modify if necessary
mv nxtOSEK ../
