# nxtOSEK

Installation instructions for [nxtOSEK](http://lejos-osek.sourceforge.net) version 2.18 in Ubuntu 14.04 LTS.

This tutorial is based on the one found at http://lejos-osek.sourceforge.net/installation_linux.htm

## Clone nxtOSEK repository

```
~$ git clone https://github.com/gmsanchez/nxtOSEK.git
~$ cd nxtOSEK
```


## Build and Install GNU ARM

[GNU ARM](http://www.gnuarm.com/) is a distribution of GCC (GNU Compiler Collection) for ARM core and it supports the ARM7 CPU inside the NXT. 

The complete process should take at least half an hour and finish with the message "Build complete !".

Install the required libraries by running the following command

`~/nxtOSEK$ sudo apt-get install build-essential texinfo libgmp-dev libmpfr-dev libppl-dev libcloog-ppl-dev`

Run the provided script.

`~/nxtOSEK$ sh ./build_arm_toolchain.sh`

Test the new gcc : this should be the output of `arm-elf-gcc -print-multi-lib` (hard and soft float support)

```
~/nxtOSEK$ ./gnuarm/bin/arm-elf-gcc -print-multi-lib
.;
thumb;@mthumb
fpu;@mhard-float
interwork;@mthumb-interwork
fpu/interwork;@mhard-float@mthumb-interwork
thumb/interwork;@mthumb@mthumb-interwork
```

## Set up nxtOSEK

We need to install `wine`, to execute `toppers_osek/sg/sg.exe` (parser of the .oil files) and `p7zip-full` to uncompress the lhz file.

`~/nxtOSEK$ sudo apt-get install wine p7zip-full`

Run the provided script

`~/nxtOSEK$ sh ./install_nxtosek.sh`
