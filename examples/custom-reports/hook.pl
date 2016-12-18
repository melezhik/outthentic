run_story('00');
run_story('01', { foo => 'hello world'});
run_story('02', { FOO_THING => 'FOO_VALUE!!!' });


#print STDERR Dumper([@Outthentic::STORY_STAT]);

print STDERR "story | status |  message \n";

for my $s (@Outthentic::STORY_STAT){
    my @s = ($s->[0],( $s->[1] ? "OK" : "FAILED" ), $s->[2]);
    print STDERR join " | ", map {chomp $_; $_}  @s;
    print STDERR "\n";
}
