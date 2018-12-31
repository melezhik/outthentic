my $envvars = config()->{envvars};
my @envvars;

if ($envvars){


  for my $e (keys %{$envvars}){
    push @envvars, "export $e=".($envvars->{$e})."; ";
  }
 
}

run_story("bash-command", { envvars => join " ", @envvars });


