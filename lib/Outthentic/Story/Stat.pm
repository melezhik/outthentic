package Outthentic::Story::Stat;
use strict;

my @stories;
my $current;

sub current {

  my $class = shift;
  $current || {}; # we return "fake" current for upstream stories

}

sub all {
  my $class = shift;
  @stories
}

sub failures {
  my $class = shift;
  grep { $_->{status} == 0  } $class->all
}

sub new_story {

  # gets called in Outthentic::Story::run_story 
  # for downstream stories only
  my $class = shift;
  my $data = shift;
  push @stories, { vars => {} , %$data , status => 1 };
  $current = $stories[-1];

}

sub add_check_stat {

  my $class = shift;
  my $data = shift;

  push @{$class->current->{check_stat}}, $data;

}

sub set_stdout {

  my $class = shift;
  my $stdout = shift;

  $class->current->{stdout} = $stdout;

}

sub set_scenario_status {

  my $class    = shift;
  my $status  = shift;

  $class->current->{scenario_status} = $status;

}

sub set_status {

  my $class    = shift;
  my $status  = shift;

  $class->current->{status} = $status;

}

1;


