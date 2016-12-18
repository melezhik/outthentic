run_story('00');
run_story('01', { foo => 'hello world'});
run_story('02', { FOO_THING => 'FOO_VALUE!!!' });


print STDERR Dumper([@Outthentic::STORY_STAT]);
