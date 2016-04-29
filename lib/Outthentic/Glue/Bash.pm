package Outthentic::Glue::Bash;

use base 'Exporter';
use JSON;
use strict;

our @EXPORT = qw{
  config
};

sub config {

  my $path = $ARGV[0];
  my $name = $ARGV[1];

  open CONF, $path or die "can't open file $path to read: $!";
  my $data = join "", <CONF>;
  close CONF;
  
  my $json = JSON->new;
  my $conf = $json->decode($data); 

  for my $n (split /\./, $name){
    $conf = $conf->{$n};    
  }

  print $conf;

}

sub variable {

  my $path = $ARGV[0];
  my $name = $ARGV[1];

  open VARS, $path or die "can't open file $path to read: $!";
  my $data = join "", <VARS>;
  close VARS;
  
  my $json = JSON->new;
  my $conf = $json->decode($data); 

  my $val;

  for my $n (split /\./, $name){
    $val = $conf->{$n};    
  }

  print $val;

}

1;

