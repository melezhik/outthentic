package Outthentic::Glue::Perl;

1;

package main;

use glue;
use strict;

use JSON;

our $VARIABLES;
our $CAPTURES;

sub config {

  my $path = cache_dir()."/config.json";

  open CONF, $path or die "can't open file $path to read: $!";
  my $data = join "", <CONF>;
  close CONF;
  
  my $json = JSON->new;
  return $json->decode($data); 

}


sub captures {

  return $CAPTURES if $CAPTURES;

  my $path = cache_dir()."/captures.json";
  open CAPT, $path or die "can't open file $path to read: $!";
  my $data = join '', <CAPT>;
  close CAPT;

  my $json = JSON->new;
  $CAPTURES = $json->decode($data);

  return $CAPTURES; 

}

sub capture {
    captures()->[0]
}

sub story_variables {

  return $VARIABLES if $VARIABLES;

  my $path = cache_dir()."/variables.json";
  open VARS, $path or die "can't open file $path to read: $!";
  my $data = join '', <VARS>;
  close VARS;

  my $json = JSON->new;
  $VARIABLES = $json->decode($data);

  return $VARIABLES; 

}


sub story_var  {
  story_variables()->{shift()}
}

1;

