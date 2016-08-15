start_with=$1;
start_with=${start_with:-examples};
find $start_with -name story.rb -or -name story.bash -or -name story.pl -execdir pwd \; | grep -v modules/ | perl -n -e 'chomp; s{.*examples/}[]; push @foo, "strun --root examples --story $_"; END { print join " && " , @foo }' | bash
