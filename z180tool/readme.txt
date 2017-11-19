Edit z80tool.pl to point to your FTDI device's device file.

    ls -la /dev/serial/by-id/

You can also just use the /dev/ttyUSB device name, but FTDI chips are popular
and you may eventually plug another one into your computer.  It's better to
use the by-id path which contains the chip's serial number.

The script can program EEPROM both with and without high-speed programming
mode and with or without software write protection, as well as RAM.  It
detects automatically which type of memory is in the Z80 system, but has
only been tested with AT28C256 EEPROMs and SRAM, as I do not have other
EEPROMs.  I did, however, test the code paths by modifying the assembly code
to incorrectly detect which type of memory is present, and so it should work
with other memory chips.

Usage: ./z80tool.pl [function] [filename]

Functions:

  read - reads the Z80 memory and writes it to specified file
  write - writes the specified file to Z80 memory
  protect - enables write protection on AT28C256 EEPROMs
  unprotect - disables write protection on AT28C256 EEPROMs
  writeprotect - writes the specified file to Z80 memory, then
                 enables write protection on the AT28C256 EEPROMS.
  check - Just checks what type of memory is in the Z80, and its
          write protection status.  May wreck the EEPROM's contents
          in the process, as it must write to it to figure it out.

The z80tool.pl can run alone, the other files in this archive are there just
in case you need to modify it.  If it sees the resulting *.rom files from
compiling the two assembly source files, it will load them, otherwise it uses
versions stored within the script itself, made with the rom2perl.pl script.

http://www.ecstaticlyrics.com/electronics/Z80/EEPROM_programmer/
