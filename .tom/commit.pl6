#!perl6

my $msg = prompt("enter commit message: ");

bash "git commit -a -m '$msg'";
