# Implementation Notes

These are some notes taken during implementation, so that the scraps of paper don't get lost.

## FIXME

- convert APU driver from storing operand pointers, to actually store operands.<br>
- implement mutex lock code for apu [ ], asci0 [ ], and asci1 [ ].<br>

## Why the `COMMON_AREA_1` shrunk

Now that we're trying to keep the `COMMON_AREA_1` space down to 4kB, we need to pack things in tight.

The CP/M BIOS functions will be below the YABIOS area, because they relate only to CP/M, and there are some large allocation vectors for the disks that are not required for other systems. So, don't push them on other systems. We can then choose whether the CP/M BDOS/BIOS is large or small, depending on how we prepare the hard drive files.

## Calculating `COMMON1` addresses

We have `$0500` bytes of aligned buffers, with the two ASCI and the APU. Put them at the bottom, then unaligned data starts at `$F500`. That allows the code section to flow after, and makes copying on setup a single transfer.

The ASCI Tx buffers share a single page, and are interleaved. This provides 127 bytes of Tx buffer and doesn't require manual buffer wrapping. Page alignment ensure that we only have to increment the low address byte to have the buffer wrap properly.

So that the Z80 jump and Z180 vector tables don't have to be moved, put them at the top. Therefore the Z80 `__IO_VECTOR_BASE` is `$FFE0`, and with the Z180 `__crt_io_vector_base` being `0x00` bytes later at `$FFE0`.

That puts the initial system stack pointer at `$FFC0`, with two bytes available at `$FFC0` to enable the global SP to be stored, when local SP is switched over.

## Modifying the memory model

Based on the above, we can allow the memory model to be expanded by just 3 items. The `rodata_page0` contains `$003B` bytes of simple page zero code, to be replicated to each `BANKnn` during initialisation, and when a bank is reloaded.

Then the `rodata_common1_data` and `rodata_common1_driver` can just follow each other into the space from `$F000`. The global stack will grow down to meet them somewhere (hopefully not too often).

```asm
section rodata_page0
section rodata_common1_data
section rodata_common1_driver
```

## Moving the Z88dk files around because `PHASE`

We need to have the YABIOS constructed in just three files. The `PAGE0` file, the `COMMON1_DATA` file, and the `COMMON1_DRIVER` file. This is pretty simple, based on the fact that we can't handle multiple files with phase currently. It breaks the nice model of one file per function, but that's ok for now. We don't have too many functions we want to put in the common area 1 memory.

## Setting up the Z80 `RST` calls

Because we're using all of the `RST` calls, (except `RST28` is reserved for the user, and `RST30` is reserved for FUZIX), the resulting code is `$00FE`. There is no Z80 jump table built, and the `RST` jumps will be directly to the actual function. These functions calls must be filled into the page zero table in `rodata_page0`.

The `__crt_enable_trap` enables us to use the `RST00` to do a warm boot, or optionally jump to the start of a transitory program in TPA space `$0100`.

```asm
   defc TAR__crt_enable_rst            = 0x00FE
   defc TAR__crt_enable_nmi            = 0
   defc TAR__crt_enable_trap           = 1
```

## What needs to be in `COMMON_AREA_1`?

Based on the [design rules](https://github.com/feilipu/yaz180/blob/master/yabios/README.MD#design-rules), the following things will need to be in the `COMMON_AREA_1` so that they can respond quickly.

- All interrupt code, for Z180 interrupts, and the Z80 INT0 APU ISR.
- ASCI0/1 get character code, so that `_load_hex` and `_load_bin` can work quickly.
- Banking code and handling the error, system and APU `RST` calls.
- DMAC0/1 code for doing `_memcpy_far` and `_memset_far`.
- Any Z80dk library code that is called by either a `PAGE0` or `COMMON_AREA_1` resident call, unless it is specifically a banked call.
- Scheduling code, when we get that far...

## What needs to be in `BANK0` RAM?

These elements need to be either statically defined the `BANK0` RAM, or located in the system heap space also in `BANK0`.

- Disk I/O buffers
- FatFS
- Floating point library conversions, and soft floating point
- clib
- time functions
- driver code that is not time critical or is large (i2c, graphics).

The boot monitor code will be the major program located in `BANK0` Flash, and this will be written in C.

## Sadly, there can never be a `jp_far`

I modified the `call_far` code to make a `jp_far` using the `RSTx + DEFW + DEFC` mechanism, but forgot that a `jp` instruction doesn't push the `PC` onto the stack. Therefore there is no way to know from whence the program arrived, when it hits the `rst` instruction. Damn. It would have been so nice to just switch banks like that. I guess the only way to do it is off the stack (costing the ability to pass some parameters).

## Compilation Command Line

First make sure that the ff and time libraries are installed into Z88dk using the `z88dk-lib` tool.

```bash
zcc +yaz180 -v -subtype=yabios -SO3 --list -m -clib=sdcc_iy -llib/yaz180/ff -llib/yaz180/time --max-allocs-per-node200000 main.c -gpf yabios.rex -o yabios -create-app
```
This generates a `yabios.ihx` file that can be written to the YAZ180 flash.

It also generates a `yabios.def` file containing the calling linkages for the particular compile. Note that this API will be quite unstable, because of the constant development in Z88dk, sdcc, and the resulting sizes of the `ff.lib` and `time.lib` system libraries. So once the YAZ180 flash is written, then the `yaz180.def` (or possibly renamed to `yaz180.asm`) API will be needed for every application.

## Loading Flash from outside yabios

It is possible to load `BANK13`, `BANK14`, and `BANK15` with application code either from the perl programming interface, or via the TL866 programming tool. Applications written in this way can be loaded to an initialised (`mkb`) bank using the `mvb` command and then executed using `initb` as normal.

## CP/M Implementation

The CP/M implementation supports both ASCI interfaces, with ASCI0 being the CRT and ASCI1 being the TTY. The CCP/BDOS is now running, but the disk interface needs to be completed. The work is to finalise the best way of getting CP/M disks to appear in a FATFs file system as simple files.

```bash
zcc +yaz180 --no-crt -m --list @cpm22.lst -o cpm22; appmake +glue -b cpm22 --ihex --clean
cat > /dev/ttyUSB0 < cpm22__.ihx 
```

I've added the `_f_expand()` into the FATFs implementation, as this will allow the YABIOS command line to create a correctly sized CP/M drive, which can then be added / or exchanged for other drives simply by renaming it. Formatting and other CP/M "disk" management will be done from within CP/M, using the YABIOS tools.





