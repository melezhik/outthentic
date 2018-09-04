my $dir = story_dir();

system("powershell -executionPolicy bypass	-file $dir\\cmd.ps1") == 0 or die "powershell command failed";