# nxtOSEK

Installation instructions for nxtOSEK version 2.18 in Ubuntu 14.04 LTS.

This tutorial is based on the one found at http://lejos-osek.sourceforge.net/installation_linux.htm

## Build and Install GNU ARM

[GNU ARM](http://www.gnuarm.com/) is a distribution of GCC (GNU Compiler Collection) for ARM core and it supports the ARM7 CPU inside the NXT. 

The complete process should take at least half an hour and finish with the message "Build complete !".

Install the required libraries by running the following command

`~$ sudo apt-get install build-essential texinfo libgmp-dev libmpfr-dev libppl-dev libcloog-ppl-dev`

Run the provided script.

`~$ sh ./build_arm_toolchain.sh`

Test the new gcc : this should be the output of `arm-elf-gcc -print-multi-lib` (hard and soft float support)

```
~$ ./gnuarm/bin/arm-elf-gcc -print-multi-lib
.;
thumb;@mthumb
fpu;@mhard-float
interwork;@mthumb-interwork
fpu/interwork;@mhard-float@mthumb-interwork
thumb/interwork;@mthumb@mthumb-interwork
```

nxtOSEK can be found at http://lejos-osek.sourceforge.net
