#! /usr/bin/env perl

use File::Find;
use Cwd;

my $root = getcwd();

find( { wanted => \&wanted, no_chdir => 1 } , $ARGV[0]||'examples/');

sub wanted  {

  return unless /story\.(pl|rb|bash|py)$/ or /meta\.txt$/;

  return if /modules\//;

  (my $dir = $File::Find::dir)=~s{examples/}{};
 
  my $cmd = "strun --purge-cache --root ./examples --story $dir";
  (system($cmd) == 0)  or die "$cmd failed";

}


