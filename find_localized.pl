#!/usr/bin/perl

use File::Find ();
use strict;

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name/;
*name = *File::Find::name;

my $print_unused = 1;
my %src_strings = ();

sub match_source;
sub match_localizable;

# Find all the localized strings in source files
File::Find::find({wanted => \&match_source}, '.');

# Find all the localized strings in Localizable.strings files
File::Find::find({wanted => \&match_localizable}, '.');

sub match_source {
  my $filename = $_;
  if ($filename =~ /\.m$/) {
    process_source($filename);
  }
}

sub match_localizable {
  my $filename = $_;
  if ($filename =~ /^Localizable.strings$/) {
    print "Processing $name\n";
    process_localizable($filename);
  }
}

sub process_source {
  my($file) = @_;

  open(FILE, $file) or die("Failed to open file $file: $!");

  my $lineno = 0;
  while (<FILE>) {
    my $line = $_;
    chomp($line);

    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    $lineno++;

    while ($line =~ /NSLocalizedString\(@"([^"]*)"/g) {
      my $string = $1;
      $src_strings{$string} = 1;
    }
  }

  close(FILE);
}

sub process_localizable {
  my($file) = @_;
  my %localized_strings = {};

  open(FILE, "iconv -f UTF-8 $file |") or die("Failed to open file: $!");

  my $lineno = 0;
  while (<FILE>) {
    my $line = $_;
    chomp($line);

    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    $lineno++;

    if ($line =~ /^"([^"]*)"\s*=/) {
      my $string = $1;
      $localized_strings{$string} = 1;
      if ($print_unused && $src_strings{$string} != 1) {
        print "  Unused $string\n";
      }
    }
  }

  close(FILE);

  foreach my $string (keys(%src_strings)) {
    if ($localized_strings{$string} != 1) {
      print "  Missing $string\n";
    }
  }
}

