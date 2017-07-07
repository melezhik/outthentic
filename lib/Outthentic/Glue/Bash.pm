package Outthentic::Glue::Bash;

use base 'Exporter';
use JSON;
use strict;

our @EXPORT = qw{
  json_var
};

sub json_var {

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

  if ( ref  $conf eq "ARRAY") { 
    my $conf =  join ' ', @$conf ;
    print '(' . $conf . ')';
  } else {
    print $conf;
  }

}

1;
