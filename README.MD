# YAZ180

There needed to be Yet Another Z180 computer created.
And so, here it is.

<a href="https://github.com/feilipu/yaz180/blob/master/docs/P1080760.JPG" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/P1080760.JPG"/></a>

The YAZ180 is a modern single board computer, based on the tradition rich Z180 CPU and the AMD Am9511A-1 APU.

It is my attempt to create a perfect mix of modern and "ancient" computing technology. Further, it is an attempt to marry CPU/APU technology from 40 years ago, with modern I2C, USB, and WiFi capabilities, and make an powerful 8-bit computer that can either be embedded, or operate stand-alone (with some accessories).

The YAZ180 is supported by the Z88dk and it is designed to work with both traditional CP/M v2.2 applications and modern Z88dk C compiled programs.

## Concept

The Z180 CPU is based on the Z80 CPU, but it includes a number of integrated peripherals including a basic Memory Management Unit (MMU), two serial interfaces (ASCI0 & ASCI1), two DMA controllers (DMAC0 & DMAC1), and two Programmable Reload Timers (PRT0 & PRT1).

The fastest readily available Flash memory is 55ns. This is matched by the fastest RAM in 8 x 1MByte packaging at 45ns. Using these two timings the fastest clock that can be therefore be supported is approximately 20MHz. Using this as a guide, and knowing that the Z180 ASCI interfaces are happiest running at a magic frequency, I have selected 18.432MHz as the basic operating frequency (or Phi) for the YAZ180.

The Z180 can operate internally at 2x the external Phi clock, which means that the YAZ180 is configured to run at 36.864MHz in normal situations. This is slightly outside the Z180 specification (33MHz), but this frequency is widely recommended even in Zilog documentation.

In addition to the internal Z180 interfaces, I have added a 82C55 Parallel Input Output (PIO) Controller. This device provides 3x 8 bit parallel ports, and enables the YAZ180 to support 16bit IDE hard drives, as well as providing a mechanism to add parallel data interfacing.

As the IDE interface requires control signals that are active low, several of the PIO Port C lines are passed through inverters. Importantly, those Port C lines that can accept input in PIO Mode 1 or Mode 2 are not inverted, and are therefore available as inputs.

A single step circuitry has been implemented, which is enabled by a switch, and triggered by writing to an I/O port address. This enables the YAZ180 to run normally, until it becomes interesting to enable a breakpoint.

To interface with modern sensors, and devices, two separate I2C interface PCA9665 devices have been provided. This enables one device to be running at 1MHz in Fast-mode Plus (or even Turbo mode) driving a LCD controller for a screen (example FTDI EVE), and have the other connected to over longer distances to sensors or keyboard running at 100kHz in Standard mode. The PCA9665 has deep 68 byte hardware buffers, and can operate in buffered or streaming mode, enabling complete I2C sentences to be transmitted or received without CPU interaction. A complete GL graphics command can be sent with one CPU DMA, for example.

To interface with TCP/IP networks, using WiFi, an ESP8266 pin-out for the ESP-01S is provided, connected to ASCI1. This enables the YAZ180 to operate as an Internet server (with attached IDE hard drive), and / or to be controlled using Secure Shell from anywhere.

A USB parallel interface is provided to enable "tool-less" programming of the YAZ180. A perl script is provided to upload Intel HEX code and program it into the system Flash memory. To enable this featured, hardware is provided to reconfigure the memory map to allow boot from USB.


## PCB

The YAZ180 PCB is 10cm x 16cm in size. The layout is based on 4 layers. This is the maximum size supported by the Eagle "Hobby Licence", which was used to create the PCB.

- Layer Top - all active devices - 2oz copper
- Layer 2 - GND layer - 0.5oz copper
- Layer 15 - VCC layer - 0.5oz copper
- Layer Bottom - signal traces - 2oz copper

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.1 PCB<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v2.1.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v2.1.png"/></a></td>
</tr>
</tbody>
</table>
</div>

The YAZ180 requires 15V to 40V DC supply. If you are not equipping the Am9511A-1 APU, then the minimum required supply voltage drops to 7V.

The main supply is switchmode 5V 3A, which is used by most of the traditional devices on the board. Note that the TIL-311 LED display devices consume approximately 105mA each, and operate HOT TO TOUCH.

A 3.3V 1A linear supply is fed from the 5V internal source. 3.3V is needed to support the I2C and ESP-01S devices.

The internal 12V 500mA switchmode supply is generated only to support the APU.
Note that the Am9511A-1 consumes 5V 70mA plus 12V 70mA normally, and operates BURNING HOT TO TOUCH (seriously).

The Z180 is supported by a signal buffer on the /RD, /RW, /MREQ, and /IORQ lines, together with the four lowest address lines, A3, A2, A1, and A0. These signals are provided to all active elements, and so even though the Z180 includes its own signal buffers, I thought these signals should be additionally buffered.

The Z180 data lines are also buffered by a bus transceiver. This is to ensure that these lines are also optimally driven.

## BOM

The <a href="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180_V21_BOM_PARTS.csv" target="_blank">Bill of Material</a> is available from DigiKey using this [Shopping Cart](http://www.digikey.com.au/short/q7nnr8).

Note that there are two significant items missing from the Cart.

- The <a href="https://github.com/feilipu/yaz180/blob/master/docs/datasheets/Am9511%20Arithmetic%20Processor.pdf" target="_blank">Am9511A-1</a> is obsolete, and is only available from second tier chip sellers.
- The <a href="https://github.com/feilipu/yaz180/blob/master/docs/datasheets/til311.pdf" target="_blank">TIL-311</a> is not obsolete, but is no longer used in modern development and so is also not generally available.

Both of these products are readily available from second tier sources, but due to their scarcity they are not inexpensive.

Some other smaller pin-outs and connectors are not included:

- 1 of 2x4 0.1 inch female for ESP-01S
- 2 of 1x4 0.1 inch male for Sparkfun I2C
- 2 of SeeedGrove I2C

## Memory & I/O Address Layout

The physical address mapping is provided by the standard CUPL (described below), and is completely arbitrary.
Any other CUPL definitions can be programmed into the GAL16V8D "Memory" device to provide any memory layout desired.

### Physical Memory Address Space

The basic layout is to allow for an initial boot from flash memory into a BANK0, with additional BANK1 through BANK12 containing 64kB RAM based application spaces. The upper 8kB of each application space will be masked by COMMON AREA 1, which provides system utilities.

The additional flash memory is assigned to the upper memory space BANK13, BANK14, and BANK15.
This non-volatile storage can be used for any purpose.

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
<th style="border: 1px solid #cccccc; padding: 6px;">$00000 - $03FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (16kB of 256kB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">USB (16kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$04000 - $0BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (32kB of 256kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$0C000 - $BFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (704kB of 1MB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (704kB of 1MB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$C0000 - $CFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (64kB of 1MB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (64kB of 256kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$D0000 - $FFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (192kB of 256kB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (192kB of 256kB)</td>
</tr>
</tbody>
</table>
</div>

### Logical Memory Address Space

There is no need to follow this mapping. This is what I prefer. You can do whatever you want.

The organisation below is an attempt to provide a BANK0 containing YABIOS (boot and Z88dk library code) and a system heap space. The COMMON AREA 1 space from 0xD000 to 0xFFFF is intended to hold banking code, system calls, interrupt service routines, system buffers, and a system stack.

Additional BANK1 through BANK12 are intended to hold user code, whether CP/M or Z88dk C programms, both are supported through system calls to BANK0.

Flash found in BANK13, BANK14, and BANK15 is intended to be used for snapshots of frequent applications. For example a CP/M snapshot would enable a "diskless" CP/M initialisation, using DMA to load within fractions of a second. Suggested initial snapshots could be: CP/M CCP/BDOS, CP/M + BASIC, & Webserver, for example.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<th style="border: 2px solid #cccccc; padding: 6px;">Logical Address Range</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Run Mode</th>
<th style="border: 2px solid #cccccc; padding: 6px;">Programming Mode</th>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$0000 - $1FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (16kB, BANK)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">USB (16kB, CA0)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$3000 - $BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (32kB, BANK)</td>
<td style="border: 1px solid #cccccc; padding: 6px;"><strong>Flash (32kB, BANK)</strong></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$C000 - $FFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (16kB, BANK / CA1)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (16kB, CA1)</td>
</tr>
</tbody>
</table>
</div>

### I/O Address Space

As a computer always needs to be extended and interact with the real world, and the YAZ180 adds modern user interfaces to the solution. Address lines A15-A13 to provide I/O selection options on the YAZ180.

Using GAL to generate the I/O address mapping also allows flexibility to latch data into the Hex Display, or trigger breakpoints using #M1 and #Wait to allow Single Step execution from any code point.

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
<td style="border: 1px solid #cccccc; padding: 6px;">DO NOT USE ($0, b000)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Internal I/O z180 INT $0000-$00FF Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$2000 - $3FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">BREAK ($1, b001)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Break Point - Initiate Single Step Mode</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$4000 - $5FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#DIO_CS ($2, b010)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">82C55 $4000-$4003 Registers</span></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$6000 - $7FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">EXPANSION ($3, b011)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Hold for Expansion</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$8000 - $9FFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#I2C_CS2 ($4, b100)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">PCA9665 #INT2 $8000-$8003 Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$A000 - $BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#I2C_CS1 ($5, b101)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">PCA9665 #INT1 $A000-$A003 Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$C000 - $DFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">#APU_CS ($6, b110)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Am9511A-1 #INT0 $C000-$C001 Registers</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$E000 - $FFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">EXPANSION ($7, b111)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Hold for Expansion</td>
</tr>
</tbody>
</table>
</div>

## CUPL

The YAZ180 is essentially software defined hardware. The use of Programmable Logic Devices (PLD) to control the board has enabled me to avoid multiple rework to repair issues, and has enabled reconfiguration of memory and I/O logic without raising a soldering iron.

### Memory GAL Configuration

<a href="https://github.com/feilipu/yaz180/blob/master/docs/MEMORY_PLD_NEW.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/MEMORY_PLD_NEW.png"/></a>

### Logic (Single Step) GAL Configuration

<a href="https://github.com/feilipu/yaz180/blob/master/docs/LOGIC_PLD.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/LOGIC_PLD.png"/></a>

The YAZ180 CUPL code is available in the [respective directory](https://github.com/feilipu/yaz180/tree/master/cupl).

## BIOS

Work in progress.

Currently the YAZ180 is initialised to load [NASCOM Basic](https://github.com/feilipu/NASCOM_BASIC_4.7/tree/master/yaz180_NascomBasic56k), and within the [Z88dk]((https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/target/yaz180)) using the ROM, and RAM models.

## Z88dk

[Z88dk support](https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/target/yaz180) has been completed, but work continues daily.

## CPM

Work in progress.
