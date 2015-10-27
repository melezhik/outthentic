package Outthentic;

our $VERSION = '0.0.6';

1;

package main;

use strict;
use Test::More;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Outthentic::Story;

$| = 1;

sub execute_cmd {
    my $cmd = shift;
    diag("execute cmd: $cmd") if debug_mod2();
    (system($cmd) == 0);
}

sub run_story_file {

    return get_prop('stdout') if defined get_prop('stdout');

    my ($fh, $content_file) = tempfile( DIR => get_prop('test_root_dir') );

    if (get_prop('my_stdout')){

        ok(1,"stdout is already set");

        open F, ">", $content_file or die $!;
        print F get_prop('my_stdout');
        close F;
        ok(1, "stdout saved to $content_file");

    }else{

        my $story_file = get_prop('story_file');

        my $st = execute_cmd("perl $story_file 1>$content_file 2>&1 && test -f $content_file");

        if ($st) {
            ok(1, "perl $story_file succeeded");
        }elsif(ignore_story_err()){
            ok(1, "perl $story_file failed, still continue due to ignore_story_err enabled");
        }else{
            ok(0, "perl $story_file succeeded");
            open CNT, $content_file or die $!;
            my $rdata = join "", <CNT>;
            close CNT;
            diag("perl $story_file \n===>\n$rdata");
        }

        ok(1,"stdout saved to $content_file");

    }

    open F, $content_file or die $!;
    my $cont = '';
    $cont.= $_ while <F>;
    close F;

    set_prop( stdout => $cont );

    my $debug_bytes = get_prop('debug_bytes');

    diag `head -c $debug_bytes $content_file` if debug_mod2();

    return get_prop('stdout');
}

sub header {

    if (debug_mod12()) {

        my $project = get_prop('project_root_dir');
        my $story = get_prop('story');
        my $story_type = get_prop('story_type');
        my $story_file = get_prop('story_file');
        my $debug = get_prop('debug');
        my $ignore_story_err = ignore_story_err();

        ok(1, "project: $project");
        ok(1, "story: $story");
        ok(1, "story_type: $story_type");
        ok(1, "debug: $debug");
        ok(1, "ignore story errors: $ignore_story_err");
    }
}

sub generate_asserts {

    my $story_check_file = shift;
    my $show_header = shift;

    header() if $show_header;

    dsl->{debug_mod} = get_prop('debug');
    dsl()->{output} = run_story_file();
    dsl()->generate_asserts($story_check_file);

}

1;


__END__

=head1 SYNOPSIS

Print something into stdout and test

=head1 Documentation

Please follow github pages  - https://github.com/melezhik/outthentic

=head1 AUTHOR

Aleksei Melezhik

=head1 COPYRIGHT

Copyright 2015 Alexey Melezhik.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

