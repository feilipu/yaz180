# Implementation Notes

These are some notes taken during implementation, so that the scraps of paper don't get lost.

## FIXME

- convert APU driver from storing operand pointers, to actually store operands.<br>
- implement mutex lock code for apu [ ], asci0 [ ], and asci1 [ ].<br>

## Why the `COMMON_AREA_1` shrunk

Now that we're trying to keep the `COMMON_AREA_1` space down to 4kB, we need to pack things in tight.

The CP/M BIOS functions will be below the YABIOS area, because they relate only to CP/M, and there are some large allocation vectors for the disks that are not required for other systems. So, don't push them on other systems. We can then choose whether the CP/M BDOS/BIOS is large or small, depending on how we prepare the hard drive files.

## Calculating `COMMON1` addresses

We have `$0600` bytes of aligned buffers, with the two ASCI and the APU. Put them at the bottom, then unaligned data starts at `$F600`. That allows the code section to flow after, and makes copying on setup a single transfer.

So that the Z80 jump and Z180 vector tables don't have to be moved, put them at the top. Therefore the Z80 `__IO_VECTOR_BASE` is `$FFE0`, and with the Z180 `__crt_io_vector_base` being `0x0000` bytes later at `$FFE0`.

We can use these `$20` bytes from `$FFC0` to `$FFDF` to record the local `SP` for each of the 15 `BANKnn`, and system SP for `BANK0`.

That puts the initial system stack pointer at `$FFC0`, with two bytes available at `$FFC0` to enable the global SP to be stored, when local SP is switched over.

Before initialisation, keep `SP` starting down at `$F000`, otherwise it will be overwritten by the `COMMON_AREA_1` memory initialisation.

## Modifying the memory model

Based on the above, we can allow the memory model to be expanded by just 3 items. The `rodata_page0` contains `$0040` bytes of simple page zero code, to be replicated to each `BANKnn` during initialisation, and when a bank is reloaded.

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
- DMAC0/1 code for doing `_far_memcpy` and `_far_memset`.
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





