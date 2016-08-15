#! /usr/bin/env perl

use File::Find;
use Cwd;

my $root = getcwd();

find( { wanted => \&wanted, no_chdir => 1 } , $ARGV[0]||'examples/');

sub wanted  {

  return unless /story\.(pl|rb|bash)$/;

  return if /modules\//;

  (my $dir = $File::Find::dir)=~s{examples/}{};
 
  (system("strun --root ./examples --story $dir") == 0)  or die "strun --root ./examples --story $dir failed";

}


