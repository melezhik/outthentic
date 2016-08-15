#! /usr/bin/env perl

use File::Find;

find( { wanted => \&wanted, no_chdir => 1 } , $ARGV[0]||'examples');

sub wanted  {

  return unless /story\.(pl|rb|bash)/;
  return if /modules\//;
  (my $story_dir = $File::Find::dir)=~s{.*examples/}[];

  print "$story_dir\n";

  (system("strun --root examples/ --story $story_dir") == 0)  or die "strun --root examples/ --story $story_dir failed";

}


