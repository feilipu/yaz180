# Construction Notes

The best BOM, as in most accurate, is the Digikey Shopping Cart. But this is not so transparent, as the Item numbers don't match the names on the board. Use the Excel version of the BOM for reference, although it has a few extra parts that are unneeded.

To build instructions, this depends on your personal workflow. I have a cheap Chinese SMD oven, so I use this for most of the SMD components. Though, I've found that the RAM, I2C, and FTDI USB component soldering is better done by hand soldering, after the other SMD components are placed and soldered. Then I place the sockets for all of the through-hole components.

Finally, I use a TL866 to program the Lattice GAL devices, and the Flash with the relevant code, and dig into testing.

## Soldering

Also, please note that the soldering for the TSSOP SMD devices is quite hard. I have a bit of trouble with these myself and I still don't have a perfect workflow for getting the RAM and FTDI devices soldered right every time.

## PCB Version 2.1

I found the ESP-01S doesn't need to have a level converter, because it has 5V tolerant I/O. Therefore the expensive level converter component is not needed. The footprint can be repaired by [three small cuts](https://github.com/feilipu/yaz180/blob/master/docs/YAZ180v2.1errata.png), as shown.

## PCB Version 2.2

The ESP-01S won't boot with its IO held high. Therefore the two IO pins need to be removed from the connector before it is soldered into the PCB. This modification and the fix for PCB v2.1 is [shown in this file](https://github.com/feilipu/yaz180/blob/master/docs/IMG_1339.JPG).



