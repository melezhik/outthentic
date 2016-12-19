package Outthentic::Story::Stat;
use strict;

my @stories;
my $current;

sub current {

  my $self = shift;

  $current || {}; # we return "fake" current for upstream stories

}

sub all {
  @stories
}

sub new_story {

  # gets called in Outthentic::Story::run_story 
  # for downstream stories only
  my $self = shift;
  my $data = shift;
  push @stories, { vars => {} , %$data };
  $current = $stories[-1];

}

sub add_check_stat {

  my $self = shift;
  my $data = shift;

  push @{$self->current->{check_stat}}, $data;

}

sub set_stdout {

  my $self = shift;
  my $stdout = shift;

  $self->current->{stdout} = $stdout;

}

sub set_scenario_status {

  my $self    = shift;
  my $status  = shift;

  $self->current->{scenario_status} = $status;

}

1;


