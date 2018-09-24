my $project_root_dir = project_root_dir();
print `cd $project_root_dir/../examples/comments && strun --nocolor --purge-cache --debug 0`;
