
package Outthentic::Story;

use strict;
use base 'Exporter';
use Outthentic::DSL;

our @EXPORT = qw{ 

    new_story end_of_story 

    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_stdout

    dsl captures capture

    run_story apply_story_vars story_var

    do_perl_file

    ignore_story_err

    project_root_dir

    test_root_dir

};

our @stories = ();

sub new_story {
    
    push @stories, {
        story_vars => {},
        props => { ignore_story_err => 0 , dsl => Outthentic::DSL->new() },
    };

}

sub end_of_story {

    if (debug_mod12()){
        Test::More::ok(1,"end of story: ".(get_prop('story')));
    }
    delete $stories[-1];

}

sub _story {
    @stories[-1];
}

sub get_prop {

    my $name = shift;

    _story()->{props}->{$name};
    
}

sub set_prop {

    my $name = shift;
    my $value = shift;

    _story()->{props}->{$name} =  $value;
    
}

sub project_root_dir {
    get_prop('project');
}

sub test_root_dir {
    get_prop('test_root_dir');
}

sub ignore_story_err {

    my $val = shift;
    my $rv;

    if (defined $val){
        set_prop('ignore_story_err',$val);
    } else {
        $rv = get_prop('ignore_story_err');
    }
    $rv;
}


sub debug_mod1 {

    get_prop('debug') == 1
}

sub debug_mod2 {

    get_prop('debug') == 2
}

sub debug_mod12 {

    debug_mod1() or debug_mod2()
}


sub set_stdout {
    set_prop('my_stdout', shift());
}

sub dsl {
    get_prop('dsl')
}

sub captures {

    dsl()->{captures}
}

sub capture {
    dsl()->{captures}->[0]
}


sub run_story {

    my $path = shift;
    my $story_vars = shift || {};

    $main::story_vars = $story_vars;


    my $test_root_dir = get_prop('test_root_dir');
    my $project_root_dir = get_prop('project_root_dir');

    my $test_file = "$test_root_dir/$project_root_dir/modules/$path/story.d";

    die "test file: $test_file does not exist" unless -e $test_file;

    if (debug_mod12()){
        Test::More::ok(1,"run downstream story: $path"); 
    }

    do_perl_file($test_file);
    
}

sub do_perl_file {

    my $file = shift;

    {
    package main;
    my $return;
    unless ($return = do $file) {
        die "couldn't parse $file: $@" if $@;
    }
    }
    return 1;
}


sub apply_story_vars {

    set_prop( story_vars => $main::story_vars );
}

sub story_var {

    my $name = shift;
    get_prop( 'story_vars' )->{$name};

}


1;

__END__

