#! /usr/bin/env perl

use File::Find;
use Cwd;

my $root = getcwd();

if ($^O  =~ 'MSWin'){
  find( { wanted => \&wanted, no_chdir => 1 } , 'examples/');
} else {
  my $cmd = "cd examples && strun --recurse --purge-cache  --format production";
  (system($cmd) == 0)  or die "$cmd failed";
}

my %seen;

sub wanted  {

  return unless $File::Find::name=~/(story|hook)\.(pl|rb|bash|py|pm|ps1)$/ or /meta\.txt$/;

  return unless -e $File::Find::dir."/windows.test";

  (my $dir = $File::Find::dir)=~s{examples/}{};

  return if $dir=~/modules/;

  return if $seen{$dir};
  
  my $cmd = "cd examples && strun --purge-cache --story $dir --format production";

  (system($cmd) == 0)  or die "$cmd failed";

  $seen{$dir}++;

}


