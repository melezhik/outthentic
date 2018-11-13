package Outthentic::Story;

use strict;
use base 'Exporter';
use Outthentic::DSL;
use Outthentic::Story::Stat;
use File::ShareDir;
use JSON;
use Carp;

use File::Path::Tiny;

our @EXPORT = qw{ 

    new_story end_of_story set_story story_cache_dir

    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_stdout get_stdout stdout_file

    dsl captures capture stream match_lines

    run_story apply_story_vars story_var story_vars_pretty

    do_perl_hook

    do_ruby_hook

    do_python_hook

    do_bash_hook

    ignore_story_err

    quit

    outthentic_die

    project_root_dir

    test_root_dir

    cache_root_dir

    host

    dump_os

};

our @stories = ();
our $OS;

sub new_story {
    

    my $self = {
        ID =>  scalar(@stories),
        props => { 
          ignore_story_err => 0 , 
          dsl => Outthentic::DSL->new() , 
          story_vars => {} },
    };

    push @stories, $self;

    1;

}

sub end_of_story {

    if (debug_mod12()){
        main::note("end of story: ".(get_prop('story')));
    }

    delete $stories[-1];

}

sub set_story {

    my $dist_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $ruby_run_cmd;

    if (-f project_root_dir()."/Gemfile" ){
      $ruby_run_cmd  = "cd ".project_root_dir()." && bundle exec ruby -I $dist_lib_dir -r outthentic -I ".story_cache_dir()
    } else {
      $ruby_run_cmd = "ruby -I $dist_lib_dir -r outthentic -I ".story_cache_dir();
    }

    my $python_run_cmd  = "PYTHONPATH=\$PYTHONPATH:".(story_cache_dir()).":$dist_lib_dir python";

    get_prop('dsl')->{languages}->{ruby} = $ruby_run_cmd; 

    get_prop('dsl')->{languages}->{python} = $python_run_cmd; 

    get_prop('dsl')->{cache_dir} = story_cache_dir();

    my $bash_run_opts = "source "._bash_glue_file()." && source $dist_lib_dir/outthentic.bash";

    get_prop('dsl')->{languages}->{ruby} = $ruby_run_cmd; 

    get_prop('dsl')->{languages}->{bash} = $bash_run_opts; 

    _make_cache_dir();

    _mk_perl_glue_file();

    _mk_ruby_glue_file();

    _mk_python_glue_file();

    _mk_bash_glue_file();

    _mk_ps_glue_file();

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


sub test_root_dir { # this one is deprected and exists for back compatibilty, use cache_root_dir instead
    get_prop('cache_root_dir');
}

sub cache_root_dir {
    get_prop('cache_root_dir');
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

  my $cache_dir = cache_root_dir()."/story-"._story_id();

  if (debug_mod12()){
    main::note("make cache dir: $cache_dir");
  }
  File::Path::Tiny::mk($cache_dir) or die "can't create $cache_dir, error: $!";
  File::Path::Tiny::empty_dir($cache_dir) or die "can't empty $cache_dir, error: $!";
}

sub story_cache_dir {
  cache_root_dir()."/story-"._story_id();
}

sub _perl_glue_file {
  story_cache_dir()."/glue.pm";
}

sub _ruby_glue_file {
  story_cache_dir()."/glue.rb";
}

sub _python_glue_file {
  story_cache_dir()."/glue.py";
}

sub _bash_glue_file {
  story_cache_dir()."/glue.bash";
}

sub _ps_glue_file {
  story_cache_dir()."/glue.ps1";
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

    Outthentic::Story::Stat->new_story({
      vars => $story_vars,
      path => $path
    });

    my $cache_root_dir = get_prop('cache_root_dir');

    my $project_root_dir = get_prop('project_root_dir');

    my $story_module = "$cache_root_dir/modules/$path/story.outth";

    die "story module file $story_module does not exist" unless -e $story_module;

    if (debug_mod12()){
        main::note("run downstream story: $path");
        for my $k (keys %{$story_vars}){
          my $v = $story_vars->{$k};
          main::note("downstream story var: $k => $v"); 
        } 
    }

    {
      package main;
      unless (do $story_module) {
        die "couldn't parse story module file $story_module: $@" if $@;
      }
    }

    # return statistic for downstream story just executed
    return Outthentic::Story::Stat->current;
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

sub quit {
  my $msg = shift;
  chomp($msg);
  main::print_story_header();
  main::note("? forcefully exit: $msg"); 
  exit(0);
}

sub outthentic_die {
  my $msg = shift;
  chomp($msg);
  main::print_story_header();
  main::note("!! forcefully die: $msg");
  $main::STATUS = 0;
  exit(1);
}

sub _mk_perl_glue_file {

    open PERL_GLUE, ">", _perl_glue_file() or confess "can't create perl glue file ".(_perl_glue_file())." : $!";

    my $cache_root_dir = cache_root_dir();
    my $story_dir = get_prop('story_dir');
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();
    my $cache_dir = story_cache_dir;

    my $os = _resolve_os();

    print PERL_GLUE <<"CODE";

package glue;
1;

package main;
use strict;
  
    sub debug_mod12 {
      $debug_mod12
    }

    sub cach_root_dir {
      '$cache_root_dir'
    }

    sub test_root_dir {
      '$cache_root_dir'
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

    sub os { '$os' }


1;

CODE

    close PERL_GLUE;

}

sub _mk_ruby_glue_file {

    open RUBY_GLUE, ">", _ruby_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $cache_root_dir = cache_root_dir();
    my $story_dir = get_prop('story_dir');
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $cache_dir = story_cache_dir;

    print RUBY_GLUE <<"CODE";

    def debug_mod12 
      '$debug_mod12'
    end

    def cache_root_dir
      '$cache_root_dir' 
    end

    def test_root_dir
      '$cache_root_dir' 
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

    close RUBY_GLUE;

}

sub _mk_python_glue_file {

    open PYTHON_GLUE, ">", _python_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $cache_root_dir = cache_root_dir();
    my $story_dir = get_prop('story_dir');
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $cache_dir = story_cache_dir;

    print PYTHON_GLUE <<"CODE";

def debug_mod12():
  return $debug_mod12

def cache_root_dir():
  return '$cache_root_dir' 

def test_root_dir():
  return '$cache_root_dir' 

def project_root_dir():
  return '$project_root_dir' 

def cache_dir():
  return '$cache_dir'

def story_dir():
  return '$story_dir'

def stdout_file():
  return '$stdout_file' 

CODE

    close PYTHON_GLUE;

}

sub _mk_bash_glue_file {


    my $story_dir = get_prop('story_dir');

    open BASH_GLUE, ">", _bash_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $cache_root_dir = cache_root_dir();
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $cache_dir = story_cache_dir;

    my $os = _resolve_os();

    print BASH_GLUE <<"CODE";

    debug_mod=debug_mod12 

    test_root_dir=$cache_root_dir

    cache_root_dir=$cache_root_dir

    project_root_dir=$project_root_dir

    cache_dir=$cache_dir

    story_dir=$story_dir

    stdout_file=$stdout_file 

    os=$os

CODE

    close BASH_GLUE;

}

sub _mk_ps_glue_file {

    open PS_GLUE, ">", _ps_glue_file() or die $!;

    my $stdout_file = stdout_file();
    my $cache_root_dir = cache_root_dir();
    my $story_dir = get_prop('story_dir');
    my $project_root_dir = project_root_dir();
    my $debug_mod12 = debug_mod12();

    my $cache_dir = story_cache_dir;

    print PS_GLUE <<"CODE";

    function debug_mod12 {
      '$debug_mod12'
    }

    function cache_root_dir {
      '$cache_root_dir'
    }

    function test_root_dir {
      '$cache_root_dir'
    }

    function project_root_dir {
      '$project_root_dir'
    }

    function cache_dir {
      '$cache_dir'
    }

    function story_dir {
      '$story_dir'
    }

    function stdout_file {
      '$stdout_file'
    }

CODE

    close PS_GLUE;

}

sub do_ruby_hook {

    my $file = shift;

    my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $cmd;

    if (-f project_root_dir()."/Gemfile" ){
      $cmd = "cd ".project_root_dir()." && bundle exec ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $file"
    } else {
      $cmd = "ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $file"
    }

    if (debug_mod12()){
        main::note("do_ruby_hook: $cmd"); 
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

      quit($1) if $l=~/quit:(.*)/;
      outthentic_die($1) if $l=~/outthentic_die:(.*)/;

      ignore_story_err($1) if $l=~/ignore_story_err:\s+(\d)/;
      
      if ($l=~s/story_var_json_begin.*// .. $l=~s/story_var_json_end.*//){
        $story_vars_json.=$l;    
        next;
      }


      if ($l=~/story:\s+(\S+)/){

        my $path = $1;

        if (debug_mod12()){
            main::note("run downstream story from ruby hook"); 
        }

        run_story($path, decode_json($story_vars_json||{}));
        $story_vars_json = undef;

        }
    }

    return 1;
}

sub do_python_hook {

    my $file = shift;

    my $python_lib_dir = File::ShareDir::dist_dir('Outthentic');

    my $cmd  = "PYTHONPATH=\$PYTHONPATH:".(story_cache_dir()).":$python_lib_dir python $file";
  
    if (debug_mod12()){
        main::note("do_python_hook: $cmd"); 
    }


    my $rand = int(rand(1000));

    my $st = system("$cmd 2>".story_cache_dir()."/$rand.err 1>".story_cache_dir()."/$rand.out");

    if($st != 0){
      die "do_python_hook failed. \n see ".story_cache_dir()."/$rand.err for details";
    }

    my $out_file = story_cache_dir()."/$rand.out";

    open PYTHON_HOOK_OUT, $out_file or die "can't open PYTHON_HOOK_OUT file $out_file to read!";

    my @out = <PYTHON_HOOK_OUT>;

    close PYTHON_HOOK_OUT;

    my $story_vars_json;

    for my $l (@out) {

      next if $l=~/#/;

      quit($1) if $l=~/quit:(.*)/;
      outthentic_die($1) if $l=~/outthentic_die:(.*)/;

      ignore_story_err($1) if $l=~/ignore_story_err:\s+(\d)/;
      
      if ($l=~s/story_var_json_begin.*// .. $l=~s/story_var_json_end.*//){
        $story_vars_json.=$l;    
        next;
      }


      if ($l=~/story:\s+(\S+)/){

        my $path = $1;

        if (debug_mod12()){
            main::note("run downstream story from python hook"); 
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
        main::note("do_bash_hook: $cmd"); 
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
      
      quit($1) if $l=~/quit:(.*)/;
      outthentic_die($1) if $l=~/outthentic_die:(.*)/;

      ignore_story_err($1) if $l=~/ignore_story_err:\s+(\d)/;
      
      if ($l=~/story_var_bash:\s+(\S+)\s+(.*)/){
        $story_vars_bash{$1}=$2;
        #warn %story_vars_bash;
        next;    
      }

      if ($l=~/story:\s+(\S+)/){
        my $path = $1;
        if (debug_mod12()){
            main::note("run downstream story from bash hook"); 
        }
        run_story($path, {%story_vars_bash});
        %story_vars_bash = ();
      }
    }

    return 1;

}


sub apply_story_vars {

    my $story_vars = Outthentic::Story::Stat->current->{vars};

    set_prop( story_vars =>  $story_vars );

    open STORY_VARS, ">", (story_cache_dir())."/variables.json" 
    or die "can't open ".(story_cache_dir())."/variables.json write: $!";

    print STORY_VARS encode_json($story_vars);

    close STORY_VARS;

    open STORY_VARS, ">", (story_cache_dir())."/variables.bash" 
    or die "can't open ".(story_cache_dir())."/variables.bash write: $!";

    for my $name (keys %{$story_vars} ){
      print STORY_VARS "$name=".$story_vars->{$name}."\n";
    }

    close STORY_VARS;

}

sub story_var {

    my $name = shift;

    get_prop( 'story_vars' )->{$name};

}

sub story_vars_pretty {

    join " ", map { "$_:".(story_var($_)) } sort keys %{get_prop( 'story_vars' ) };

}

sub dump_os {

return $^O if $^O  =~ 'MSWin';

my $cmd = <<'HERE';
#! /usr/bin/env sh

# Find out the target OS
if [ -s /etc/os-release ]; then
  # freedesktop.org and systemd
  . /etc/os-release
  OS=$NAME
  VER=$VERSION_ID
elif lsb_release -h >/dev/null 2>&1; then
  # linuxbase.org
  OS=$(lsb_release -si)
  VER=$(lsb_release -sr)
elif [ -s /etc/lsb-release ]; then
  # For some versions of Debian/Ubuntu without lsb_release command
  . /etc/lsb-release
  OS=$DISTRIB_ID
  VER=$DISTRIB_RELEASE
elif [ -s /etc/debian_version ]; then
  # Older Debian/Ubuntu/etc.
  OS=Debian
  VER=$(cat /etc/debian_version)
elif [ -s /etc/SuSe-release ]; then
  # Older SuSE/etc.
  printf "TODO\n"
elif [ -s /etc/redhat-release ]; then
  # Older Red Hat, CentOS, etc.
  OS=$(cat /etc/redhat-release| head -n 1)
else
  RELEASE_INFO=$(cat /etc/*-release 2>/dev/null | head -n 1)

  if [ ! -z "$RELEASE_INFO" ]; then
    OS=$(printf -- "$RELEASE_INFO" | awk '{ print $1 }')
    VER=$(printf -- "$RELEASE_INFO" | awk '{ print $NF }')
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi
fi

  echo "$OS$VER"

HERE

  `$cmd`

}

sub _resolve_os {

  
    if (!$OS){

       DONE: while (1) {
          my $data = dump_os();
          $data=~/alpine/i and $OS = 'alpine' and last DONE;
          $data=~/minoca/i and $OS = "minoca" and last DONE;
          $data=~/centos linux(\d+)/i and $OS = "centos$1" and last DONE;
          $data=~/Red Hat.*release\s+(\d)/i and $OS = "centos$1" and last DONE;
          $data=~/arch/i and $OS = 'archlinux' and last DONE;
          $data=~/funtoo/i and $OS = 'funtoo' and last DONE;
          $data=~/fedora/i and $OS = 'fedora' and last DONE;
          $data=~/amazon/i and $OS = 'amazon' and last DONE;
          $data=~/ubuntu/i and $OS = 'ubuntu' and last DONE;
          $data=~/debian/i and $OS = 'debian' and last DONE;
          $data=~/darwin/i and $OS = 'darwin' and last DONE;
          $data=~/MSWin/i and $OS = 'windows' and last DONE;
          warn "unknown os: $data";
          last DONE;
      }
  }
  return $OS;
}

package main;

sub os { Outthentic::Story::_resolve_os }



1;

__END__

