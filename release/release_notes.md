## Release Notes

### V1.2

The current version of yabios has been used now for several months, and Release 1.2 provides a clear point from which code can be distributed.

At this point all of the included hardware drivers (ASCIO, 82C55 and APU), and software functions are working as expected, and yabios now provides a platform for further development.

Further development includes the I2C drivers, which are excluded from the yabios common RAM.

In the 256kB of Flash there are 4 pages of 64kB, split according to the memory map into Pages 0, 13, 14, and 15.

* Page 0 is the boot page, containing the yabios boot code and shell.
* Page 13 is a mandelbrot test using the Z180 `mul` instruction, showing the maximum performance at math.
* Page 14 is a mantelbrot test using the Am9511A-1 APU in floating point mode.
* Page 15 is the CP/M CCP/BDOS/BIOS from which the CP/M system loads (and reloads) during normal operation.

Note that the Am9511A-1 APU may have difficulty initialising itself, and may need to be power cycled. This will be obvious, because the expected output will not be provided.

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