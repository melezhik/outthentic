#!perl6

bash "perl Makefile.PL";
bash "make test";
bash "perl run-test.pl";
