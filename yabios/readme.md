# YABIOS

There needed to be Yet Another Z180 computer created, and for that computer: <strong>Yet Another BIOS</strong>.

The YAZ180 is a modern single board computer, built on the tradition rich Z180 CPU and the AMD Am9511A-1 APU.

It is my attempt to create a perfect mix of "ancient" and  modern computing technology. Specifically, it is an attempt to marry CPU/APU technology from 40 years ago, with modern I2C, USB, and WiFi capabilities, and make an powerful 8-bit computer that can either be embedded into an application, or operate as a stand-alone computer (with some accessories).

The YAZ180 is supported by the Z88dk and it is designed to work with both traditional CP/M v2.2 applications and modern Z88dk C compiled applications.

The YABIOS supports CP/M 2.2 Page 0 compatibility, with an underlying Fat32 File System, and allows access to Z88dk libraries, with APU, FatFs, and time libraries, through the use of `RST+DEFB` or `RST+DEFW` short calls, and will include a `_call_far` capability to allow applications to grow beyond 60kB.

## Design Concept

YABIOS is designed to look substantially like CP/M BIOS to CP/M applications, but incorporating advances in design pioneered by the Cambridge Z88 OZ operating sytem to enable access to a wider range of system resources for applications prepared by the Z88dk.

There are three ways to interact with YABIOS,

1. the Command Line Interface, on either of the ASCI serial interfaces,
2. the Z80 `RST` short calls established to support access to YABIOS system functions, and
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

As the YAZ180 has multiple BANK locations in which to run an application, one design goal is to minimise (remove) dependency on the application being loaded into a particular BANK. This will require the development of BANK relative addressing for `_call_far` and other system functionalities, if an application is to be larger than 60kB, or is to be independent of its initial BANK location.

## Development Path

As the development of YABIOS is going to take some effort and time, the work will be divided into phases, each providing measurable and useable outcomes. Each phase should provide services to the following phases, upon which that development phase will build.

Each one of these items will need to be implemented.

### Phase 1 - Z88dk application support

- [x] [`_memcpy_far`](https://github.com/feilipu/yaz180/tree/master/yabios#_memcpy_far)function
- [x] [`_load_hex`](https://github.com/feilipu/yaz180/tree/master/yabios#_load_hex)
- [x] [`_load_bin`](https://github.com/feilipu/yaz180/tree/master/yabios#_load_bin) functions
- [x] [Command Line Interface](https://github.com/feilipu/yaz180/tree/master/yabios#command-line-interface)
- [x] [`RST+DEFW` System Call](https://github.com/feilipu/yaz180/tree/master/yabios#rst20defw-system-call)
- [x] [`RST+DEFB` APU Call](https://github.com/feilipu/yaz180/tree/master/yabios#rst28defb-apu-call) convert existing code to pass values, rather than pointers
- [x] [`RST+DEFB` Error Handler](https://github.com/feilipu/yaz180/tree/master/yabios#rst8defb-error-handler)
- [x] Integrate existing FatFs code for IDE interface on 82C55.
- [x] I/O redirection for CP/M IOBYTE support

Note: `_memset_far` was deleted as there was insufficient space in CA1 memory.

### Phase 2 - CP/M application support

- [x] `conin`, `conout`, `const` calls
- [x] link FatFS with CP/M Disk buffers
- [x] `setdma`, `seldsk`, `settrk`, `setsec` calls
- [x] `read`, `write`, `sectran` calls
- [x] integrate CP/M IOBYTE support
- [x] integrate CLI support

### Phase 3 - Flash Snapshot support

- [x] add flash read support into `_ memcpy_far`.
- [ ] add flash write support into `_ memcpy_far` (very hard, DMAC won't do it).
- [x] support CP/M to warm boot from flash
- [x] integrate CLI support

### Phase 4 - RTOS multi-tasking

- [x] port FreeRTOS within an application (single BANK) see [z88dk-libs/freertos](https://github.com/feilipu/z88dk-libraries/tree/master/freertos).
- [ ] integrate FreeRTOS with YABIOS (Page 0 `TCB*`)

### Phase 5 - Multi-bank application support

- [x] [`RST+DEFW+DEFB` `_call_far`](https://github.com/feilipu/yaz180/tree/master/yabios#rst10defwdefb-_call_far)
- [x] [`RST` `_jp_far`](https://github.com/feilipu/yaz180/tree/master/yabios#rst18-_jp_far)
- [x] finalise and test

## Memory Map

The organisation below is an attempt to provide a logical memory map for YAZ180, which allows simple bank management. Yet, is flexible enough to support multi-tasking from a RTOS in the future.

`BANK_0` contains YABIOS (CRT0, boot code, and Z88dk library code) together with a RAM system heap. The COMMON AREA 1 space from 0xF000 to 0xFFFF is intended to hold banking code, system call forwarding, interrupt service routines, system buffers, and a system stack.

Additional `BANK_1` through `BANK14` are intended to hold user code, whether CP/M or Z88dk C programs, both are supported through system calls to `BANK_0`.

Flash found in (`BANK13`, `BANK14`, and) `BANK15` is intended to be used for snapshots of default or frequently used applications. For example storing a CP/M snapshot enables a "diskless" CP/M initialisation, using DMA, to load within fractions of a second. Suggested default snapshots could be: CP/M CCP/BDOS, CP/M + BASIC, or Webserver, for example.

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

### Physical Memory Address Space

The basic layout is to allow for an initial boot from flash memory into a system `BANK_0`, with additional `BANK_1` through `BANK12` containing 64kB RAM based application spaces. The upper 4kB of each application space will be masked by `COMMON AREA 1` RAM, which provides system utilities.

The additional flash memory is assigned to the upper memory space (`BANK13`, `BANK14`, and) `BANK15`. This non-volatile storage can be used for any purpose.

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
<th style="border: 1px solid #cccccc; padding: 6px;">$00000 - $0BFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (48kB of 128kB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">USB pseudo RAM (48kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$0C000 - $DFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (848kB of 1MB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (848kB of 1MB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$E0000 - $EFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">SRAM (64kB of 1MB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (64kB of 128kB)</td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;">$F0000 - $FFFFF</th>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (64kB of 128kB)</td>
<td style="border: 1px solid #cccccc; padding: 6px;">Flash (64kB of 128kB)</td>
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

## Design Rules

_My house, my rules!_

Some design rules which (hopefully) will allow a responsive multi-tasking system to be built.

1. Only interrupt service routines should disable the global interrupt. No application should disable the global interrupt flag. The only exception to this is where an atomic outcome is needed, and there is no Z80 instruction available to achieve what is required.

2. All the hardware resources will be protected by their own Mutual Exclusion (mutex) semaphore (or lock). Irrespective of whether you need exclusive use of a resource, use the lock. Otherwise you might be trampling another application's I/O. Potentially, a queuing semaphore may be needed at some stage, but for now, it is simply a `SRA` based little mutex.

3. Shadow (alternate) registers are reserved for the use of the bank switching routines, and for yabios library code. Interrupt service routines should not use the shadow registers. Z88dk system library code uses shadow registers, and the calling yabios code will retain the `shadowLock` mutex, to ensure that the Z88dk library code is not affected by a bank switch at an inconvenient time.

4. Applications should use their own stack, which will be located at the top of the BANK space when they are initialised (unless otherwise defined), and not rely on the system stack being available. If parameters need to be passed on the stack to the library code, then they will have to be pushed onto the system stack, before the `system` call.

5. CP/M specific BIOS items will exist in the BANK space, below the YABIOS space, ensuring that the CP/M specific buffers and jump tables do not consume space in non-CP/M applications.


## System Function Definitions

These system functions are essential for creating bank handling for the YAZ180.

Whilst they will be exposed to the user through linkage into the Z88dk libraries, they are not expected to be used by an application, and they may cause harm to the coherency of the system if they are used.

### Note on BANK relative addressing, the `far void*`

For all memory related functions in the Z180 which extend beyond the Z80 addressing capability of 64kB, there needs to be a decision made as to how to address locations. Where a flat RAM model is being pursued, it makes sense to create a flat addressing structure.

However, in the YAZ180 we have a banked memory assignment. This means that the top of one bank is not contiguous with the bottom of another bank, and the YABIOS exists in a specific location in `BANK_0`. Therefore, we are never going to copy memory across the edge of a BANKED memory space. Both of these issues point to a slightly different addressing scheme.

For all far memory functions, the high byte of the 20bit address will be a twos complement bank-relative address. Additionally, as a later enhancement, calling far memory functions from a non-zero bank (as a user) will ensure that `BANK_0` and (`BANK13`, `BANK14`, and) `BANK15` cannot be reached, and `COMMON_AREA_1` memory cannot be written.

Far pointers will normally be passed in the `EHL` registers, as is the z88dk standard.<br>
`0xEE` is the twos complement bank address, as defined above.<br>
`0xHH` is the normal high or page address, within 64kB.<br>
`0xLL` is the normal low address, within 64kB.<br>


### `_memcpy_far`

`void *memcpy_far(void *str1, int8_t bank1, const void *str2, const int8_t bank2, size_t n)`<br>
`str1` − This is a pointer to the destination array where the content is to be copied, type-cast to a pointer of type `void*`.<br>
`bank1` − This is the destination bank, relative to the current bank.<br>
`str2` − This is a pointer to the source of data to be copied, type-cast to a pointer of type `void*`.<br>
`bank2` − This is the source bank, relative to the current bank.<br>
`n` − This is the number of bytes to be copied.<br>
This function returns a `void*` to destination, which is `str1` in `HL`.

IN:

    stack:
    n high
    n low
    bank2 far
    str2 high
    str2 low
    bank1 far
    str1 high
    str1 low
    ret high
    ret low

OUT:

    HL = `void*` to `str1`

Registers affected after return:
```
    ......../IXIY   preserved
    AFBCDEHL/....   modified
```
Notes:

`_memcpy_far` respects overlapping source and destination regions.
No checking is done to prevent writing to the `PAGE0` region, as this will be a common requirement.

Memory copying is done with DMAC0, using burst mode. This means that the CPU is halted during the transfer. This affects processing of other interrupts.

### `_load_hex`

`void _load_hex(char bank)`<br>
`bank` − This is the desired bank (in two's complement) _relative_ to the current bank. For example `0xFF` is one bank lower than the current bank.

IN:

    L = destination BANK, relative addressed.

OUT:

    -

Registers affected after return:
```
    ..BCDEHL/IXIY   preserved
    AF....../....   modified
exx AFBCDEHL        modified
```
Notes:

When called `_load_hex` waits for Intel HEX to be loaded via the CLI, and will load it into the provided initial bank. Any Type 2 ESA HEX instruction present within the Intel HEX will override CLI selection.

`_load_hex` provides an initial bank for loading the application. Type 2 ESA HEX information provides further _relative_ (preferred) bank information, in the [format defined above](https://github.com/feilipu/yaz180/tree/master/yabios#note-on-bank-relative-addressing), should the program to be loaded extend beyond one bank.

The contents of the alternate register set is modified only during the internal banks which function with interrupts disabled. This is only a momentary situation. Normal `_load_hex` operation is with interrupts enabled (to ensure that the ASCI interfaces are working).

No checking is done to prevent the `BANK_0` or flash memory bank (`BANK13`, `BANK14`, or) `BANK15` from being selected, if the system calls `_load_hex`.

No checking is done to prevent `PAGE0` and `COMMON AREA 1` memory being overwritten, if the system calls `_load_hex`.

When the user calls `_load_hex`, access to `BANK_0` will be prevented, enabling relocation of applications, and will ensure that critical `PAGE0` and `COMMON AREA 1` memory cannot be overwritten.

### `_load_bin`

`void _load_bin(far void* str)`<br>
`str` − This is a pointer to the destination where the content is to be copied, type-cast to a pointer of type `far void*`.<br>

IN:

    E = destination BANK, relative addressed.
    HL = `void*` to `str`

OUT:

    -

Registers affected after return:
```
    ..BC..../IXIY   preserved
    AF..DEHL/....   modified
exx AFBCDEHL        modified
```
Notes:

When called `_load_bin` waits for binary data to be loaded via the CLI, and will load it into memory starting from the provided initial destination  `str`.

The alternate register set is modified only during the internal `_bank_switch` function with interrupts disabled. This is only a momentary situation. Normal `_load_hex` operation is with interrupts enabled (to ensure that the ASCI interfaces are working).

No checking is done to prevent the `BANK_0` or flash memory bank (`BANK13`, `BANK14`, or) `BANK15` from being selected if the system calls `_load_bin`.

No checking is done to prevent `PAGE0` and `COMMON AREA 1` memory being overwritten, if the system calls `_load_bin`.

When the user calls `_load_bin`, access to `BANK_0` will be prevented, enabling relocation of applications, and will ensure that critical `PAGE0` and `COMMON AREA 1` memory cannot be overwritten.

## User System Interfaces

Access to YABIOS is designed to be through calls to the `RST20` System Call, and the `RST18` APU Call. Access to banked applications (greater than 60kB in size) is designed to be through the `RST10` `_call_far`. General management of the YAZ180 is to be done through the Command Line Interface.

Errors will be reported to an Error handler function located at `RST8`, registered for each application, as desired.

Additional short call `RST30` addresses may be used by the application as desired.

### `RST30` Reserved User Call

The user might want to have a `RST` short call available. Reserve this `RST` for user short calls within a bank.

### `RST28+DEFB` APU Call

Registers affected after return:
```
    ..B.DE../IXIY   preserved (check called APU Function)
    AF.C..HL/....   modified  (check called APU Function)
```
Notes:

YABIOS APU Calls are provided within the `COMMON AREA 1` memory space, and can be linked to an Z88dk application program.

For example, for the `APU_OP_SQRT` command the System Call is generated by following example byte code:

```
RST28
DEFB __IO_APU_IO_SQRT
```

Following execution of the APU Call, the operation returns to the calling application.

### `RST20+DEFW` System Call

IN:

    Parameters required to execute the System Call, in Registers, or on Stack

OUT:

    Parameters returned by the System Call

Registers affected after return:
```
    ......../IXIY   preserved (check called System Function)
    AFBCDEHL/....   modified  (check called System Function)
exx AFBCDEHL        modified  (check called System Function)
```
Notes:

YABIOS System Calls are provided within the `BANK_0`, or `COMMON AREA 1` memory space, and can be linked to an Z88dk application program.

For example, the `_f_printf` function parameters are placed on the Stack or Registers, and the System Call is generated by following example byte code:

```
RST20
DEFW _f_printf
```

Following execution of the System Call, the operation returns to the calling application.

The the contents of the alternate register set is modified during the internal bank switch with interrupts disabled, during a System Call. Interrupts are disabled only for a momentary situation. Normal operation is with interrupts enabled.  Therefore for YABIOS system functions that require the use of the alternate register set, some evaluation of the actual requirements will need to be completed.

### `RST18` `_jp_far`

IN:

    `far void *` in EHL, to the location

OUT:

Registers affected after return:
```
    ......../IXIY   preserved (check called System Function)
    AFBCDEHL/....   modified  (check called System Function)
exx AFBCDEHL        modified  (check called System Function)
```

Notes:

YABIOS `_jp_far` call are provided to support an application in its own memory space. The location of the application `_user_function` is provided by a `far void *`.

The `_jp_far` call is generated by following example byte code:

```
LD E, -1                ; Destination BANK, for example one bank below
LD HL, _user_function   ; Address of _user_function
RST18
```
The the contents of the alternate register set is modified during the internal bank switch with interrupts disabled, during a System Call. Interrupts are disabled only for a momentary situation. Normal operation is with interrupts enabled.

### `RST10+DEFW+DEFB` `_call_far`

IN:

    Parameters required to execute the `_user_function` call, in Registers or on Stack

OUT:

    Parameters returned by the `_user_function` call

Registers affected after return:
```
    ......../IXIY   preserved (check called _user_function)
    AFBCDEHL/....   modified  (check called _user_function)
exx AFBCDEHL        modified  (check called _user_function)
```
Notes:

YABIOS `_call_far` calls are provided to support an application in its own memory space. The location of the application `_user_function` is provided by a `far void *`.

The called `_user_function` parameters are placed on the Stack or Registers, and the `_call_far` call is generated by following example byte code:

```
RST10
DEFW 0xHHLL
DEFB 0xEE
```

Where:<br>
0xHHLL = `void*` to `_user_function`
0xEE = destination BANK, _relative_ addressed, to the current BANK.<br>

Following execution `_user_function` call, the operation returns to the calling application.

The the contents of the alternate register set is modified during the internal bank switch with interrupts disabled, during a System Call. Interrupts are disabled only for a momentary situation. Normal operation is with interrupts enabled.

### `RST8+DEFB` Error Handler

IN:

    Parameters required to execute the `_error` call, in Registers or on Stack

OUT:

    Parameters returned by the `_error` call

Registers affected after return:
```
    ......../IXIY   preserved (check called _error Function)
    AFBCDEHL/....   modified  (check called _error Function)
```
Notes:

YABIOS `_error` calls are provided to support an application in its own memory space. The location of the application `_error` function is provided by a `void*` within the application's own bank.

The `_error` parameters are placed on the Stack or Registers, and the `_error` call is generated by following example byte code:

```
RST08
DEFB 0xEE           ; optional if error code is placed in subset of DEHL
```

Where:<br>
EE = error code as defined by the application.<br>

Following execution `_error` call, the operation returns to the Command Line interface via `_warm_start`, and does not return to the calling function.

```
RST08:
    pop hl             ; get return address in hl
    call _error        ; user provided function, minimum is `ret`
    jp _warm_start     ; YABIOS provided warm restart function
```

### Command Line Interface

The command line interface is implemented in C, with the underlying functions either in C or in assembly.

#### CP/M Functions
- `mkcpmb [src][dest][file][][][]` - initialise dest bank for CP/M from src bank, up to 4 drive files
- `mkcpmd [file][dir][bytes]` - create a drive file for CP/M, with dir entries, of bytes size

#### Bank Functions
- `mkb [bank]` - initialise the nominated bank (to warm state)
- `cpb [src][dest]` - copy or clone the nominated src bank
- `rmb [bank]` - remove the nominated bank (to cold state)
- `lsb` - list the usage of banks, and whether they are cold, warm, or hot (not implemented)
- `initb [bank][origin]` - begin executing the nominated bank at nominated address
- `loadh [bank]` - load the nominated bank with Intel Hex from ASCI0 / ASCI1 (ESA supported)
- `loadb [path][bank][origin]` - load the nominated bank from origin with binary code
- `saveb [bank][path]` - save the nominated bank from 0x0100 to 0xF000

#### System Functions
- `md [bank][origin]` - memory dump, origin in hexadecimal
- `help` - this is it
- `exit` - exit and restart

#### File System Functions
- `ls [path]` - directory listing
- `rm [path]` - delete a file
- `cp [src][dest]` - copy a file
- `cd [path]` - change the current working directory
- `pwd` - show the current working directory
- `mkdir [path]` - create a new directory
- `chmod [path][attr][mask]` - change file or directory attributes
- `mount [path][option]` - mount a FAT file system

#### Disk Functions
- `ds` - disk status
- `dd [sector]` - disk dump, sector in decimal

#### Time Functions
- `clock [timestamp]` - set the time (UNIX epoch) using `date +%s`
- `tz [tz]` - set timezone (no daylight saving)
- `diso` - local time ISO format: 2013-03-23 01:03:52
- `date` - local time: Sun Mar 23 01:03:52 2013

