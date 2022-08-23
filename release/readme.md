## Release Notes

### V1.2

The current version of yabios has been used now for several months, and Release 1.2 provides a clear point from which code can be distributed.

At this point all of the included hardware drivers (ASCIO, 82C55 and APU), and software functions are working as expected, and yabios now provides a platform for further development.

Further development includes the I2C drivers, which are excluded from the yabios common RAM.

In the 256kB of Flash there are 4 pages of 64kB, split according to the memory map into Pages 0, 13, 14, and 15.

* Page 0 is the boot page, containing the yabios boot code and shell.
* Page 13 is a mandelbrot test using the Z180 `mul` instruction, showing the maximum math performance.
* Page 14 is a mantelbrot test using the Am9511A-1 APU in floating point mode.
* Page 15 is the CP/M CCP/BDOS/BIOS from which the CP/M system loads (and reloads) during normal operation.

__Note__ that the Am9511A-1 APU may have difficulty initialising itself. This will be obvious, because the expected output will not be provided. In this case the yaz180 may need to be power cycled, or at a minimum reset.

If no IDE disk is available for testing, most of the system can be tested by running either the Page 13 or Page 14 mandelbrot programs, or simply doing some memory dumps.


<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/apu_mul_test.png" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/apu_mul_test.png"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>Testing using Page 13 and Page 14<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/cpm_test.png" target="_blank"><img src="https://raw.githubusercontent.com/feilipu/yaz180/master/docs/cpm_test.png"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>Testing Page 15 CP/M<center></th>
</tr>
</tbody>
</table>
</div>

### V1.3

There is little change to the yaz180 code in this release, but the underlying `zsdcc` compiler has been developed significantly. This release has been compiled with `r11311` of sdcc, using the patch file included in z88dk.

### V1.4

There is little change to the yaz180 code in this release, except a few tweaks to the far functions and ASCI drivers. This release has been compiled with `r11369` of sdcc, using the patch file included in z88dk. This release changes the location of most functions, so the [linkage file](https://github.com/z88dk/z88dk/blob/master/libsrc/_DEVELOPMENT/target/yaz180/crt_yabios_def.inc) in z88dk has been updated.

### V1.5

There is little change to the yaz180 code in this release, except a few tweaks to the IDE drivers and time reporting. This release has been compiled with `r11502` of sdcc, using the patch file included in z88dk. This release changes the location of some functions, so the [linkage file](https://github.com/z88dk/z88dk/blob/master/libsrc/_DEVELOPMENT/target/yaz180/crt_yabios_def.inc) in z88dk has been updated.

### V1.6

There is little change to the yaz180 code in this release, except a few tweaks to the CLI. This release has been compiled with `r11556` of sdcc, using the patch file included in z88dk. All the underlying libraries have been updated too.

### V2.0

__NOTE WELL__ This release __v2.0 changes the number of directory entries in CP/M drives to 2048 directory entries__. If you don't convert __your old drives__ to this new configuration, __they will be destroyed__.

There is no change to the yaz180 code in this release, except to change the directory structure. This release has been compiled with `r12017` of sdcc, using the patch file included in z88dk.

### V2.1

This release adds trap functionality to notify of illegal opcodes, most commonly present in programs developed for use within CP/M. This has meant that the function addresses have changed, and these are noted both here and in the [z88dk definitions file](https://github.com/z88dk/z88dk/blob/master/libsrc/_DEVELOPMENT/target/yaz180/crt_yabios_def.inc).

The command to clone or copy a bank has changed to `cpb` which is more aligned to its actual function.

Hardware flow control has been enabled on ASCI0 `CRT` using `/RTS`.

This release has been compiled with `r12419` of zsdcc, using the patch file included in z88dk.

### V2.2

This release provides some minor tidy up of the source code, including simplification of token parsing. The unimplemented function `lsb` has been removed from the CLI, and some defaults have been reset.

The serial interfaces have been adjusted to 115200 baud 8n2.

This release has been compiled with v4.2.0 `r13131` of zsdcc, using the patch file included in z88dk.
