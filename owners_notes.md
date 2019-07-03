# Owners Notes

These are a few notes for owners of a YAZ180, which should help to make using the board for fun and profit easier.

Please also read the [implementation notes](https://github.com/feilipu/yaz180/blob/master/yabios/implementation_notes.md), and the [construction notes](https://github.com/feilipu/yaz180/blob/master/construction_notes.md). The information in both these documents won't be repeated here.

Note that the YAZ180 is a very capable and multifaceted tool. I've not stretched any of its capabilities, and therefore you might find stuff (bugs) that I've never seen.

I've tested the `_call_far` and `_jp_far` functions, but I haven't written large programs requiring multi-bank support. 

I've written I2C drivers now 3 times (and deleted the last two attempts), and I know the drivers in the z88dk are never going to work (they were 1st iteration). Trying to use the I2C hardware buffers, in an interrupt driven memory banked environment is hard IMHO, and I've still not achieved the result I want.

You're probably the first one to try what you're trying to do. But, don't stress.

Read the source code. At least the code in this repository. The important stuff to know is all maintained here. Libraries in z88dk and in my z88dk-libraries are relevant, but they deliver standardised outcomes for libc and for file management, and the won't tell you much about how this environment is configured.

## Power Bricks

The first thing needed is a power supply capable of supplying the current needs of all of the blinking lights. And, being able to supply current at above 12V to support the Am9511A APU.

Because a switch mode power supply is being used, with a substantial input voltage tolerance, anything up to (say) 24V 2A would work. On my desk, I have a 15V 2A supply, which performs perfectly.

40V is the ultimate maximum input voltage. Magic smoke territory. Please don't use this.

If you're not planning to use the APU, then it is probably best to unplug it and leave it aside. It will just sit generating heat, and that's pretty pointless. If you aren't using the APU, then the power supply is adequate supplying 7V to 9V 2A.

Use a 12V to 15V supply, simply because that covers all of the bases. 2A is more than enough.
Providing a lower source voltage is less wasteful and the PCB power supplies run cooler.

## USB Cables and Connections

I selected male A type sockets for the USB because the plug is quite robust, and doesn't mind a few insertion cycles.

The FTDI chips are powered by the USB side, but their IO on the digital side is powered by the board. This means that during a power cycle it should be possible to leave the USB cable plugged, and not re-enumerate the USB interface. But, this doesn't always work. Often the host computer will move the USB interface to new device on power cycle, which means that the serial terminal will loose connection with the YAZ180 if it is not re-plugged.

The ASCI-0 with the FTDI-232 Serial interface is set up for 115,200 baud 8n1.

## RESET and SINGLE-STEP

After putting a lot of circuitry on the PCB to support SINGLE-STEP, in reality it is not very useful now that tools such as ZSID or DDT work effectively. Still, it is nice to have. Leave the switch set to RUN, and forget it.

The RESET button is your friend. Don't be afraid to use it, often. As there is very little state maintained, nothing is lost by doing a RESET.

You will need to RESET

* on power on, to flush and reset the serial interfaces.
* something crashed in CP/M.
* sometimes, just because.

## Random stuff happening

There are two causes of random stuff happening. The first is the Flash chip has lost seating. The second is the IDE or CF drive needs to be power cycled.

Sometimes I find random things happening, and it is always cured by pressing down on the Flash chip, or sometimes simply extracting it and reseating.

When using CP/M sometimes the IDE or CF drive will get itself into an unusual state, that can't be recovered by a hard reset on the PATA interface (generated when the YAZ180 is RESET). If that happens, then a power cycle is the only option.

## Am9511A-1 APU

Obviously, the Am9511A APU is a very old device, and it has been quite difficult to get it to work with the more modern Z8S180 CPU. That said, once it has been initialised correctly, it is very reliable.

Sometimes the devices doesn't initialise itself properly, and then the only thing remaining to do is to power cycle the board. Resetting often doesn't work. But, try if you like.

The Am9511A-1 runs very very hot. I cannot leave my finger on the surface of the device after it has been operating for 10 minutes or so. Yet, this is normal. The current consumption is within the normal range. And the devices I used have been operating now for two years now without one failing.

You will note that in order to write to the Am9511A-1 the CPU has to slow down 4x from 36MHz to 9.2MHz, although during normal operation of the Am9511A-1 the 74LS93 divider produces a 2.3MHz signal from the normal speed CPU PHI signal. Unfortunately, the Am9511A-1 requires 30ns of data hold following release of the `/WR` signal, and this can only be generated by combining the `/WR` and `ECLK` signals (shortening the apparent `/WR` for the APU), and slowing down the CPU clock. Running the CPU at 18.432MHz produces 27ns of hold time, and unfortunately this is simply not sufficient so the the next step is to slow down to 9.2MHz during write to the APU.

Reading from the APU is not affected by this issue, so it is done at full CPU speed.

Note that in some situations the Am9511A-1 also requires that 2x Memory Wait states (and 3x I/O Wait states) be set, although it is not being accessed by memory operations. I'm still not clear why this is the case.

## ESP-01S Interface

The ASCI-1 is connected to a port into which a ESP-01S can be inserted. Whilst any program can be run on the ESP-01S, the most useful from my point of view is the [JeeLabs esp-link](https://github.com/jeelabs/esp-link/releases/tag/V3.0.14).

The ASCI-1 is set up with 9600 baud 8n2, with NO remote echo as it typical for teletype interfaces. It is done this way to support Kermit on HP-48S/G calculators. Just an interest I have.

Using the ESP-01S, it is possible to reach your YAZ180 via the Internet.

# YABIOS

The YABIOS has been set up as a working tool. It isn't consise in its language or its commands. So, for example, there are three steps to getting a program running.

* Load the program using either `loadh 3` via the currently active serial port, or load a previously saved program (if you've got an IDE or CF drive attached) using `loadb path 3`.
* Save the program to your drive (if you want to) using `saveb 3 path`.
* Establish the program bank as active, and fill the page 0 information with `mkb 3` (where we have decided to use Bank 3 for our program).
* Initiate the program by using the `initb 3`, whereby execution begins in Bank 3 at `0x0100`.

Before any IDE or CF drive information can be obtained, the drive needs either to be mounted with `mount 1`, or its directory read with `ls` which will auto mount the drive.

The workflow that I use is to build new programs, which will be run as a native YABIOS `app`, on the host PC and then download or `cat` the HEX file to the YAZ180 using the YABIOS `loadh` function. This is extremely fast, and makes use of more convenient tools on the host PC.

It is also possible to store binary files, with any origin (default at `0x0100`) directly into a file in the IDE or CF drive on the PC, and then use `loadb` to load them into the correct place on YAZ180, and `initb` to start execution at the right address. I'd call this advanced usage. I can't remember actually doing this.

Often used binary files can be stored in flash. For example in the Release 1.2, two versions of the Mandelbrot program are stored in Pages 13 (using Z180 `mul` routines), and Page 14 (using Am9511A-1 APU). Normal binaries can be accessed with the command sequence `mvb 13 3`, `mkb 3`, and `initb 3`, for example.

## CP/M Functions

There are two CP/M functions. The `mkcpmd` function builds a properly extended CP/M drive file on the IDE or CF drive attached to YAZ180. This is necessary because the CPM tools do not build the fully extended 16777216 Byte files required. But, if you have a file you can use as a template already then this comand is pretty useless (obsolete). Just do a file copy, and then within CP/M delete the contents of the drive.

The `mkcpmb` command will be used all the time. This combines both the `mkb` and `loadb` actions, and will load the contents of the flash in Bank 15 into the Bank you choose, and will prepare the bank with the LBA of each of up to 4 drive files. Then a `initb` command is required to kick off CP/M.

To exit CP/M an additional CCP function called `EXIT` has been added. This will return to YABIOS and allow CP/M to be restarted with different drive files.

More to CP/M later

## Bank Functions

All work as intended, but `lsb` or list bank has not been implemented. I found that since I've not implemented a RTOS yet, there was little point to this function at this stage.

The `loadh` function should respect Type 2 ESA configuration. This means that an ESA command will change banks to the required Bank, and will begin loading HEX from that location. The Type 2 Extended Segment Address (ESA), is equivalent to BBR data, and translates 1:1. Therefore Bank changes can be done by inputting the correct ESA data as 0xn000.

## File System Functions

The `mkfs` function has been excluded from the build, as it took too much space, and it wasn't sensible to format the sole drive on the YAZ180. Do this on a host PC.

## Disk Functions

The `dd` function reads decimal LBAs, so where a file is used as input to the `mkcpmb` command and the LBA is found and output. This LBA can then be used to dump the contents of the CP/M drive file, for interest.

## Time functions

The `clock` reads real time and keeps pretty good time at that at about 20ppm. The only thing that will upset the clock is using the APU which slows down the clock to 1/4 speed for milli-seconds. Probably you won't notice this.

The default `tz` is Melbourne Australia. There isn't an easy non-volatile way to make the default change permanently, unless a new firmware version is burnt.

# z88dk

The z88dk is my development system of choice. There is much information about how to configure it around, and there's an [entry on my blog](https://feilipu.me/2016/09/16/z80-c-code-development-with-eclipse-and-z88dk/) on using it as a last resort. Note, I've never gotten to getting the Eclipse environment working. Never really needed it.

## YAZ180

For the YAZ180 the command line of choice is
```bash
zcc +yaz180 -subtype=app -SO3 -m --max-allocs-per-node400000 test.c -o test -create-app
```
The YAZ180 has three main options,being `app`, `rom`, and `cpm` subtypes.

The `rom` subtype is only useful where you are compiling a YABIOS, or you wish to run your YAZ180 without the yabios from the metal. In this situation all the drivers available for the YAZ180 are maintained within the z88dk, and (with the exception of I2C) everything should work.

The `app` subtype is the go to for native applications. Everything you're running directly on YABIOS should be compiled with this subtype.

Within the CP/M environment, then the `cpm` subtype should be selected. Alternatively the z88dk `cpm` target can be selected, although this doesn't allow access to YAZ180 specific libraries and header files, nor does it use the Z180 specific functions, such as `mlt nn` to accelerate array access and integer arithmetic.

Details of each build type for the YAZ180 can be found within the configuration files of the z88dk. For the beginning user, the defaults are quite acceptable.

Breaking down the above command line

* `+yaz180` - is the platform type
* `-subtype=app` - is the subtype for the platform, here build for application (with YABIOS)
* `-v` - verbose `-nv` is silent
* `-m` - build a map file, needed for `-create-app`
* `-SO3` - stongly optimise using the aggressive peephole optimiser
* `--list` - generate list files
* `--max-allocs-per-node` - depth of sdcc code optimisation, reduce for faster compilation
* `-create-app` - generate finalised HEX code, also a BIN file which can be used directly.

## CP/M

To use z88dk to compile for CP/M for the Z180 processor, then the following commands can be used

```bash
zcc +yaz180 -subtype=cpm -SO3 -m --list -test.c -o test
appmake +glue --ihex --clean -b test -c test
```
Breaking this down

* `+yaz180` - is the platform type
* `-subtype=cpm` - is the subtype for the platform, here build for CP/M
* `appmake` - builds the final HEX output
* `+glue` - binds binary objects into a specific output
* `--clean` - removes byproducts of the build process

Using the `cpm` subtype from the YAZ180 target supports the Z180 specific instructions more completely, and avoid the potential inclusion of Z80 undocumented instructions.

Note that the alternative method of obtaining CP/M builds by using the CP/M target and `default` subtype doesn't provide access to YAZ180 specific hardware or capabilities, but that is not really a problem, as CP/M provides access to all the serial hardware via BDOS calls anyway.


