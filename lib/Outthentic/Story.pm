
package Outthentic::Story;

use strict;
use base 'Exporter';
use Outthentic::DSL;
use File::ShareDir;
use JSON;

our @EXPORT = qw{ 

    new_story end_of_story set_story

    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_stdout get_stdout stdout_file

    dsl captures capture stream match_lines

    run_story apply_story_vars story_var

    do_perl_hook

    do_ruby_hook

    ignore_story_err

    project_root_dir

    test_root_dir

    host
};

our @stories = ();

sub new_story {
    

    my $self = {
        ID =>  int(rand(1000)),
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

    my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $ruby_run_opts = "-I $ruby_lib_dir -r outthentic -I "._story_cache_dir();

    if  (-f get_prop('story_dir')."/common.rb"){
      $ruby_run_opts.= " -I ".(get_prop('story_dir')); 
      $ruby_run_opts.= " -r common"; 
    }

    get_prop('dsl')->{languages}->{ruby} = $ruby_run_opts; 

    get_prop('dsl')->{cache_dir} = _story_cache_dir();

    _mk_ruby_glue_file();

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

  _story_cache_dir()."/std.out"

}

sub _story_cache_dir {

  my $cache_dir = test_root_dir()."/story-"._story_id();
  system("mkdir -p $cache_dir");
  $cache_dir;

}

sub _ruby_glue_file {
  _story_cache_dir()."/glue.rb";
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


sub _mk_ruby_glue_file {

    open RUBY_GLUE, ">", _ruby_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $test_root_dir = test_root_dir();
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $json = JSON->new->allow_nonref;

    my $cache_dir = _story_cache_dir;

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

    def stdout_file
      '$stdout_file' 
    end

CODE

    close RUBY_GLUE,;

}

sub do_ruby_hook {

    my $file = shift;


    my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $cmd = "ruby -I $ruby_lib_dir -r outthentic -I "._story_cache_dir();

    if  (-f get_prop('story_dir')."/common.rb"){
      $cmd.= " -I ".(get_prop('story_dir')); 
      $cmd.= " -r common"; 
    }

    $cmd.=" $file";

    if (debug_mod12()){
        Test::More::note("do_ruby_hook: $cmd"); 
    }


    my $rand = int(rand(1000));

    my $st = system("$cmd 2>"._story_cache_dir()."/$rand.err 1>"._story_cache_dir()."/$rand.out");

    if($st != 0){
      die "do_ruby_hook failed. \n see "._story_cache_dir()."/$rand.err for details";
    }

    my $out_file = _story_cache_dir()."/$rand.out";

    open RUBY_HOOK_OUT, $out_file or die "can't open RUBY_HOOK_OUT file $out_file to read!";

    my @out = <RUBY_HOOK_OUT>;

    close RUBY_HOOK_OUT;

    my $story_vars;

    for my $l (@out) {

      next if $l=~/#/;

      ignore_story_err($1) if $l=~/ignore_story_err:\s+(\d)/;
      
      if ($l=~s/story_vars:.*// .. $l=~s/story_vars:.*//){
        $story_vars.=$l;    
      }

      if ($l=~/story:\s+(\S+)/){
        my $path = $1;
        if (debug_mod12()){
            Test::More::note("run downstream story from ruby hook"); 
        }
        run_story($path, decode_json($story_vars||{}));
      }
    }

    return 1;
}


sub apply_story_vars {

    set_prop( story_vars => $main::story_vars );

    open STORY_VARS, ">", (_story_cache_dir())."/variables.json" 
    or die "can't open ".(_story_cache_dir())."/variables.json write: $!";

    print STORY_VARS encode_json($main::story_vars);

    close STORY_VARS;
}

sub story_var {

    my $name = shift;

    get_prop( 'story_vars' )->{$name};

}


1;

__END__

