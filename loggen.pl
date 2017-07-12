#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw(time usleep);
use IO::Handle;
use File::Copy;

use POSIX qw(strftime);

my ($rate, $outfile, $file1, $file2) = @ARGV;
my @files = ($file1, $file2);

my $fh = undef;
my $fcnt = 0;
my $linecnt = 0;
my $out = undef;
my $in = undef;
my $prev = undef;

my $start = time;
my $end = undef;
my $interval = 5;
my $flip = 0;

while (1) {
    if (!$fh) {
			my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;

			open $fh, '<', $files[$fcnt%2] or die "died";

			if($min % $interval == 0 && $sec == 0 && $flip == 0){
        my $newFileName = sprintf("%s.%04d-%02d-%02d-%02d",$outfile, $year+1900, $mon+1, $mday, $hour-1);
        copy($outfile, $newFileName )or die "File cannot be copied.";

        open $out, '>', $outfile or die "output file open failed";
        $out->autoflush;
        $flip = 1;
			}else{
				open $out, '>', $outfile or die "output file open failed";
        $out->autoflush;
			}
    }

		while (<$fh>) {
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
        if($min % $interval == 0 && $sec == 0 && $flip == 0){
          last;
        }
        my $line = $_;
        my $time = time;
        my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $time;
        $date .= sprintf ".%03d", ($time - int($time))*1000;
        $line =~ s/^\[.*?\]/[$date]/g;
        if ($line =~ /^\[/) {
                if ($prev) {
                        print $out $prev;
                }
                $linecnt++;
                if ($linecnt % $rate == 0) {
                        my $elapsed = time - $start;
                        my $sleptFor = 1 - $elapsed;
                        if ($sleptFor > 0) {
                                select(undef, undef, undef, $sleptFor);
                        }
                        $start = time;
                }
                $prev = $line;
        } else {
                $prev .= $line;
        }
  }
  if($prev){print $out $prev;}

  close $fh;
  close $out;
  $fh = undef;
  $prev = undef;
  $linecnt = 0;
  $fcnt++;
}
