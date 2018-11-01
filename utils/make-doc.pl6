bash "rm -rf README.pod";
bash "/root/perl5/perlbrew/perls/perl-5.28.0/bin/markdown2pod README.md > README.pod";
bash 'perl -n -e "print unless /__END__/ .. eof()" lib/Outthentic.pm > /tmp/Outthentic.pm';
bash '(echo __END__; echo; echo; ) >> /tmp/Outthentic.pm';
bash 'cat README.pod >> /tmp/Outthentic.pm';
bash 'diff -u lib/Outthentic.pm /tmp/Outthentic.pm; echo';
bash 'cp /tmp/Outthentic.pm lib/Outthentic.pm';
bash "rm -rf README.pod";

