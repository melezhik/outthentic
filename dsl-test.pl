#! /usr/bin/env perl

use File::Find;
use Cwd;

my $root = getcwd();

find( { wanted => \&wanted, no_chdir => 1 } , $ARGV[0]||'dsl-test/');

sub wanted  {

  return unless /story\.(pl|rb|bash)$/ or /meta\.txt$/;

  return if /modules\//;

  (my $dir = $File::Find::dir)=~s{dsl-test/}{};

  my $cmd = "strun --purge-cache --root ./dsl-test --story $dir --format production";
  (system($cmd) == 0)  or die "$cmd failed";

}


