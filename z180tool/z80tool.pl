#!/usr/bin/perl
use Time::HiRes qw(gettimeofday);

# Set programmer FTDI device name here:

# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A704DIVK-if00-port0'; # YAZ180v1
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A104Q1AM-if00-port0'; # YAZ180v2

# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A105LKZ7-if00-port0'; # v2.1 Phillip Ok
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A105LKZ8-if00-port0'; # v2.1
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_A105LKZ9-if00-port0'; # v2.1 Alvin Ok

$device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_AI05EB35-if00-port0' ; # v2.4 Phillip Ok
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_AI05EB36-if00-port0' ; # v2.4 
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_AI05EB37-if00-port0' ; # v2.4
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_AI05EB38-if00-port0' ; # v2.4 Frank Ok
# $device = '/dev/serial/by-id/usb-FTDI_FT245R_USB_FIFO_AI05EB39-if00-port0' ; # v2.4 Klaus Ok

# Note that in recent versions of Linux, the devices also show up in
# /dev/serial/by-id/name where the device name includes the serial number,
# which is probably a far more reliable way to address the device.

# Many issues I've had in the past have been related to bugs either in the
# kernel or the FTDI driver, or perhaps a flaky USB hub, or problems in the
# FTDI chips themselves.  Never did figure out exactly what the issue was.
# Whatever the cause, limiting the maximum amount of data exchanged in a
# single read or write call solved the problems I was having.

# $max_read_size = 15;
# $max_write_size = 15;

$max_read_size = 1;
$max_write_size = 1;

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

$main_code .= pack('H*', '310078210000E52160408785DD6FAF8CDD67DD6E00DD6601');
$main_code .= pack('H*', 'E9000000000000007D4169415541EC40A9400441C9408040');
$main_code .= pack('H*', '87400000000000000000000000000000CD8D42CD3742C93E');
$main_code .= pack('H*', 'AA3255D53E5532AAAA3E803255D53EAA3255D53E5532AAAA');
$main_code .= pack('H*', '3E203255D5CD3742C91100802100004E1AB9CAC14079121A');
$main_code .= pack('H*', 'B9C2B7401AB9C2B7407713AFB2C2AF40C91100802100004E');
$main_code .= pack('H*', '1AB9CAE440CD8D4279121AB9C2DA401AB9C2DA407713AFB2');
$main_code .= pack('H*', 'C2CF40C9110080ED530060CD1F41CD3741CD2B413A0160B7');
$main_code .= pack('H*', 'C2F340C9110080ED530060CD1F41CD8D42CD3741CD2B413A');
$main_code .= pack('H*', '0160B7C20B41C9210000110070014000EDB0C92100701100');
$main_code .= pack('H*', '00014000EDB0C9210070ED5B0060013F00EDB07E121ABEC2');
$main_code .= pack('H*', '45411ABEC2454113ED530060C9110080210000010040EDB0');
$main_code .= pack('H*', '210000010040EDB0C9210080110000010040EDB011000001');
$main_code .= pack('H*', '0040EDB0C97AF68057ED530060EBDD2102607EDD7700C669');
$main_code .= pack('H*', 'E6FE77DD77017EDD77027EDD7703DD7E02DDBE00200BDD7E');
$main_code .= pack('H*', '03DDBE002003C32542DD7E02DDBE01200BDD7E03DDBE0120');
$main_code .= pack('H*', '03C32E42CD37427EDD77047EDD7705DD7E04DDBE00200BDD');
$main_code .= pack('H*', '7E05DDBE002003C36642DD7E04DDBE01200BDD7E05DDBE01');
$main_code .= pack('H*', '2003C34542CD16422100003600DD7E0077DD7E0177DD7E02');
$main_code .= pack('H*', '77DD7E0377DD7E0477DD7E0577C9C9CD37422A00603A0260');
$main_code .= pack('H*', '77CD3742C9CD16422100003601C9CD16422100003602C9C5');
$main_code .= pack('H*', '0100000DC23B4205C23B42C1C9CD1642CD9D42CDC342F5CD');
$main_code .= pack('H*', 'FF42CDC342F1B7CA60422100003603C92100003604C9CD16');
$main_code .= pack('H*', '42CD9D42CD8D42CDC342F5CDFF42CD8D42CDC342F1B7CA87');
$main_code .= pack('H*', '422100003605C92100003606C93EAA3255D53E5532AAAA3E');
$main_code .= pack('H*', 'A03255D5C93A0060E6C03200602A0060114070014000EDB0');
$main_code .= pack('H*', '21407011007006407EC669E6FE12231310F6C9210070ED5B');
$main_code .= pack('H*', '0060013F00EDB07E120100000B78B1CAFC421ABEC2D4421A');
$main_code .= pack('H*', 'BEC2D442210070ED5B00600140001ABEC2FC4213230BC2EE');
$main_code .= pack('H*', '423E01C93E00C9214070110070014000EDB0C900');

# ...or, load from file if the file exists...

if (-f "main_code.rom") {
  open FILE, "main_code.rom";
    read FILE, $main_code, 65536;
  close FILE;
};
if (length($main_code) > 16320) {
  die "The SRAM test program (main_code.rom) is too big!\n";
};
$main_code .= "\x00" x (16320 - length($main_code));

print "Testing SRAM (stage two)...\n";

for ($j = 3; $j < 4; $j++) {

  # First we construct a sequence of test bytes...

  $test = '';
  for ($i = 0; $i < 16320; $i++) {
    if ($j == 0) {
      $byte = 0x55;
    } elsif ($j == 1) {
      $byte = 0xAA
    } elsif ($j == 2) {
      $byte = int(256 * rand());
    } else {
      # For the last test, we use the code of the SRAM test program.
      $test = $main_code; last;
      # Thus, the success of this test verifies the program is loaded.
    };
    $test .= pack('C', $byte);
  };

  # Then we utilize the code already in SRAM, which will write the test
  # data to SRAM, then read the SRAM and send us a copy of what is in it.

  $code = '';
  $code .= pack('H*', 'C30040');    # jp $4000
  $code .= $test;
  special_write($code);

  # Then we just read the SRAM contents...

  $receive = special_read(16320);

  # If the memory contents match what we wrote to them, we have working SRAM.

  unless ($receive eq $test) {
    compare($test, $receive);
    die "SRAM test (stage two) failed!\n";
  };

};

print "SRAM test (stage two) succeeded!\n";

# Now, figure out what we are doing...

@functions = ('read', 'write', 'protect', 'unprotect', 'writeprotect', 'check');
foreach $i (@functions) {
  $fuck{$i} = '';
};

$function = $ARGV[0];

if (!exists $fuck{$function}) {
  print STDERR "Unknown function '$function'\n";
  print STDERR "Usage: ./z80tool.pl [function] [filename]\n";
  print STDERR "Functions:
  read - reads the Z80 memory and writes it to specified file
  write - writes the specified file to Z80 memory
  protect - enables write protection on AT28C256 EEPROMs
  unprotect - disables write protection on AT28C256 EEPROMs
  writeprotect - writes the specified file to Z80 memory, then
                 enables write protection on the AT28C256 EEPROMS.
  check - Just checks what type of memory is in the Z80, and its
          write protection status.  May wreck the EEPROM's contents
          in the process, as it must write to it to figure it out.\n";
  exit 1;
};

if ($function eq 'write' or $function eq 'writeprotect' or $function eq 'read') {
  if ($ARGV[1] eq '') {
    die "You must specify a file for function '$function'\n";
  };
  if ($function eq 'write' or $function eq 'writeprotect') {
    unless (-f $ARGV[1]) {
      die "File '$ARGV[1]' does not exist.\n";
    };
    open FILE, '<', $ARGV[1];
      read FILE, $new_memory, 65536;
    close FILE;
    if (length($new_memory) != 32768) {
      die "File '$ARGV[1]' must contain 32768 bytes.\n";
    };
  };
};

if ($function eq 'write' or $function eq 'writeprotect' or $function eq 'check') {

  # With SRAM tested and the main code loaded, we can have the main code
  # check what type of memory is in the ROM slot on the Z80...

  print "Checking whether Z80 contains EEPROM or SRAM...\n";

  $code = '';
  $code .= pack('H*', '210000');    # ld hl $0000
  $code .= pack('H*', '11');        # ld de xxxx
  $address = int(32768 * rand()) + 32768;
  $code .= pack('v', $address);
  $code .= pack('H*', '7E');        # ld a [hl]
  $code .= pack('C', 0);            # [data]
  $code .= pack('H*', 'C34040');    # jp $4040
  special_write($code);

  $memory_type = unpack('C', special_read(1));

  if ($memory_type == 0) {
    @bytes = unpack('C*', special_read(6));
    print "Result of memory test: inconclusive\n";
    print "Test address: \$" . uc(unpack('H4', pack('n', $address))) . "\n";
    print "Original value: \$" . uc(unpack('H2', pack('C', $bytes[0]))) . "\n";
    print "Modified value: \$" . uc(unpack('H2', pack('C', $bytes[1]))) . "\n";
    print "Immediate value 1: \$" . uc(unpack('H2', pack('C', $bytes[2]))) . "\n";
    print "Immediate value 2: \$" . uc(unpack('H2', pack('C', $bytes[3]))) . "\n";
    print "Delayed value 1: \$" . uc(unpack('H2', pack('C', $bytes[4]))) . "\n";
    print "Delayed value 2: \$" . uc(unpack('H2', pack('C', $bytes[5]))) . "\n";
    die "With memory_types like that, it isn't clear how to proceed.\n";
  } elsif ($memory_type == 1) {
    print "Result of memory test: It's ROM.\n";
    die "As it doesn't appear to be RAM or EEPROM, we can't program it.\n";
  } elsif ($memory_type == 2) {
    print "Result of memory test: It's RAM.\n";
  } elsif ($memory_type == 3) {
    print "Result of memory test: It's unprotected EEPROM, with fast page mode.\n";
  } elsif ($memory_type == 4) {
    print "Result of memory test: It's unprotected EEPROM, without fast page mode.\n";
  } elsif ($memory_type == 5) {
    print "Result of memory test: It's protected EEPROM, with fast page mode.\n";
  } elsif ($memory_type == 6) {
    print "Result of memory test: It's protected EEPROM, without fast page mode.\n";
  } else {
    die "Unknown memory test result: $memory_type\n";
  };

};

if ($function eq 'write' or $function eq 'writeprotect') {

  if ($function eq 'writeprotect') {
    $memory_type = 5 if $memory_type == 3;
    $memory_type = 6 if $memory_type == 4;
  };

  if ($memory_type == 2) {
    print "Writing '$ARGV[1]' to SRAM...\n";
    $code = '';
    $code .= pack('H*', '210000');    # ld hl $0000
    $code .= pack('H*', '7E');        # ld a [hl]
    $code .= pack('C', 2);            # [data]
    $code .= pack('H*', 'C34040');    # jp $4040
    special_write($code);
    special_write($new_memory);
  } elsif ($memory_type >= 3 and $memory_type <= 6) {

    print "Writing '$ARGV[1]' to Z80 memory...\n";
    $code = '';
    $code .= pack('H*', '210000');    # ld hl $0000
    $code .= pack('H*', '7E');        # ld a [hl]
    $code .= pack('C', $memory_type);            # [data]
    $code .= pack('H*', 'C34040');    # jp $4040
    special_write($code);

    $start_time = gettimeofday();
    print "...\n";
    $sent = 0; $receive = '';
    while ('whatever') {
      $read = $write = $what = '';
      vec($read, fileno(FTDI), 1) = 1;
      vec($write, fileno(FTDI), 1) = 1 if $sent < length($new_memory);
      $result = select $read, $write, $what, 1.0;
      last if $result == 0 and $sent == length($new_memory);
      if (vec($read, fileno(FTDI), 1)) {
        $result = sysread FTDI, $receive, $max_read_size, length($receive);
        die "Read error: $!" if $result < 0;
        die "FTDI device disappeared!" if $result == 0;
        $current_time = gettimeofday();
        $elapsed_time = $current_time - $start_time;
        $byte_count = length($receive);
        if ($elapsed_time >= 1 && $byte_count > 0) {
          $rate = $byte_count / $elapsed_time;
          $remain = 32768 - $byte_count;
          $eta = int($remain / $rate + 0.999);
        };
        last if length($receive) == 32768;
      };
      if (vec($write, fileno(FTDI), 1)) {
        $result = syswrite FTDI, $new_memory, $max_write_size, $sent;
        die "Write error: $!" if $result < 0;
        die "FTDI device disappeared!" if $result == 0;
        $sent += $result;
      };
      print "\e[1ASent $sent bytes, received " . length($receive) . " bytes";
      print " ($eta seconds)" if $eta ne '';
      print "...\n";
    };
    print "\e[1ASent $sent bytes, received " . length($receive) . " bytes";
    print " ($eta seconds)" if $eta ne '';
    print "...\n";

  } else {
    die "I don't know how to write to memory type $memory_type\n";
  };

};

if ($function eq 'read' or $function eq 'write' or $function eq 'writeprotect') {

  print "Reading Z80 memory contents...\n";

  $code = '';
  $code .= pack('H*', '210000');    # ld hl $0000
  $code .= pack('H*', '7E');        # ld a [hl]
  $code .= pack('C', 1);            # [data]
  $code .= pack('H*', 'C34040');    # jp $4040
  special_write($code);
  $old_memory = special_read(32768);

  if ($function eq 'read') {
    open FILE, '>', $ARGV[1] or die "Failed to open '$ARGV[1]' for writing.\n";
      print FILE $old_memory;
    close FILE;
    print "Memory contents saved to '$ARGV[1]'\n";
  };

};

if ($function eq 'protect') {
  $code = '';
  $code .= pack('H*', '210000');    # ld hl $0000
  $code .= pack('H*', '7E');        # ld a [hl]
  $code .= pack('C', 7);            # [data]
  $code .= pack('H*', 'C34040');    # jp $4040
  special_write($code);

  print "Attempted to activate write protection.  If the chip does not support write\n";
  print "protection, then hell knows what actually happened.  Try the 'check' comamnd.\n";

};

if ($function eq 'unprotect') {
  $code = '';
  $code .= pack('H*', '210000');    # ld hl $0000
  $code .= pack('H*', '7E');        # ld a [hl]
  $code .= pack('C', 8);            # [data]
  $code .= pack('H*', 'C34040');    # jp $4040
  special_write($code);

  print "Attempted to disable write protection.  If the chip does not support write\n";
  print "protection, then hell knows what actually happened.  Try the 'check' comamnd.\n";

};

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
