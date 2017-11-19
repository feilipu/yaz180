#!/usr/bin/perl

open FILE, '<', $ARGV[0];
  while ('true') {
    read FILE, $data, 24;
    last if $data eq '';
    print "\$code .= pack('H*', '";
    print uc(unpack('H*', $data));
    print "');\n";
  };
close FILE;
