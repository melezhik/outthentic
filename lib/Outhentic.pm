package Outhentic;

our $VERSION = '0.00001';

package main;

use strict;
use Test::More;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Outhentic::Story;

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
        diag "stdout saved to $content_file" if debug_mod12();

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

        diag "stdout saved to $content_file" if debug_mod12();

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

sub populate_context {

    return if context_populated();

    my $data = shift;
    my $i = 0;

    my $context = [];

    for my $l ( split /\n/, $data ){
        chomp $l;
        $i++;
        $l=":blank_line" unless $l=~/\S/;
        push @$context, [$l, $i];
    }

    set_prop('context',$context);
    set_prop('context_local',$context);

    diag("context populated") if debug_mod2();

    set_prop(context_populated => 1);

}

sub check_line {

    my $pattern = shift;
    my $check_type = shift;
    my $message = shift;
    my $status = 0;


    reset_captures();
    my @captures;

    populate_context( run_story_file() );

    diag("lookup $pattern ...") if debug_mod2();

    my @context         = @{get_prop('context')};
    my @context_local   = @{get_prop('context_local')};
    my @context_new     = ();

    if ($check_type eq 'default'){
        for my $c (@context_local){
            my $ln = $c->[0]; my $next_i = $c->[1];
            if ( index($ln,$pattern) != -1){
                $status = 1;
                push @context_new, $context[$next_i];
            }
        }
    }elsif($check_type eq 'regexp'){
        for my $c (@context_local){
            my $re = qr/$pattern/;
            my $ln = $c->[0]; my $next_i = $c->[1];

            my @foo = ($ln =~ /$re/g);

            if (scalar @foo){
                push @captures, [@foo];
                $status = 1;
                push @context_new, $context[$next_i];
            }
        }
    }else {
        die "unknown check_type: $check_type";
    }

    ok($status,$message);


    if (debug_mod2()){
        my $k=0;
        for my $ce (@captures){
            $k++;
            diag "captured item N $k";
            for  my $c (@{$ce}){
                diag("\tcaptures: $c");
            }
        }
    }

    set_prop( captures => [ @captures ] );

    if (in_block_mode()){
        set_prop( context_local => [@context_new] );
    }

    return

}


sub header {

    if (debug_mod12()) {

        my $project = get_prop('project_root_dir');
        my $story = get_prop('story');
        my $story_file = get_prop('story_file');
        my $debug = get_prop('debug');
        my $ignore_story_err = ignore_story_err();

        ok(1, "project: $project");
        ok(1, "story: $story");
        ok(1, "debug: $debug");
        ok(1, "ignore story errors: $ignore_story_err");
    }
}

sub generate_asserts {

    my $filepath_or_array_ref = shift;
    my $write_header = shift;

    header() if $write_header;

    my @ents;
    my @ents_ok;
    my $ent_type;

    if ( ref($filepath_or_array_ref) eq 'ARRAY') {
        @ents = @$filepath_or_array_ref
    }else{
        return unless $filepath_or_array_ref;
        open my $fh, $filepath_or_array_ref or die $!;
        while (my $l = <$fh>){
            push @ents, $l
        }
        close $fh;
    }



    ENTRY: for my $l (@ents){

        chomp $l;
        diag $l if runner_debug();

        next ENTRY unless $l =~ /\S/; # skip blank lines

        if ($l=~ /^\s*#(.*)/) { # skip comments
            next ENTRY;
        }

        if ($l=~ /^\s*begin:\s*$/) { # begin: block marker
            diag("begin: block") if debug_mod2();
            set_block_mode();
            next ENTRY;
        }
        if ($l=~ /^\s*end:\s*$/) { # end: block marker
            unset_block_mode();
            populate_context( run_story_file() );
            diag("end: block") if debug_mod2();
            set_prop( context_populated => 0); # flush current context
            next ENTRY;
        }

        if ($l=~/^\s*code:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'code';
                 next ENTRY; # this is multiline, hold this until last line \ found
            }else{
                undef $ent_type;
                handle_code($code);
            }
        }elsif($l=~/^\s*generator:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'generator';
                 next ENTRY; # this is multiline, hold this until last line \ found
            }else{
                undef $ent_type;
                handle_generator($code);
            }

        }elsif($l=~/^\s*regexp:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $re=$1;
            undef $ent_type;
            handle_regexp($re);
        }elsif(defined($ent_type)){
            if ($l=~s/\\\s*$//) {
                push @ents_ok, $l;
                next ENTRY; # this is multiline, hold this until last line \ found
             }else {

                no strict 'refs';
                my $name = "handle_"; $name.=$ent_type;
                push @ents_ok, $l;
                &$name(\@ents_ok);

                undef $ent_type;
                @ents_ok = ();

            }
       }else{
            s{#.*}[], s{\s+$}[], s{^\s+}[] for $l;
            undef $ent_type;
            handle_plain($l);
        }
    }

    die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);

}

sub handle_code {

    my $code = shift;

    unless (ref $code){
        eval $code;
        die "code entry eval perl error, code:$code , error: $@" if $@;
        diag "handle_code OK. $code" if runner_debug();
    } else {
        my $code_to_eval = join "\n", @$code;
        eval $code_to_eval;
        die "code entry eval error, code:$code_to_eval , error: $@" if $@;
        diag "handle_code OK. multiline. $code_to_eval" if runner_debug();
    }

}

sub handle_generator {

    my $code = shift;
    unless (ref $code){
        my $arr_ref = eval $code;
        die "generator entry eval error, code:$code , error: $@" if $@;
        diag "handle_generator OK. $code" if runner_debug();
        generate_asserts($arr_ref,0);
    } else {
        my $code_to_eval = join "\n", @$code;
        my $arr_ref = eval $code_to_eval;
        die "generator entry eval error, code:$code_to_eval , error: $@" if $@;
        diag "handle_generator OK. multiline. $code_to_eval" if runner_debug();
        generate_asserts($arr_ref,0);
    }

}

sub handle_regexp {

    my $re = shift;

    my $story = get_prop('story');

    my $message = in_block_mode() ? "$story stdout matches the | $re" : "$story stdout matches the $re";
    check_line($re, 'regexp', $message);
    diag "handle_regexp OK. $re" if runner_debug();

}

sub handle_plain {

    my $l = shift;

    my $story = get_prop('story');

    my $message = in_block_mode() ? "$story stdout has | $l" : "$story stdout has $l";
    check_line($l, 'default', $message);
    diag "handle_plain OK. $l" if runner_debug();
}


1;


__END__

=head1 SYNOPSIS

Print something into stdout and test

=head1 Documentation

Please follow github pages  - https://github.com/melezhik/outhentic

=head1 AUTHOR

Aleksei Melezhik

=head1 COPYRIGHT

Copyright 2015 Alexey Melezhik.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

