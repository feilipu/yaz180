#!/usr/bin/perl
use Time::HiRes qw(gettimeofday);

# Set programmer FTDI device name here:

# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A704DIVK-if00-port0'; # YaZ180v1
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A104Q1AM-if00-port0'; # YAZ180v2

# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A105LKZ7-if00-port0'; # v2.1
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A105LKZ8-if00-port0'; # v2.1
$device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A105LKZ9-if00-port0'; # v2.1 Alvin

# Note that in recent versions of Linux, the devices also show up in
# /dev/serial/by-id/name where the device name includes the serial number,
# which is probably a far more reliable way to address the device.

# Many issues I've had in the past have been related to bugs either in the
# kernel or the FTDI driver, or perhaps a flaky USB hub, or problems in the
# FTDI chips themselves.  Never did figure out exactly what the issue was.
# Whatever the cause, limiting the maximum amount of data exchanged in a
# single read or write call solved the problems I was having.

$max_read_size = 15;
$max_write_size = 15;

# If you run into issues, try changing both to 1 just in case.
# I once had a flaky USB hub which would make the process fail
# if the max_write_size was set to anything more than 15.

unless (-c $device) {
  die "Device file '$device' does not exist!\n";
};

# Linux kernels are good at locking up in the functions called by the
# 'stty' command, so we display a message explaining the error, then
# quickly erase it after the command executes.  If it doesn't fail,
# the message disappers before the user can see it.

print "If you see this message, unplug your device and try again.\n";
`stty raw -echo < $device`; print "\e[A\e[K"; select undef, undef, undef, 0.1;

# With the stupid terminal features disabled, now open the device:

open FTDI, '+<', $device or die "Cannot open $device: $!\n";

# Tell Perl not to buffer our I/O:

select FTDI; $| = 1;
select STDOUT; $| = 1;

# Finally, we can begin!

print "Switching Z80 to 'program' mode...\n";
$code  = pack('H*', '00000000000000'); # NOPs
$code .= pack('H*', 'C30000'); # jp $0000

# print $code . "\n"; # DEBUG feilipu

special_write($code);

# If this is our second attempt, let's wait a second and make sure there's
# nothing in the pipe before we continue:

print "Waiting a moment for data we shouldn't receive...\n";
while ('true') {
  $read = $write = $bullshit = '';
  vec($read, fileno(FTDI), 1) = 1;
  $count = select $read, $write, $bullshit, 0.1;
  last if $count == 0;
  $size = sysread FTDI, $bullshit, $max_read_size;
  print "Received $size bytes we shouldn't have received.\n";
};

# Now we test two-way communication with the Z80 by constructing a series
# of instructions which send a string of data back over the FTDI device.

$test = "This string is test data!";

print "Testing two-way communication...\n";

$code .= pack('H*', '210000');    # ld hl $0000
for ($i = 0; $i < length($test); $i++) {
  $code .= pack('H*', '7E');      # ld a [hl]
  $code .= substr($test, $i, 1);  # [data]
  $code .= pack('H*', '77');      # ld [hl] a
};
$code .= pack('H*', 'C30000');  # jp $0000
special_write($code);

# If what we received is what we sent, everything is cool!

unless ($test eq special_read(length($test))) {
  die "Two-way communication test failed.\n";
};

print "Two-way communication successful!\n";

# Now we'll test the SRAM in two stages.  In the first, we test the first
# 64 bytes manually.  Once it is verified, we load a small test program into
# that 64 bytes and utilise it to test the remaining SRAM faster.

$sram_test = pack('H*', '210000110020010001EDB0210020110000010001EDB0C30000');

# ...or, load from file if the file exists...

if (-f "sram_test.rom") {
  open FILE, "sram_test.rom";
    read FILE, $sram_test, 4096;
  close FILE;
};
if (length($sram_test) > 64) {
  die "The SRAM test program (sram_test.rom) is too big!\n";
};
$sram_test .= "\x00" x (64 - length($sram_test));

print "Testing SRAM (stage one)...\n";

for ($j = 3; $j < 4; $j++) {

  # First we construct a sequence of test bytes...

  $test = '';
  for ($i = 0; $i < 64; $i++) {
    if ($j == 0) {
      $byte = 0x55;
    } elsif ($j == 1) {
      $byte = 0xAA
    } elsif ($j == 2) {
      $byte = int(256 * rand());
    } else {
      # For the last test, we use the code of the SRAM test program.
      $test = $sram_test; last;
      # Thus, the success of this test verifies the program is loaded.
    };
    $test .= pack('C', $byte);
  };

  # Then we write them to the SRAM...

  $code = '';
  $code .= pack('H*', '210000');    # ld hl $0000
  $code .= pack('H*', '110040');    # ld de $4000
  for ($i = 0; $i < 64; $i++) {
    $code .= pack('H*', 'EDA0');    # ldi
    $code .= substr($test, $i, 1);  # data read from [hl]
  };
  $code .= pack('H*', 'C30000');    # jp $0000

  # This code reads data from the SRAM and writes it to the FTDI chip.

  $code .= pack('H*', '210040');    # ld hl $4000
  $code .= pack('H*', '110000');    # ld de $0000
  for ($i = 0; $i < 64; $i++) {
    $code .= pack('H*', 'EDA0');    # ldi
  };
  $code .= pack('H*', 'C30000');    # jp $0000

  # Now we just send all of that code to the Z80, then wait for the data
  # to come back.  Because we're sending the instructions that read the
  # memory contents, we must be prepared to receive them while we send the
  # instructions, thus we can't use the special read & write functions.

#  print "...\n";
  $sent = 0; $receive = '';
  while ('whatever') {
    $read = $write = $what = '';
    vec($read, fileno(FTDI), 1) = 1;
    vec($write, fileno(FTDI), 1) = 1 if $sent < length($code);
    $result = select $read, $write, $what, 1.0;
    last if $result == 0 and $sent == length($code);
    if (vec($read, fileno(FTDI), 1)) {
      $result = sysread FTDI, $receive, $max_read_size, length($receive);
      die "Read error: $!" if $result < 0;
      die "FTDI device disappeared!" if $result == 0;
      last if length($receive) == length($test);
    };
    if (vec($write, fileno(FTDI), 1)) {
      $result = syswrite FTDI, $code, $max_write_size, $sent;
      die "Write error: $!" if $result < 0;
      die "FTDI device disappeared!" if $result == 0;
      $sent += $result;
    };
#    print "\e[1ASent $sent bytes, received " . length($receive) . " bytes...\n";
  };

  # If the memory contents match what we wrote to them, we have working SRAM.

  unless ($receive eq $test) {
    compare($test, $receive);
    die "SRAM test (stage one) failed!\n";
  };

};

print "SRAM test (stage one) succeeded!\n";


# Now, figure out what we are doing...

print "Switching Z80 to 'normal' mode...\n";

special_write(pack('C*', 0x76));     # halt

if ($function eq 'write' or $function eq 'writeprotect') {
  if ($new_memory eq $old_memory) {
    print "\nEEPROM/SRAM has been programmed and verified!\n";
  } else {
    compare($new_memory, $old_memory);
    die "\nVerification of EEPROM/SRAM contents failed!\n";
  };
};

sub compare {
  open FILE, ">", ".first";
    print FILE $_[0];
  close FILE;
  open FILE, ">", ".second";
    print FILE $_[1];
  close FILE;
  `hexdump -C ".first" > .first.txt`;
  `hexdump -C ".second" > .second.txt`;
  print `diff .first.txt .second.txt`;
};

sub special_read {
  my ($buffer, $result, $size);
  print "Reading $_[0] bytes:\n"; # debug
  print "...\n"; # debug
  while (length($buffer) < $_[0]) {
    $size = $_[0] - length($buffer);
    $size = $max_read_size if $size > $max_read_size;
    $result = sysread FTDI, $buffer, $size, length($buffer);
    die "Read error: $!\n" if $result < 0;
    print "\e[1ARead " . length($buffer) . " bytes so far...\n"; # debug
    last if length($buffer) == $_[0];
    last if $result == 0;
  };
  print "Read complete!\n"; # debug
  return $buffer;
};

sub special_write {
  my ($count, $result, $size);
  print "Writing " . length($_[0]) . " bytes:\n"; # debug
  print "...\n"; # debug
  while ($count < length($_[0])) {
    $size = length($_[0]) - $count;
    $size = $max_write_size if $size > $max_write_size;
    $result = syswrite FTDI, substr($_[0], $count, $size);
    die "Write error: $!\n" if $result < 0;
    $count += $result;
    print "\e[1AWrote $count bytes so far...\n";  # debug
  };
  print "Write complete!\n";  # debug
};
