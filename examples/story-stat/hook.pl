my $stat = run_story('01', { foo => 'hello world'});

set_stdout("story status: $stat->{status}");
set_stdout("story path: $stat->{path}");
set_stdout("story vars: $stat->{vars}->{foo}");
set_stdout("check0 status: $stat->{check_stat}->[0]->{status}");
set_stdout("check0 message: $stat->{check_stat}->[0]->{message}");
