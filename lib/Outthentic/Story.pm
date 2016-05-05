
package Outthentic::Story;

use strict;
use base 'Exporter';
use Outthentic::DSL;
use File::ShareDir;
use JSON;
use Carp;

our @EXPORT = qw{ 

    new_story end_of_story set_story story_cache_dir

    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_stdout get_stdout stdout_file

    dsl captures capture stream match_lines

    run_story apply_story_vars story_var

    do_perl_hook

    do_ruby_hook

    do_bash_hook

    ignore_story_err

    project_root_dir

    test_root_dir

    host
};

our @stories = ();

sub new_story {
    

    my $self = {
        ID =>  scalar(@stories),
        story_vars => {},
        props => { ignore_story_err => 0 , dsl => Outthentic::DSL->new() },
    };

    push @stories, $self;

    1;

}

sub end_of_story {

    if (debug_mod12()){
        Test::More::note("end of story: ".(get_prop('story')));
    }
    delete $stories[-1];

}

sub set_story {

    my $dist_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $ruby_run_opts = "-I $dist_lib_dir -r outthentic -I ".story_cache_dir();

    get_prop('dsl')->{languages}->{ruby} = $ruby_run_opts; 

    get_prop('dsl')->{cache_dir} = story_cache_dir();

    my $bash_run_opts = "source "._bash_glue_file()." && source $dist_lib_dir/outthentic.bash";

    get_prop('dsl')->{languages}->{ruby} = $ruby_run_opts; 

    get_prop('dsl')->{languages}->{bash} = $bash_run_opts; 

    _make_cache_dir();

    _mk_perl_glue_file();

    _mk_ruby_glue_file();

    _mk_bash_glue_file();

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

  story_cache_dir()."/std.out"

}

sub _make_cache_dir {

  my $cache_dir = test_root_dir()."/story-"._story_id();

  if (debug_mod12()){
    Test::More::note("make cache dir: $cache_dir");
  }
  system("rm -rf $cache_dir");
  system("mkdir -p $cache_dir");
}

sub story_cache_dir {
  test_root_dir()."/story-"._story_id();
}

sub _perl_glue_file {
  story_cache_dir()."/glue.pm";
}

sub _ruby_glue_file {
  story_cache_dir()."/glue.rb";
}

sub _bash_glue_file {
  story_cache_dir()."/glue.bash";
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

    my $story_module = "$test_root_dir/$project_root_dir/modules/$path/story.d";

    die "story module file $story_module does not exist" unless -e $story_module;

    if (debug_mod12()){
        Test::More::note("run downstream story: $path");
        for my $k (keys %{$story_vars}){
          my $v = $story_vars->{$k};
          Test::More::note("downstream story var: $k => $v"); 
        } 
    }

    {
      package main;
      unless (do $story_module) {
        die "couldn't parse story module file $story_module: $@" if $@;
      }
    }

}

sub do_perl_hook {

    my $hook_file = shift;

    {
      package main;
      unless (do $hook_file) {
        die "couldn't parse perl hook file $hook_file: $@" if $@;
      }
    }

    return 1;
}


sub _mk_perl_glue_file {

    open PERL_GLUE, ">", _perl_glue_file() or confess "can't create perl glue file ".(_perl_glue_file())." : $!";

    my $test_root_dir = test_root_dir();
    my $story_dir = get_prop('story_dir');
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();
    my $cache_dir = story_cache_dir;

    print PERL_GLUE <<"CODE";

package glue;
1;

package main;
use strict;
  
    sub debug_mod12 {
      $debug_mod12
    }

    sub test_root_dir {
      '$test_root_dir'
    }

    sub project_root_dir {
      '$project_root_dir' 
    }

    sub  cache_dir {
      '$cache_dir'
    }

    sub story_dir {
      '$story_dir'
    }

1;

CODE

    close PERL_GLUE,;

}

sub _mk_ruby_glue_file {

    open RUBY_GLUE, ">", _ruby_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $test_root_dir = test_root_dir();
    my $story_dir = get_prop('story_dir');
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $cache_dir = story_cache_dir;

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

    def cache_dir
      '$cache_dir'
    end

    def story_dir
      '$story_dir'
    end

    def stdout_file
      '$stdout_file' 
    end

CODE

    close RUBY_GLUE,;

}

sub _mk_bash_glue_file {


    my $story_dir = get_prop('story_dir');

    open BASH_GLUE, ">", _bash_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $test_root_dir = test_root_dir();
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $cache_dir = story_cache_dir;

    print BASH_GLUE <<"CODE";

    debug_mod=debug_mod12 

    test_root_dir=$test_root_dir

    project_root_dir=$project_root_dir

    cache_dir=$cache_dir

    story_dir=$story_dir

    stdout_file=$stdout_file 

CODE

    close BASH_GLUE,;

}

sub do_ruby_hook {

    my $file = shift;

    my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $cmd = "ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir();

    $cmd.=" $file";

    if (debug_mod12()){
        Test::More::note("do_ruby_hook: $cmd"); 
    }


    my $rand = int(rand(1000));

    my $st = system("$cmd 2>".story_cache_dir()."/$rand.err 1>".story_cache_dir()."/$rand.out");

    if($st != 0){
      die "do_ruby_hook failed. \n see ".story_cache_dir()."/$rand.err for details";
    }

    my $out_file = story_cache_dir()."/$rand.out";

    open RUBY_HOOK_OUT, $out_file or die "can't open RUBY_HOOK_OUT file $out_file to read!";

    my @out = <RUBY_HOOK_OUT>;

    close RUBY_HOOK_OUT;

    my $story_vars_json;

    for my $l (@out) {

      next if $l=~/#/;

      ignore_story_err($1) if $l=~/ignore_story_err:\s+(\d)/;
      
      if ($l=~s/story_var_json_begin.*// .. $l=~s/story_var_json_end.*//){
        $story_vars_json.=$l;    
        next;
      }


      if ($l=~/story:\s+(\S+)/){

        my $path = $1;

        if (debug_mod12()){
            Test::More::note("run downstream story from ruby hook"); 
        }

        run_story($path, decode_json($story_vars_json||{}));
        $story_vars_json = undef;

        }
    }

    return 1;
}

sub do_bash_hook {

    my $file = shift;

    my $bash_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $cmd = "source "._bash_glue_file()." && source $bash_lib_dir/outthentic.bash";

    $cmd.=" && source $file";

    $cmd="bash -c '$cmd'";

    if (debug_mod12()){
        Test::More::note("do_bash_hook: $cmd"); 
    }


    my $rand = int(rand(1000));

    my $st = system("$cmd 2>".story_cache_dir()."/$rand.err 1>".story_cache_dir()."/$rand.out");

    if($st != 0){
      die "do_bash_hook failed. \n see ".story_cache_dir()."/$rand.err for details";
    }

    my $out_file = story_cache_dir()."/$rand.out";

    open HOOK_OUT, $out_file or die "can't open HOOK_OUT file $out_file to read!";

    my @out = <HOOK_OUT>;

    close HOOK_OUT;

    my %story_vars_bash = ();

    for my $l (@out) {

      next if $l=~/#/;

      ignore_story_err($1) if $l=~/ignore_story_err:\s+(\d)/;
      
      if ($l=~/story_var_bash:\s+(\S+)\s+(.*)/){
        $story_vars_bash{$1}=$2;
        #warn %story_vars_bash;
        next;    
      }

      if ($l=~/story:\s+(\S+)/){
        my $path = $1;
        if (debug_mod12()){
            Test::More::note("run downstream story from bash hook"); 
        }
        run_story($path, {%story_vars_bash});
        %story_vars_bash = ();
      }
    }

    return 1;

}


sub apply_story_vars {

    set_prop( story_vars => $main::story_vars );

    open STORY_VARS, ">", (story_cache_dir())."/variables.json" 
    or die "can't open ".(story_cache_dir())."/variables.json write: $!";

    print STORY_VARS encode_json($main::story_vars);

    close STORY_VARS;

    open STORY_VARS, ">", (story_cache_dir())."/variables.bash" 
    or die "can't open ".(story_cache_dir())."/variables.bash write: $!";

    for my $name (keys %{$main::story_vars} ){
      print STORY_VARS "$name=".$main::story_vars->{$name}."\n";
    }

    close STORY_VARS;

}

sub story_var {

    my $name = shift;

    get_prop( 'story_vars' )->{$name};

}


1;

__END__

