
package Outthentic::Story;

use strict;
use base 'Exporter';
use Outthentic::DSL;
use File::ShareDir;

our @EXPORT = qw{ 

    new_story end_of_story 

    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_stdout get_stdout stdout_file

    dsl captures capture stream match_lines

    run_story apply_story_vars story_var

    do_perl_file

    do_ruby_file

    ignore_story_err

    project_root_dir

    test_root_dir

    host
};

our @stories = ();

sub new_story {
    
    push @stories, {
        ID =>  int(rand(1000)),
        story_vars => {},
        props => { ignore_story_err => 0 , dsl => Outthentic::DSL->new() },
    };

}

sub end_of_story {

    if (debug_mod12()){
        Test::More::note("end of story: ".(get_prop('story')));
    }
    delete $stories[-1];

}

sub _story {
    @stories[-1];
}

sub _story_id {
  _story()->{ID};
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
    get_prop('project_root_dir');
}

sub test_root_dir {
    get_prop('test_root_dir');
}

sub host {
    get_prop('host');
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

    my $line = shift;
    open FSTDOUT, ">>", stdout_file() or die $!;
    print FSTDOUT $line, "\n";
    close FSTDOUT;

}

sub get_stdout {

    return unless -f stdout_file();

    my $data;

    open FSTDOUT, stdout_file() or die $!;
    my $data = join "",  <FSTDOUT>;
    close FSTDOUT;
    $data;
}

sub stdout_file {

  _story_glue_dir()."/std.out"

}

sub _story_glue_dir {

  my $glue_dir = test_root_dir()."/story-"._story_id();
  system("mkdir -p $glue_dir");
  $glue_dir;

}

sub _ruby_glue_file {
  _story_glue_dir()."/glue.rb";
}

sub dsl {
    get_prop('dsl')
}

sub stream {
    dsl()->stream
}

sub captures {

    dsl()->{captures}
}

sub capture {
    dsl()->{captures}->[0]
}

sub match_lines {

    dsl()->{match_lines}
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
        Test::More::note("run downstream story: $path"); 
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


sub do_ruby_file {

    my $file = shift;

    open RUBY_GLUE, ">", _ruby_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $test_root_dir = test_root_dir();
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    print RUBY_GLUE <<"CODE";

    def debug_mod12 
      '$debug_mod12'
    end

    def test_root_dir
      '$test_root_dir' 
    end

    def project_root_dir
      '$project_root_dir' 
    end

    def stdout_file
      '$stdout_file' 
    end

CODE

    close RUBY_GLUE,;

    my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $cmd = "ruby -I ".$ruby_lib_dir." -I ".(_story_glue_dir())." $file";

    if (debug_mod12()){
        Test::More::note("do_ruby_file: $cmd"); 
    }

    for my $l ( split /\n/, `$cmd`){
      print "$l\n";
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

