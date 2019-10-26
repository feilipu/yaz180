# YAZ180

There needed to be <strong>Yet Another Z180</strong> computer created.<br>
And so, here it is.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/YAZ180v24_left.JPG" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/YAZ180v24_left.JPG"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.4 2019 Left<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/YAZ180v24_right.JPG" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/YAZ180v24_right.JPG"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.4 2019 Right<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/P1090697.JPG" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/P1090697.JPG"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.1 2017 Live with YABIOS and CP/M<center></th>
</tr>
</tbody>
</table>
</div>


The [YAZ180](https://feilipu.me/?s=yaz180) is a modern single board computer, built on the tradition rich Z180 CPU and the AMD Am9511A-1 APU.

It is my attempt to create a perfect mix of "ancient" and  modern computing technology. Specifically, it is an attempt to marry CPU/APU technology from 40 years ago, with modern I2C, USB, and WiFi capabilities, and make an powerful 8-bit computer that can either be embedded into an application, or operate as a stand-alone computer (with some accessories).

The YAZ180 is supported by the z88dk and it is designed to work with both traditional CP/M v2.2 applications and modern z88dk C compiled programs.

The YAZ180 is fully open source. All documentation and design is available from this repository. I have made the raw PCBs available on [Tindie](https://www.tindie.com/products/feilipu/yaz180-pcb-modern-single-board-z180-computer/). Hand assembled, tested, and finished [YAZ180 single board computers are available on Tindie](https://www.tindie.com/products/feilipu/yaz180-modern-single-board-z80-computer/) now.

## Concept

The Z180 CPU is based on the Z80 CPU, but it includes a number of integrated peripherals including a basic Memory Management Unit (MMU), two serial interfaces (ASCI0 & ASCI1), two DMA controllers (DMAC0 & DMAC1), and two Programmable Reload Timers (PRT0 & PRT1).

The fastest readily available Flash memory is 55ns. This is matched by the fastest RAM in 8 x 1MByte packaging at 45ns. Using these two timings the fastest clock that can be therefore be supported is approximately 20MHz. Using this as a guide, and knowing that the Z180 ASCI interfaces are happiest running at a magic frequency, I have therefore selected 18.432MHz as the crystal oscillator frequency for the YAZ180.

The Z180 can operate internally at 2x the crystal oscillator frequency, which means that the YAZ180 is configured to run with PHI at 36.864MHz with 1 wait memory wait state in normal situations. This is slightly outside the Z180 specification (33MHz), but this frequency is reported to work without issues by a number of SBC builds.

The AMD Am9511A (1977) was the first hardware arithmetic Floating Point Unit (FPU) developed. It is essentially a "scientific calculator" on a chip, and is capable of both 16 bit and 32 bit fixed and 32 bit floating point processing, across all the standard and trancendental functions. Even though this device is 40 years old, it is still [comparable in performance](https://feilipu.me/2017/02/22/characterising-am9511a-1-apu/) of mathematical calculations to its Z180 host.

In addition to the internal Z180 interfaces, I have added a 82C55 Programmable Peripheral Interface (PPI) Controller (1974). This device provides 3x 8 bit parallel ports, and enables the YAZ180 to support 16bit IDE hard drives, as well as providing a mechanism to add parallel data interfacing to future expansion boards.

As the IDE interface requires control signals that are active low, several of the PPI Port C lines are passed through inverters. Importantly, those Port C lines that can accept input in PPI Mode 1 or Mode 2 are not inverted, and are therefore available as inputs from off-board applications. The IDE physical interface cable also provides a tidy board extension format, to allow extension or accessory devices to be attached to the YAZ180.

A single step circuitry has been implemented, which is enabled by a switch, and triggered by writing to an I/O port address. This enables the YAZ180 to run normally, until it becomes interesting to enable a breakpoint.

To interface with modern sensors and devices, two separate I2C interface PCA9665 devices have been provided. This enables one I2C device to be running at 800kHz in Fast-mode Plus (or even Plaid at 1MHz) driving a LCD controller for a screen (for example FTDI EVE), and have the other I2C interface connected over longer distances to sensors or keyboard running at 100kHz in Standard mode. The PCA9665 has deep 68 byte hardware buffers, and can operate in buffered or streaming mode, enabling complete I2C sentences to be transmitted or received without CPU interaction. A complete GLX graphics command can be sent with one CPU interrupt transaction, for example.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://www.youtube.com/embed/6-p7kZrgalg" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/conway_life.png"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 I2C#2 Conway's Life & I2C#1 Temperature / Humidity Sensing - CLICK FOR VIDEO<center></th>
</tr>
</tbody>
</table>
</div>

To interface with TCP/IP networks, using WiFi, an ESP8266 pin-out for the ESP-01S is provided, connected to ASCI1. This enables the YAZ180 to operate as an Internet server (with attached IDE hard drive), and / or to be controlled using Secure Shell from anywhere.

A USB parallel interface is provided to enable "tool-less" programming of the YAZ180. A perl script is provided to upload Intel HEX code and program it into the system Flash memory. To enable this feature hardware is provided to reconfigure the memory map to allow boot from USB.

## PCB

The YAZ180 PCB is 160mm x 100mm in size, with 4 layers.<br>
This is the maximum size supported by the Eagle "Hobby Licence", which was used to create the PCB.

- Layer Top - all active devices (RED) - 2oz copper
- Layer 2 - GND layer (flood fill) - 0.5oz copper
- Layer 15 - VCC layer (flood fill) - 0.5oz copper
- Layer Bottom - signal traces (BLUE) - 2oz copper

- PCB Dimension - 160mm*100mm
- Material - FR-4 TG130
- Surface Finish - ENIG
- Min Solder Mask Dam - 0.4mm
- PCB Color - Black

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/YAZ180v2.4.png" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/YAZ180v2.4.png"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.4 PCB 2019 Layout<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v21_pcb.JPG" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v21_pcb.JPG"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.1 PCB 2017<center></th>
</tr>
</tbody>
</table>
</div>

<a href="https://www.tindie.com/stores/feilipu/?ref=offsite_badges&utm_source=sellers_feilipu&utm_medium=badges&utm_campaign=badge_large"><img src="https://d2ss6ovg47m0r5.cloudfront.net/badges/tindie-larges.png" alt="I sell on Tindie" width="200" height="104"/></a>

The YAZ180 requires 15V to 40V, 2A power supply, through a standard 2.1mm barrel jack.<br>
If you are not equipping the Am9511A-1 APU, then the minimum required supply voltage drops to 7V.

The main supply is switchmode rated at 5V 3A, which is used by most of the traditional devices on the board. Note that the <strong>TIL-311</strong> LED display devices consume approximately 105mA each, and operate <strong>HOT TO TOUCH</strong>.

A 3.3V 1A rated linear supply is fed from the 5V internal source. 3.3V is needed to support the I2C and ESP-01S devices.

The internal 12V 500mA rated switchmode supply is generated only to support the APU. Note that the <strong>Am9511A-1</strong> consumes 5V 70mA plus 12V 70mA normally, and operates <strong>BURNING HOT TO TOUCH</strong> (seriously).

The Z180 is supported by an ABT logic signal buffer on the /RD, /WR, /MREQ, and /IORQ lines, together with the four lowest address lines, A3, A2, A1, and A0. These signals are provided to all active elements, and so even though the Z180 includes its own signal buffers, I thought these signals should be additionally buffered.

The Z180 data lines are also buffered by an ABT logic bus transceiver. This is to ensure that these lines are also optimally driven.

## BOM

The <a href="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180_V23_ListByValues.csv" target="_blank">Bill of Material</a> is available from DigiKey by modifying this [Shopping Cart](https://www.digikey.com.au/short/j103pz).

Note that there are two significant items missing from the Shopping Cart.

- The <a href="https://github.com/feilipu/yaz180/blob/master/docs/datasheets/Am9511%20Arithmetic%20Processor.pdf" target="_blank">Am9511A-1</a> is obsolete, and is only available from second tier chip sellers.
- The <a href="https://github.com/feilipu/yaz180/blob/master/docs/datasheets/til311.pdf" target="_blank">TIL-311</a> is not obsolete, but is no longer used in modern development and so is also not generally available.

Both of these products are readily available from second tier sources, but due to their scarcity they are not inexpensive.

Some other smaller pin-outs and connectors are not included:

- 2 of Seeed Studio Grove I2C connectors

## Memory & I/O Address Layout

The physical address mapping is provided by the standard CUPL (described below), and is completely arbitrary. Any other CUPL definitions can be programmed into the GAL16V8D "Memory" device to provide any memory layout desired.

### Physical Memory Address Space

The basic layout is to allow for an initial boot from flash memory into a BANK_0, with additional BANK_1 through BANK14 containing 64kB RAM based application spaces. The upper 4kB of each application space will be masked by COMMON AREA 1 RAM, which provides system utilities.

The additional flash memory is assigned to the upper memory space (BANK13, BANK14, and) BANK15, depending on the size of flash storage equipped. This non-volatile storage can be used for any purpose.

The PROGRAMMING MODE hardware recognises that data is available on the USB parallel port, and reconfigures the physical address mapping to enable boot from USB, and further programming of Flash or RAM.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<th style="border: 2px solid #cccccc; padding: 6px;">Physical Address Range</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Run Mode</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Programming Mode</th>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$00000 -> $0BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (48kB of 256kB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">USB pseudo RAM (48kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$0C000 -> $BFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (736kB of 1MB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (736kB of 1MB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$C0000 -> $CFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (64kB of 1MB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (64kB of 256kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$D0000 -> $FFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (192kB of 256kB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (192kB of 256kB)</td>
</tr>
</tbody>
</table>
</div>

### Logical Memory Address Space

There is no need to follow this logical address space mapping. This is what I prefer. You can do whatever you want.

The organisation below is an attempt to provide a BANK_0 containing YABIOS (CRT0, boot code, and z88dk library code) together with a RAM system heap. The COMMON AREA 1 space from 0xF000 to 0xFFFF is intended to hold banking code, system call forwarding, interrupt service routines, system buffers, and a system stack.

Additional BANK_1 through BANK14 are intended to hold user code, whether CP/M or z88dk C programs, both are supported through system calls to BANK_0.

Flash found in (BANK13, BANK14, and) BANK15 is intended to be used for snapshots of default or frequently used applications. For example a CP/M snapshot would enable a "diskless" CP/M initialisation, using DMA to load within fractions of a second. Suggested default snapshots could be: CP/M CCP/BDOS, CP/M + BASIC, or Webserver, for example.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<th style="border: 2px solid #cccccc; padding: 6px;">Logical Address Range</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Run Mode</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Programming Mode</th>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$0000 - $BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (48kB, BANK_0)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">USB (48kB, CA0)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$C000 - $EFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (12kB, BANK_0)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (8kB, BANK)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$F000 - $FFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (4kB, CA1)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (8kB, CA1)</td>
</tr>
</tbody>
</table>
</div>

### I/O Address Space

A computer always needs to be extended and to interact with the real world, and the YAZ180 provides multiple high-speed interfaces. As the Z180 supports 16 bit I/O addressing, the address lines A15-A13 to provide I/O selection options on the YAZ180.

Using a PLD to generate the I/O address mapping also allows flexibility to latch data into the Hex Display, or trigger breakpoints using Z180 #M1 and #Wait signals to allow Single Step execution from any code point.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<th style="border: 2px solid #cccccc; padding: 6px;">I/O Address Range</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Chip Select (A15,A14,A13)</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Device</th>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$0000 - $1FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">DO NOT USE</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Internal I/O z180 #INTn $0000-$00FF Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$2000 - $3FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">BREAK</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Break Point - Initiate Single Step Mode</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$4000 - $5FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#DIO_CS</td>
<td style="border: 1px solid #cccccc; padding: 6px;">82C55 $4000-$4003 Registers</span></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$6000 - $7FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">EXPANSION</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Hold for Expansion</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$8000 - $9FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#I2C_CS2</td>
<td style="border: 1px solid #cccccc; padding: 6px;">PCA9665 #INT2 $8000-$8003 Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$A000 - $BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#I2C_CS1</td>
<td style="border: 1px solid #cccccc; padding: 6px;">PCA9665 #INT1 $A000-$A003 Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$C000 - $DFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#APU_CS</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Am9511A-1 #INT0 $C000-$C001 Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$E000 - $FFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">EXPANSION</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Hold for Expansion</td>
</tr>
</tbody>
</table>
</div>

## CUPL

The YAZ180 is essentially software defined hardware. The use of Programmable Logic Devices (PLD) to control the board has enabled me to avoid multiple rework to repair issues, and has enabled reconfiguration of memory and I/O logic without raising a soldering iron.

### Memory GAL Configuration

<a href="https://github.com/feilipu/yaz180/blob/master/docs/MEMORY_PLD_2018.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/MEMORY_PLD_2018.png"/></a>

### Logic (Single Step) GAL Configuration

<a href="https://github.com/feilipu/yaz180/blob/master/docs/LOGIC_PLD.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/LOGIC_PLD.png"/></a>

The YAZ180 CUPL code is available in the [respective directory](https://github.com/feilipu/yaz180/tree/master/cupl).

## YABIOS

Please see here for the status of [YABIOS](https://github.com/feilipu/yaz180/tree/master/yabios).

Currently the YAZ180 is initialised to load preferably [YABIOS v1.4](https://github.com/feilipu/yaz180/tree/master/yabios) or alternatively [NASCOM Basic](https://github.com/feilipu/NASCOM_BASIC_4.7/tree/master/yaz180_NascomBasic56k). Applications can be built the [z88dk]((https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/target/yaz180)) using the ROM (raw metal), APP (yabios I/O), and CP/M (BDOS I/O) models.

The YABIOS supports CP/M 2.2 Page 0 compatibility, with an underlying FAT32 File System, and has been extended to allow access to z88dk libraries, and APU and floating point libraries, through the use of `RST+DEFW` short calls, and it includes both `_call_far` and `_jump_far` capability to allow applications to grow beyond 60kB. There is support for 16 MByte CP/M drives as FAT32 files on a Compact Flash or PATA IDE drive up to 128 Gbyte (LBA 28).

## z88dk

[z88dk support](https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/target/yaz180) has been completed, and improvement work continues daily.

## CP/M

CP/M is complete with console and teletype I/O, and the underlying disk sub-system working. Integration of CP/M disks as FAT32 files has also been completed. CP/M can be booted off the Flash snapshot and can load transient programs from FAT32 files (read as CP/M drives).

CP/M drive files can be read and written using a host PC with any operating system, by using the [`cpmtools`](http://www.moria.de/~michael/cpmtools/) utilities, simply by inserting the IDE drive in a USB drive caddy.

## Construction Notes

There are some [construction notes](https://github.com/feilipu/yaz180/tree/master/construction_notes.md) with errata, to advice on how to build the YAZ180.

## Owners Notes

There are some [owners notes](https://github.com/feilipu/yaz180/tree/master/owners_notes.md) advice on how to operate the YAZ180, and its environment.

## Release Notes

The [release notes](https://github.com/feilipu/yaz180/tree/master/release/readme.md) for each major release cover any issues in software relating to the release.
