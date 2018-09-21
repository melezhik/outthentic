#! /usr/bin/env perl

use File::Find;
use Cwd;

my $root = getcwd();

find( { wanted => \&wanted, no_chdir => 1 } , $ARGV[0]||'examples/');

sub wanted  {

  return unless /story\.(pl|rb|bash|py)$/ or /meta\.txt$/;

  return if /modules\//;

  return if $^O  =~ 'MSWin' and ! ( -e $File::Find::dir."\\windows.test" or $File::Find::dir =~/windows/ );
  return if $^O  !~ 'MSWin' and $File::Find::dir =~/windows/;

  (my $dir = $File::Find::dir)=~s{examples/}{};
  
  my $cmd = $^O  =~ 'MSWin' ? "cd examples && strun --purge-cache --story $dir --nocolor --format default" : "cd examples && strun --purge-cache --story $dir --format production";
  (system($cmd) == 0)  or die "$cmd failed";

}


