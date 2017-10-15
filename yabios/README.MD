# YABIOS

There needed to be Yet Another Z180 computer created, and for that computer: <strong>Yet Another BIOS</strong>.

The YAZ180 is a modern single board computer, built on the tradition rich Z180 CPU and the AMD Am9511A-1 APU.

It is my attempt to create a perfect mix of "ancient" and  modern computing technology. Specifically, it is an attempt to marry CPU/APU technology from 40 years ago, with modern I2C, USB, and WiFi capabilities, and make an powerful 8-bit computer that can either be embedded into an application, or operate as a stand-alone computer (with some accessories).

The YAZ180 is supported by the Z88dk and it is designed to work with both traditional CP/M v2.2 applications and modern Z88dk C compiled applications.

The YABIOS supports CP/M 2.2 Page 0 compatibility, with an underlying Fat32 File System, and allows access to Z88dk libraries, with APU, FatFs, and time libraries, through the use of `RST+DEFB` or `RST+DEFW` short calls, and will include a `__far_call` capability to allow applications to grow beyond 56kB.

## Design Concept

YABIOS is designed to look substantially like CP/M BIOS to CP/M applications, but incorporating advances in design pioneered by the Cambridge Z88 OZ operating sytem to enable access to a wider range of system resources for applications prepared by the z88dk.

There are three ways to interact with YABIOS,

1. the Command Line Interface, on either of the ASCI serial interfaces,
2. the Z80 `RST` short calls established to support access to YABIOS functions, and
3. the CP/M BIOS calls integrating YABIOS with the CP/M CCP/BDOS.

The location of the `RST` short calls is defined within the YABIOS Page 0.
<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/yaz180/blob/master/docs/YABIOS%20-%20Page%200.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/YABIOS%20-%20Page%200.png"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YABIOS Page 0<center></th>
</tr>
</tbody>
</table>
</div>

As the YAZ180 has multiple BANK locations in which to run an application, one design goal is to minimise (remove) dependency on the application being loaded into a particular BANK. This will require the development of BANK relative addressing for `__far_call` and other system functionalities, if an application is to be larger than 56kB, or is to be independent of its initial BANK location.

## Development Path

As the development of YABIOS is going to take some effort and time, the work will be divided into phases, each providing measurable and useable outcomes. Each phase should provide services to the following phases, upon which that development phase will build.

Each one of these intems will need to be implemented.

### Phase 1 - z88dk application support

- [ ] [`__far_memcpy`](https://github.com/feilipu/yaz180/tree/master/yabios#__far_memcpy), [`__far_memset`](https://github.com/feilipu/yaz180/tree/master/yabios#__far_memset), [`__far_memcmp`](https://github.com/feilipu/yaz180/tree/master/yabios#__far_memcmp) functions
- [ ] [`__bank_switch`](https://github.com/feilipu/yaz180/tree/master/yabios#__bank_switch) function
- [ ] [`__load_hex`](https://github.com/feilipu/yaz180/tree/master/yabios#__load_hex), [`__load_bin`](https://github.com/feilipu/yaz180/tree/master/yabios#__load_bin) functions with support for `__far_memcpy` or similar
- [ ] YABIOS [Command Line Interface](https://github.com/feilipu/yaz180/tree/master/yabios#command-line-interface)
- [ ] YABIOS `RST+DEFW` System Call
- [ ] YABIOS `RST+DEFB` APU Call
- [ ] YABIOS `RST+DEFB` Error Handler
- [ ] I/O redirection for CP/M IOBYTE support

### Phase 2 - CP/M application support

- [ ] `conin`, `conout`, `const` calls
- [ ] link FatFS with CP/M Disk buffers
- [ ] `setdma`, `seldsk`, `settrk`, `setsec` calls
- [ ] `read`, `write`, `sectran` calls
- [ ] integrate CP/M IOBYTE support
- [ ] integrate YABIOS CLI support

### Phase 3 - Flash Snapshot support

- [ ] add flash support into `_ far_memcpy` or similar
- [ ] integrate YABIOS CLI support

### Phase 4 - RTOS multi-tasking

- [ ] port FreeRTOS within an application (single BANK)
- [ ] integrate FreeRTOS with YABIOS (Page 0 TCB*)

### Phase 5 - Multi-bank application support

- [ ] `__far_call` `RST` function
- [ ] finalise and test
- [ ] to be added

## Memory Map

The organisation below is an attempt to provide a logical memory map for YAZ180, which allows simple bank management. Yet, is flexible enough to support multi-tasking from a RTOS in the future.

BANK0 contains YABIOS (CRT0, boot code, and Z88dk library code) together with a RAM system heap. The COMMON AREA 1 space from 0xE000 to 0xFFFF is intended to hold banking code, system calls, interrupt service routines, system buffers, and a system stack.

Additional BANK1 through BANK12 are intended to hold user code, whether CP/M or Z88dk C programs, both are supported through system calls to BANK0.

Flash found in BANK13, BANK14, and BANK15 is intended to be used for snapshots of default or frequently used applications. For example a CP/M snapshot would enable a "diskless" CP/M initialisation, using DMA to load within fractions of a second. Suggested default snapshots could be: CP/M CCP/BDOS, CP/M + BASIC, or Webserver, for example

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180%20Memory%20Map.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180%20Memory%20Map.png"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YABIOS Memory Map<center></th>
</tr>
</tbody>
</table>
</div>

Further description of the memory map when programming via the USB parallel port, the physical arrangement of RAM and Flash memory, and the I/O arrangement are provided below.

### Programming Memory Map

YABIOS being developed for the YAZ180 implements the following memory map for run (normal) mode and programming mode. Programming mode is used to provide access to YAZ180 Flash memory for programming, without relying on the existance of YABIOS, or external tools.

A USB parallel interface is provided to enable "tool-less" programming of the YAZ180. A perl script is provided to upload Intel HEX code and program it into the system Flash memory. To enable this feature hardware is provided to reconfigure the memory map to allow boot from USB.

Preparation of the programming mode perl tool is work in progress.

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

### Physical Memory Address Space

The basic layout is to allow for an initial boot from flash memory into a BANK0, with additional BANK1 through BANK12 containing 64kB RAM based application spaces. The upper 8kB of each application space will be masked by COMMON AREA 1 RAM, which provides system utilities.

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

### I/O Address Space

A computer always needs to be extended and to interact with the real world, and the YAZ180 provides multiple high-speed interfaces. As the Z180 supports 16 bit I/O addressing, the address lines A15-A13 to provide I/O selection options on the YAZ180.

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
<td style="border: 1px solid #cccccc; padding: 6px;">-</td>
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
<td style="border: 1px solid #cccccc; padding: 6px;">-</td>
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
<td style="border: 1px solid #cccccc; padding: 6px;">-</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Hold for Expansion</td>
</tr>
</tbody>
</table>
</div>

## Function Definitions

### `__far_memcpy`

### `__far_memset`

### `__far_memcmp`

### __bank_switch`

### `__load_hex`

### `__load_bin`

### `RST20+DEFW` System Call

### `RST18+DEFB` APU Call

### `RST10+DEFW+DEFB` `__far_call`

### `RST8+DEFB` Error Handler


### Command Line Interface

