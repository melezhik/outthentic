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

sub wanted  {

  return unless /story\.(pl|rb|bash|py|pm)$/ or /meta\.txt$/;

  return if /modules\//;

  return unless ( -e $File::Find::dir."\\windows.test" or $File::Find::dir =~/windows/ );

  (my $dir = $File::Find::dir)=~s{examples/}{};
  
  my $cmd = "cd examples && strun --purge-cache --story $dir --format production";

  (system($cmd) == 0)  or die "$cmd failed";

}


