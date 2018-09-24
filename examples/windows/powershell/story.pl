my $dir = story_dir();

if (os() eq 'windows'){
  system("powershell -executionPolicy bypass	-file $dir\\cmd.ps1") == 0 or die "powershell command failed";
} else {
  print("Hello, World!");
}

