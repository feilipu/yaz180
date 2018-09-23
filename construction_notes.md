# Construction Notes

The best BOM, as in most accurate, is the Digikey Shopping Cart. But this is not so transparent, as the Item numbers don't match the names on the board. Use the Excel version of the BOM for reference, although it has a few extra parts that are unneeded.

To build instructions, this depends on your personal workflow. I have a cheap Chinese SMD oven, so I use this for most of the SMD components. Though, I've found that the RAM, I2C, and FTDI USB component soldering is better done by hand soldering, after the other SMD components are placed and soldered. Then I place the sockets for all of the through-hole components.

Finally, I use a TL866 to program the Lattice GAL devices, and the Flash with the relevant code, and dig into testing.

## Soldering

Also, please note that the soldering for the TSSOP SMD devices is quite hard. I have a bit of trouble with these myself and I still don't have a perfect workflow for getting the RAM and FTDI devices soldered right every time.

## PCB Version 2.1 (2017)

I found the ESP-01S doesn't need to have a level converter, because it has 5V tolerant I/O. Therefore the expensive level converter component is not needed. The footprint can be repaired by three small cuts, as shown. The Z80 ASCI1 TX line can be bridged with a resistor, between 0 Ohms and 1000 Ohms. I used 220 Ohms. The Z80 ASCI1 RX line can be bridged with a very short piece of wire, as shown.

<a href="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v2.1errata.png" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v2.1errata.png" width="400"/></a>

<a href="https://github.com/feilipu/yaz180/blob/master/docs/IMG_1339.JPG" target="_blank"><img src="https://github.com/feilipu/yaz180/blob/master/docs/IMG_1339.JPG" width="400"/></a>

Note that the SST39SF020A 256kB flash device is only supported for 128kB, unless the A17 pin is connected from the Memory GAL to the flash device. This means that `BANK15` is loaded at `0x10000`, rather than at `0x30000` as might be expected. In the default CUPL code `BANK13` and `BANK14` are defined as RAM also because of this issue.

Note that the Am9511A needs to have at least 5 clock cycles under Reset, to initialise itself properly. As the Reset pins on the 74LS93 are controlled by the same Reset as the Am9511A this doesn't happen. The Reset signal needs to be disconnected from the 74LS93, so that the Phi/8 signal can be provided continually to the Am9511A. Use a sharp knife to make a tiny cut to disconnect Pin 2 and 3, which are bridged from the Reset via. Be careful not to cut on the left side of the via, as this is the Reset signal to the Am9511A.

Note to operate the YAZ180 at 36.864MHz, and have the Am9511A work at its preferred frequency, the QD (/16) output of the 74LS93 divider needs to be connected to the Am9511A `CLK` rather than the QC (/8) output. In practice, I just lifted Pin 8 of the 74LS93 off the pad, and soldered a tiny jumper from Pin 11 to Pad 8. There's no problem with just breaking off Pin 8 if it is getting in the way.

<a href="https://github.com/feilipu/yaz180/raw/master/docs/YAZ180v21%20_APUerrata.png" target="_blank"><img src="https://github.com/feilipu/yaz180/raw/master/docs/YAZ180v21%20_APUerrata.png" width="400"/></a>

These two images show a Version 2.1 PCB with both APU modifications, and ESP-01S modification. The Flash address modification has not been made, and would only be visible on the back side.

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/yaz180/raw/master/docs/IMG_1606.jpg" target="_blank"><img src="https://github.com/feilipu/yaz180/raw/master/docs/IMG_1606.jpg"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.1 2017 Top Perspective View<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/yaz180/raw/master/docs/IMG_1607.jpg" target="_blank"><img src="https://github.com/feilipu/yaz180/raw/master/docs/IMG_1607.jpg"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>YAZ180 Version 2.1 2017 Bottom Perspective View<center></th>
</tr>
</tbody>
</table>
</div>


## PCB Version 2.2 (2018)

The ESP-01S won't boot with its IO held high. Therefore the two IO pins need to be removed from the connector before it is soldered into the PCB. This modification together with fix for PCB v2.1 (2017) is shown above.

The Am9511A Reset fix above needs to be made.

Also, the Am9511A `CLK` fix above needs to be made too.




