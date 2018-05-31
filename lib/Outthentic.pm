package Outthentic;

our $VERSION = '0.3.16';

1;

package main;

use Carp;
use Config::General;
use YAML qw{LoadFile};
use JSON;
use Cwd;

use strict;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Outthentic::Story;
use Term::ANSIColor;
use Hash::Merge qw{merge};
use Time::localtime;
use Capture::Tiny;

Hash::Merge::specify_behavior(
    {
                'SCALAR' => {
                        'SCALAR' => sub { $_[1] },
                        'ARRAY'  => sub { [ $_[0], @{$_[1]} ] },
                        'HASH'   => sub { $_[1] },
                },
                'ARRAY' => {
                        'SCALAR' => sub { $_[1] },
                        'ARRAY'  => sub { [ @{$_[1]} ] },
                        'HASH'   => sub { $_[1] }, 
                },
                'HASH' => {
                        'SCALAR' => sub { $_[1] },
                        'ARRAY'  => sub { [ values %{$_[0]}, @{$_[1]} ] },
                        'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
                },
        }, 
        'Strun', 
);

my $config_data; 

our $STATUS = 1;

sub execute_cmd {
    my $cmd = shift;
    note("execute cmd: $cmd") if debug_mod2();
    (system($cmd) == 0);
}

sub execute_cmd2 {

    my $cmd = shift;
    my $out;

    my $format = get_prop('format');

    note("execute scenario: $cmd") if debug_mod2();

    my $stdout; my $stderr; my $exit;

    if ($format eq 'production'){
      ( $stdout, $stderr, $exit) =  Capture::Tiny::capture { system( $cmd ) };
    } else{
      ( $stdout, $stderr, $exit) =  Capture::Tiny::tee { system( $cmd ) };
    }

    return ($exit >> 8,$stdout.$stderr);
}

sub config {
  $config_data
}

sub dump_config {
  my $json = JSON->new->pretty;
  print $json->encode(config());
}

sub nocolor {
  get_prop('nocolor')
}

sub populate_config {

    unless (config()){
        if (get_prop('ini_file_path') and -f get_prop('ini_file_path') ){
          my $path = get_prop('ini_file_path');
          my %c  = Config::General->new( 
            -InterPolateVars => 1 ,
            -InterPolateEnv  => 1 ,
            -ConfigFile => $path 
          )->getall or confess "file $path is not valid config file";
          $config_data = {%c};
        }elsif(get_prop('yaml_file_path') and -f get_prop('yaml_file_path')){
          my $path = get_prop('yaml_file_path');
          ($config_data) = LoadFile($path);
        }elsif ( get_prop('json_file_path') and -f get_prop('json_file_path') ){
          my $path = get_prop('json_file_path');
          open DATA, $path or confess "can't open file $path to read: $!";
          my $json_str = join "", <DATA>;
          close DATA;
          $config_data = from_json($json_str);
        }elsif ( -f 'suite.ini' ){
          my $path = 'suite.ini';
          my %c  = Config::General->new( 
            -InterPolateVars => 1 ,
            -InterPolateEnv  => 1 ,
            -ConfigFile => $path 
          )->getall or confess "file $path is not valid config file";
          $config_data = {%c};
        }elsif ( -f 'suite.yaml'){
          my $path = 'suite.yaml';
          ($config_data) = LoadFile($path);
        }elsif ( -f 'suite.json'){
          my $path = 'suite.json';
          open DATA, $path or confess "can't open file $path to read: $!";
          my $json_str = join "", <DATA>;
          close DATA;
          $config_data = from_json($json_str);
        }else{
          $config_data = { };
        }
    }

    my $default_config;

    if ( -f 'suite.ini' ){
      my $path = 'suite.ini';
      my %c  = Config::General->new( 
        -InterPolateVars => 1 ,
        -InterPolateEnv  => 1 ,
        -ConfigFile => $path 
      )->getall or confess "file $path is not valid config file";
      $default_config = {%c}; 
    }elsif ( -f 'suite.yaml'){
      my $path = 'suite.yaml';
      ($default_config) = LoadFile($path);
    }elsif ( -f 'suite.json'){
      my $path = 'suite.json';
      open DATA, $path or confess "can't open file $path to read: $!";
      my $json_str = join "", <DATA>;
      close DATA;
      $default_config = from_json($json_str);
    }else{
      $default_config = { };
    }


    my @runtime_params;

    if (my $args_file = get_prop('args_file') ){
      open ARGS_FILE, $args_file or die "can't open file $args_file to read: $!";
      while (my $l = <ARGS_FILE>) {
        chomp $l;
        next unless $l=~/\S/;
        push @runtime_params, $l;
      }
      close ARGS_FILE;
    } else {
      @runtime_params = split /:::/, get_prop('runtime_params');
    }

    my $config_res = merge( $default_config, $config_data );

    PARAM: for my $rp (@runtime_params){

      my $value;

      if ($rp=~s/=(.*)//){
        $value = $1;
      }else{
        next PARAM;
      }  

      my @pathes = split /\./, $rp;
      my $last_path = pop @pathes;

      my $root = $config_res;
      for my $path (@pathes){
        next PARAM unless defined $root->{$path};
        $root = $root->{$path};
      }
      $root->{$last_path} = $value;
    }

    open CONFIG, '>', story_cache_dir().'/config.json' 
      or die "can't open to write file ".story_cache_dir()."/config.json : $!";
    my $json = JSON->new();
    print CONFIG $json->encode($config_res);
    close CONFIG;

    note("configuration populated and saved to ".story_cache_dir()."/config.json") if debug_mod12;

    # populating cli_args from config_data{args}
    unless (get_prop('cli_args')){
      if ($config_res->{'args'} and ref($config_res->{'args'}) eq 'ARRAY'){
        note("populating cli args from args in configuration data") if debug_mod12;
        my @cli_args;
        for my $item (@{$config_res->{'args'}}){
          if (! ref $item){
            push @cli_args, $item;
          } elsif(ref $item eq 'HASH'){
            for my $k ( keys %{$item}){
              my $k1 = $k;
              if ($k1=~s/^~//){
                push @cli_args, '-'.$k1, $item->{$k};
              }else{
                push @cli_args, '--'.$k1, $item->{$k};
              }
            }
          } elsif(ref $item eq 'ARRAY'){
            push @cli_args, map {
              my $v = $_;
              $v=~s/^~// ? '-'.$v : '--'.$v;
            } @{$item};
          };
        }
        note("cli args set to: ".(join ' ', @cli_args)) if debug_mod12;
        set_prop('cli_args', join ' ', @cli_args );
      }
   }

    open CLI_ARGS, '>', story_cache_dir().'/cli_args' 
      or die "can't open to write file ".story_cache_dir()."/cli_args : $!";
    print CLI_ARGS get_prop('cli_args');
    close CLI_ARGS;

    note("cli args populated and saved to ".story_cache_dir()."/cli_args") if debug_mod12;

    # it should be done once
    # and it always true
    # as populate_config() reach this lines
    # only once, when config is really populated

    if ( get_prop('cwd') ) {
      unless (chdir(get_prop('cwd'))){
        $STATUS = 0;
        die "can't change working directory to: ".(get_prop('cwd'))." : $!";
      }

    }
    
    return $config_data = $config_res;
    return $config_data;
}

sub print_story_header {

    my $task_name = get_prop('task_name');

    my $format = get_prop('format');
    my $data;
    if ($format eq 'production') {
        $data = timestamp().' : '.($task_name || '').' '.(short_story_name($task_name))
    } elsif ($format ne 'concise') {
        $data = timestamp().' : '.($task_name ||  '' ).' '.(nocolor() ? short_story_name($task_name) : colored(['yellow'],short_story_name($task_name)))
    }
    if ($format eq 'production'){
      note($data,1)
    } else {
      note($data)
    }
}

sub run_story_file {

    return get_prop('stdout') if defined get_prop('stdout');

    set_prop('has_scenario',1);

    my $format = get_prop('format');

    my $story_dir = get_prop('story_dir');

    if ( get_stdout() ){


        print_story_header();

        note("stdout is already set") if debug_mod12;

        unless ($format eq 'production') {
          for my $l (split /\n/, get_stdout()){
            note($l);
          }
        }

        set_prop( stdout => get_stdout() );
        set_prop( scenario_status => 1 );

        Outthentic::Story::Stat->set_scenario_status(1);
        Outthentic::Story::Stat->set_stdout(get_stdout());

    } else {


        my $story_command;

        if ( -f "$story_dir/story.pl" ){

          if (-f project_root_dir()."/cpanfile" ){
            $story_command  = "PATH=\$PATH:".project_root_dir()."/local/bin/ perl -I ".story_cache_dir().
            " -I ".project_root_dir()."/local/lib/perl5 -I".project_root_dir()."/lib " ."-MOutthentic::Glue::Perl $story_dir/story.pl";
          } else {
            $story_command = "perl -I ".story_cache_dir()." -I ".project_root_dir()."/lib"." -MOutthentic::Glue::Perl $story_dir/story.pl";
          }

          print_story_header();

        }elsif(-f "$story_dir/story.rb") {

            my $story_file = "$story_dir/story.rb";

            my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

            if (-f project_root_dir()."/Gemfile" ){
              $story_command  = "cd ".project_root_dir()." && bundle exec ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $story_file";
            } else {
              $story_command = "ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $story_file";
            }

          print_story_header();

        }elsif(-f "$story_dir/story.py") {

            my $python_lib_dir = File::ShareDir::dist_dir('Outthentic');
            $story_command  = "PYTHONPATH=\$PYTHONPATH:".(story_cache_dir()).
            ":$python_lib_dir python $story_dir/story.py";

            print_story_header();

        } elsif(-f "$story_dir/story.bash") {

            my $bash_lib_dir = File::ShareDir::dist_dir('Outthentic');
            $story_command = "bash -c 'source ".story_cache_dir()."/glue.bash";
            $story_command.= " && source $bash_lib_dir/outthentic.bash";
            $story_command.= " && source $story_dir/story.bash'";

            print_story_header();

        } else {

          # print "empty story\n";

          return;
        }

        my ($ex_code, $out) = execute_cmd2($story_command);

        print_story_messages($out) if $format eq 'production';

        if ($ex_code == 0) {
            outh_ok(1, "scenario succeeded" ) unless $format eq 'production';
            set_prop( scenario_status => 1 );
            Outthentic::Story::Stat->set_scenario_status(1);
            Outthentic::Story::Stat->set_stdout($out);

        }elsif(ignore_story_err()){
            outh_ok(1, "scenario failed, still continue due to `ignore_story_err' is set");
            set_prop( scenario_status => 2 );
            Outthentic::Story::Stat->set_scenario_status(2);
            Outthentic::Story::Stat->set_stdout($out);
        }else{
            if ( $format eq 'production'){
              print "$out";
              outh_ok(0, "scenario succeeded", $ex_code);
            } else {
              outh_ok(0, "scenario succeeded", $ex_code);
            }
            set_prop( scenario_status => 0 );
            Outthentic::Story::Stat->set_scenario_status(0);
            Outthentic::Story::Stat->set_stdout($out);
            Outthentic::Story::Stat->set_status(0);
        }

        set_prop( stdout => $out );

    }


    return get_prop('stdout');
}

sub header {

    my $project = project_root_dir();
    my $story = get_prop('story');
    my $story_type = get_prop('story_type');
    my $story_file = get_prop('story_file');
    my $debug = get_prop('debug');
    my $ignore_story_err = ignore_story_err();
    
    note("project: $project");
    note("story: $story");
    note("story_type: $story_type");
    note("debug: $debug");
    note("ignore story errors: $ignore_story_err");

}

sub run_and_check {

    my $story_check_file = shift;

    my $format = get_prop('format');

    header() if debug_mod2();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    eval { dsl()->{output} = run_story_file() };

  
    if ($@) {
      $STATUS = 0;
      die "story run error: $@";
    }

    return unless get_prop('scenario_status'); # we don't run checks for failed scenarios

    return unless $story_check_file;
    return unless -s $story_check_file; # don't run check when check file is empty

    eval {
          open my $fh, $story_check_file or confess $!;
          my $check_list = join "", <$fh>; close $fh;
          dsl()->validate($check_list)
    };

    my $err = $@;
    my $check_fail=0;
    for my $r ( @{dsl()->results}){
        note($r->{message}) if $r->{type} eq 'debug';
        if ($r->{type} eq 'check_expression' ){
          Outthentic::Story::Stat->add_check_stat($r);
          $check_fail=1 unless $r->{status};
          if ($format eq 'production'){
            outh_ok($r->{status}, $r->{message}) unless $r->{status}; 
          } else {
            outh_ok($r->{status}, $r->{message}); 
          }
          Outthentic::Story::Stat->set_status(0) unless $r->{status};
        };

    }


    if ($err) {
      $STATUS = 0;
      die "validator error: $err";
    }

    if ($format eq 'production' and $check_fail) {
      print get_prop("stdout");
    }
}

      
sub print_story_messages {
  my $out = shift;
  print " [msg] " if $out=~/outthentic_message/;
  my @m = ($out=~/outthentic_message:\s+(.*)/g);
  print join " ", @m;
  print "\n";
}

sub outh_ok {

    my $status    = shift;
    my $message   = shift;
    my $exit_code = shift;

    my $format = get_prop('format');

    if ($format ne 'concise'){
      if ($status) {
        print nocolor() ? "ok\t$message\n" : colored(['green'],"ok\t$message")."\n";
      } else {
        print nocolor() ? "not ok\t$message\n" : colored(['red'], "not ok\t$message")."\n";
      }
    }

    if ($status == 0 and $STATUS != 0 ){
      $STATUS = ($exit_code == 1 ) ? -1 : 0;
    }
}

sub note {

    my $message = shift;
    my $no_new_line = shift;

    binmode(STDOUT, ":utf8");
    print $message;
    print "\n" unless $no_new_line;

}


sub print_meta {

    open META, get_prop('story_dir')."/meta.txt" or die $!;

    my $task_name = get_prop('task_name');

    #note( ( nocolor() ? short_story_name($task_name) : colored( ['yellow'], short_story_name($task_name) ) ));

    while (my $i = <META>){
        chomp $i;
        $i='@ '.$i;
        note( nocolor() ? $i : colored( ['magenta'],  "$i" ));
    }
    close META;

}

sub short_story_name {

    my $task_name = shift;

    my $story_dir = get_prop('story_dir');

    my $cwd_size = scalar(split /\//, get_prop('project_root_dir'));

    my $short_story_dir;

    my $i;

    for my $l (split /\//, $story_dir){
      $short_story_dir.=$l."/" unless $i++ < $cwd_size;

    }

    my $story_vars = story_vars_pretty();

    $short_story_dir ||= "/";

    my @ret;

    push @ret, "[path] $short_story_dir" if $short_story_dir;
    push @ret, "[params] $story_vars" if $story_vars;

    join " ", @ret;

}

sub timestamp {
  sprintf '%02d-%02d-%02d %02d:%02d:%02d', 
    localtime->year()+1900, 
    localtime->mon()+1, localtime->mday, 
    localtime->hour, localtime->min, localtime->sec;
}

END {

  #print "STATUS: $STATUS\n";

  if ($STATUS == 1){
    exit(0);
  } elsif($STATUS == -1){
    exit(1);
  } else{
    exit(2);
  }

  
}

1;


__END__

=pod


=encoding utf8


=head1 Name

Outthentic - Multipurpose scenarios framework.


=head1 Synopsis

Multipurpose scenarios framework.


=head1 Build status

L<![Build Status](https://travis-ci.org/melezhik/outthentic.svg)|https://travis-ci.org/melezhik/outthentic>


=head1 Install

    $ cpanm Outthentic


=head1 Introduction

This is an outthentic tutorial. 


=head1 Scenarios

Scenario is just a script that you B<run> and that yields something into B<stdout>.

Perl scenario example:

    $ nano story.pl
    
    print "I am OK\n";
    print "I am outthentic\n";

Bash scenario example:

    $ nano story.bash
    
    echo I am OK
    echo I am outthentic

Python scenario example:

    $ nano story.py
    
    print "I am OK"
    print "I am outthentic"

Ruby scenario example:

    $ nano story.rb
    
    puts "I am OK"
    puts "I am outthentic"

Outthentic scenarios could be written in one of the four languages:

=over

=item *

Perl 


=item *

Bash


=item *

Python


=item *

Ruby


=back

Choose you favorite language ;) !

Outthentic relies on file names convention to determine scenario language. 

This table describes C<<< file name -> language >>> mapping for scenarios:

    +-----------+--------------+
    | Language  | File         |
    +-----------+--------------+
    | Perl      | story.pl     |
    | Bash      | story.bash   |
    | Python    | story.py     |
    | Ruby      | story.rb     |
    +-----------+--------------+


=head1 Check files

Check files contain rules to B<verify> stdout produced by scenarios. 

Here we require that scenario should produce  C<I am OK> and C<I am outthentic> lines in stdout:

    $ nano story.check
    
    I am OK
    I am outthentic

NOTE: Check files are optional, if one doesn't need any checks, then don't create check files.

In this case it's only ensured that a scenario succeeds ( exit code 0 ).


=head1 Stories

Outthentic story is an abstraction for scenario and check file. 

When outthentic story gets run:

=over

=item *

scenario is executed and the output is saved into a file.


=item *

the output is verified against check file


=back

See also L<story runner|#story-runner>.


=head1 Suites and projects

Outthentic suites are a bunch of related stories. You may also call suites (outthentic) projects.

Obviously project may contain more than one story. 

Stories are mapped into directories inside the project root directory.

Here is an example:

    # Perl
    
    $ mkdir perl-story
    
    $ nano  perl-story/story.pl
      print "hello from perl"
    
    $ nano perl-story/story.check
      hello from perl
    
    # Bash
    $ mkdir bash-story
    
    $ nano bash-story/story.bash
      echo hello from bash 
    
    $ nano bash-story/story.check
      hello from bash 
    
    # Python
    $ mkdir python-story
    
    $ nano python-story/story.py
      print "hello from python" 
    
    $ nano python-story/story.check
      hello from python 
    
    # Ruby
    $ mkdir ruby-story
    
    $ nano ruby-story/story.rb
      puts "hello from ruby"
    
    $ nano ruby-story/story.check
      hello from ruby 

To execute different stories launch story runner command called L<strun|#story-runner>:

    $ strun --story perl-story
    $ strun --story bash-story 
    # so on ...


=head1 The project root directory resolution and story paths

If C<--root> parameter is not set the project root directory is the current working directory.

By default, if C<--story> parameter is not given, strun looks for the file named story.(pl|rb|bash) at the project root directory
and run it.

Here is an example:

    $ nano story.bash
    echo 'hello world'
    
    $ strun # will run story.bash 

It's always possible to pass the project root directory explicitly:

    $ strun --root /path/to/project/root/

To run the certain story use C<--story> parameter:

    $ strun --story story1

C<--story> parameter should point a directory I<relative> to the project root directory.

Summary:

=over

=item *

Stories are just a directories with scenarios and check files inside.      




=item *

Strun - a [S]tory [R]unner - a console tool to execute stories.



=item *

Outthentic suites or projects are bunches of I<related> stories.



=back


=head1 Check files

Checks files contain rules to test scenario's output. 

Every scenario B<might be accompanied by> its check file. 

Check file should be placed at the same directory as scenario and be named as C<story.check>.

Here is an example:

    $ nano story.bash
    sudo service nginx status
     
    $ nano story.check
    running


=head1 Story runner

Story runner is a console tool to run stories. It is called C<strun>.

When executing stories strun consequentially goes through several phases:


=head1 Compilation phase

Stories are compiled into Perl files and saved into cache directory.


=head1 Execution phase

Compiled Perl files are executed and results are dumped out to console. 


=head1 Hooks

Story hooks are story runner's extension points. 

Hook features:

=over

=item *

Hooks like scenarios are scripts written on different languages (Perl,Bash,Ruby,Python)



=item *

Hooks always I<binds to some story>, to create a hook you should place hook's script into story directory.



=item *

Hooks are are executed I<before> scenarios



=back

Here is an example of hook:

    $ nano perl/hook.pl
    
    print "this is a story hook!";

This table describes file name -> language mapping for scenarios:

    +-----------+--------------+
    | Language  | File         |
    +-----------+--------------+
    | Perl      | hook.pl      |
    | Bash      | hook.bash    |
    | Python    | hook.py      |
    | Ruby      | hook.rb      |
    +-----------+--------------+

Reasons why you might need hooks:

=over

=item *

Execute some I<initialization code> before running a scenario


=item *

Simulate scenario's output


=item *

Call another stories


=back


=head1 Simulate scenario output

Sometimes you want to override story output at hook level. 

This is for example might be useful if you want to I<test> the rules in check files without running real script.

In QA methodology it's called Mock objects:

    $ nano hook.bash
      set_stdout 'running'
    $ nano story.check
      running

It's important to say that if overriding happens story executor never try to run scenario even if it presents:

    $ nano hook.bash
      set_stdout 'running'
    $ nano story.bash
      sudo service nginx status # this command won't be executed

You may call C<set_stdout> function more then once:

    $ nano hook.pl
      set_stdout("HELLO WORLD");
      set_stdout("HELLO WORLD2");

It will "produce" two line of a story output:

    HELLO WORLD
    HELLO WORLD2

This table describes how C<set_stdout()> function is called in various languages:

    +-----------+-----------------------+
    | Language  | signature             |
    +-----------+-----------------------+
    | Perl      | set_stdout(SCALAR)    |
    | Bash      | set_stdout(STRING)    |
    | Python(*) | set_stdout(STRING)    |
    | Ruby      | set_stdout(STRING)    |
    +-----------+-----------------------+

(*) You need to C<from outthentic import *> in Python to import set_stdout function.


=head1 Run stories from other stories

Hooks allow you to call one story from other one. Here is an example:

    $ nano modules/knock-the-door/story.rb
    
      # this is a downstream story
      # to make story downstream
      # simply create story files 
      # in modules/ directory
    
      puts 'knock-knock!'" 
     
    $ nano modules/knock-the-door/story.check
      knock-knock!
    
     
    $ nano open-the-door/hook.rb
    
      # this is a upstream story
      # to run downstream story
      # call run_story function
      # inside hook
    
      # run_story accepts parameter - story path,
      # notice that you have to omit 'modules/' part
    
      run_story( 'knock-the-door' );
    
    $ nano open-the-door/story.rb
      puts 'opening ...' 
    
    $ nano open-the-door/story.check
      opening
    
    $ strun --story open-the-door/
     
      /modules/knock-the-door/ started
    
      knock-knock!
      OK  scenario succeeded
      OK  output match 'knock-knock!'
    
      /open-the-door/ started
    
      opening ...
      OK  scenario succeeded
      OK  output match 'opening'
      ---
      STATUS  SUCCEED

Stories that run other stories are called I<upstream stories>.

Stories being called from other ones are I<downstream story>.

Summary:

=over

=item *

To create downstream story place a story data in C<modules/> directory inside the project root directory.



=item *

To run downstream story call C<run_story(story_path)> function inside the upstream story's hook.



=item *

Downstream story is always gets executed before upstream story.



=item *

You can call as many downstream stories as you wish.



=item *

Downstream stories may call other downstream stories.



=back

Here is more sophisticated examples of downstream stories:

    $ nano modules/up/story.pl 
      print "UP!"
    
    $ nano modules/down/story.pl 
      print "DOWN!"
    
    $ nano two-jumps/hook.pl
      run_story( 'up' );
      run_story( 'down' );
      run_story( 'up' );
      run_story( 'down' );


=head1 Story variables 

Variables might be passed to downstream story by the second argument of C<run_story()> function. 

For example, in Perl:

    $ nano hook.pl
    
      run_story( 
        'greeting', {  name => 'Alexey' , message => 'hello' }  
      );

Or in Ruby:

    $ nano hook.rb
    
      run_story  'greeting', {  'name' => 'Alexey' , 'message' => 'hello' }

Or in Python:

    $ nano hook.rb
    
      from outthentic import *
      run_story('greeting', {  'name' : 'Alexey' , 'message' : 'hello' })

Or in Bash:

    $ nano hook.bash
    
      run_story  greeting name Alexey message hello 

This table describes how C<run_story()> function is called in various languages:

    +------------+----------------------------------------------+
    | Language   | signature                                    |
    +------------+----------------------------------------------+
    | Perl       | run_story(SCALAR,HASHREF)                    |
    | Bash       | run_story STORY_NAME NAME VAL NAME2 VAL2 ... | 
    | Python(**) | run_story(STRING,DICT)                       | 
    | Ruby       | run_story(STRING,HASH)                       | 
    +------------+----------------------------------------------+

(I<) Story variables are accessible(>) in downstream story by C<story_var()> function. 

(**) You need to C<from outthentic import *> in Python to import set_stdout function.

Examples:

In Perl:

    $ nano modules/greeting/story.pl
    
      print story_var('name'), 'say ', story_var('message');

In Python:

    $ nano modules/greeting/story.py
    
      from outthentic import *
      print story_var('name') + 'say ' + story_var('message')

In Ruby:

    $ nano modules/greeting/story.rb
    
      puts "#{story_var('name')} say #{story_var('message')}"

In Bash:

    $ nano modules/greeting/story.bash
    
      echo $name say $message

In Bash (alternative way):

    $ nano modules/greeting/story.bash
    
      echo $(story_var name) say $(story_var message)

(*) Story variables are accessible inside check files as well.

This table describes how C<story_story()> function is called in various languages:

    +------------------+---------------------------------------------+
    | Language         | signature                                   |
    +------------------+---------------------------------------------+
    | Perl             | story_var(SCALAR)                           |
    | Python(*)        | story_var(STRING)                           | 
    | Ruby             | story_var(STRING)                           | 
    | Bash (1-st way)  | $foo $bar ...                               |
    | Bash (2-nd way)  | $(story_var foo.bar)                        |
    +------------------+---------------------------------------------+

(*) You need to C<from outthentic import *> in Python to import story_var() function.


=head1 Stories without scenarios

The minimal set of files should be present in outthentic story is either scenario file or hook script,
the last option is story without scenario.

Examples:

    # Story with scenario only
    
    $ nano story.pl
    
    
    # Story with hook only
    
    $ nano hook.pl


=head1 Story helper functions

Here is the list of function one can use I<inside hooks>:

=over

=item *

C<project_root_dir()> - the project root directory.



=item *

C<cache_root_dir()> - the cache root directory ( see  L<strun|#story-runner> ).



=item *

C<cache_dir()> - storie's cache directory ( containing story's compiled files )



=item *

C<story_dir()> - the directory containing story data.



=item *

C<config()> - returns suite configuration hash object. See also L<suite configuration|#suite-configuration>.



=item *

os() - return a mnemonic ID of operation system where story is executed.



=back

(*) You need to C<from outthentic import *> in Python to import os() function.
(**) in Bash these functions are represented by variables, e.g. $project_root_dir, $os, so on.


=head1 Recognizable OS list

=over

=item *

alpine


=item *

amazon


=item *

archlinux


=item *

centos5


=item *

centos6


=item *

centos7


=item *

debian


=item *

fedora


=item *

minoca


=item *

ubuntu


=item *

funtoo


=back


=head1 Story meta headers

Story meta headers are just plain text files with some useful description.

The content of the meta headers will be shown when story is executed.

Example:

    $ nano meta.txt
    
      The beginning of the story ...


=head1 Ignore scenario failures

If scenario fails ( the exit code is not equal to zero ), the story executor marks such a story as unsuccessful and this
results in overall failure. To suppress any story errors use C<ignore_story_err()> function.

Examples:

    # Python
    
    $ nano hook.py
      from outthentic import *
      ignore_story_err(1)
    
    
    # Ruby
    
    $ nano hook.rb
      ignore_story_err 1
    
    # Perl
    
    $ nano hook.pl
      ignore_story_err(1)
    
    # Bash
    
    $ nano hook.bash
      ignore_story_err 1


=head1 Story libraries

Story libraries are files to make your libraries' code I<automatically required> into the story scenarios, hooks and check files context:

Here are some examples:

Bash:

    $ nano my-story/common.bash
      function hello_bash {
        echo 'hello bash'
      } 
    
    $ nano my-story/story.bash
        echo hello_bash
    
    $ nano my-story/story.check
      generator: <<CODE;
      !bash
        echo hello_bash
      CODE

Ruby:

    $ nano modules/my-story/common.rb
      def hello_ruby
        'hello ruby'
      end
    
    $ nano modules/my-story/hook.rb
      set_stdout(hello_ruby())
    
    $ nano modules/my-story/story.check
      generator: <<CODE;
      !ruby
        pust hello_ruby()
      CODE

This table describes C<<< file name -> language >>> mapping for story libraries:

    +-----------+-----------------+--------------------------------+
    | Language  | file            | locations                      |
    +-----------+-----------------+--------------------------------+
    | Bash      | common.bash     | $project_root_dir/common.bash  |
    |           |                 | $story_dir/common.bash         |
    +-----------+-----------------+--------------------------------+
    | Ruby      | common.rb       | $project_root_dir/common.rb    |
    |           |                 | $story_dir/common.bash         |
    +-----------+-----------------+--------------------------------+

If you put story library file into project root directory it will be required by I<any> story:

    $ nano common.bash
    
      function hello_bash {
        echo 'hello bash'
      }

B<I<NOTE!>>  Story libraries are not supported for Python and Perl


=head1 PERL5LIB

$project_root_directory/lib path is added to $PERL5LIB variable. 

This make it easy to place custom Perl modules under project root directory:

    $ nano my-app/lib/Foo/Bar/Baz.pm
      package Foo::Bar::Baz;
      1;
    
    $ nano common.pm
      use Foo::Bar::Baz;


=head1 Story runner console tool

    $ strun <options>


=head1 Options

=over

=item *

C<--root>



=back

The project root directory. Default value is the current working directory.

=over

=item *

C<--cwd>



=back

Sets working directory when strun executes stories.

=over

=item *

C<--debug> 


=back

Enable/disable debug mode:

    * Increasing debug value results in more low level information appeared at output.
    
    * Default value is 0, which means no debugging. 
    
    * Possible values: 0,1,2,3.

=over

=item *

C<--format> 


=back

Sets reports format. Available formats are: C<concise|production|default>. Default value is C<default>.

In concise format strun shrinks output to only STDOUT/STDERR comes from scenarios. It's useful when you want to parse stories output by external commands.

Production format omits debug information.

=over

=item *

C<--purge-cache>


=back

Purge strun cache directory upon exit. By default C<--purge-cache> is disabled.

=over

=item *

C<--match_l> 


=back

Truncate matching strings. When matching lines are appeared in a report they are truncated to $match_l bytes. Default value is 200.

=over

=item *

C<--story> 


=back

Run only a single story. This should be path I<relative> to the project root directory. 

Examples:

    # Project with 3 stories
    foo/story.pl
    foo/bar/story.rb
    bar/story.pl
    
    # Run various stories
    --story foo # runs foo/ stories
    --story foo/story # runs foo/story.pl
    --story foo/bar/ # runs foo/bar/ stories

=over

=item *

C<--ini>



=back

Configuration file path.

See L<suite configuration|#suite-configuration> section for details.

=over

=item *

C<--yaml> 


=back

YAML configuration file path. 

See L<suite configuration|#suite-configuration> section for details.

=over

=item *

C<--json> 


=back

JSON configuration file path. 

See L<suite configuration|#suite-configuration> section for details.

=over

=item *

C<--nocolor>


=back

Disable colors in reports. By default reports are color.

=over

=item *

C<--dump-config>


=back

Dumps suite configuration and exit. See also suite configuration section.


=head1 Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are three type of configuration files are supported:

=over

=item *

Config::General format (aka ini files)


=item *

YAML format


=item *

JSON format


=back

Config::General style configuration files are passed by C<--ini> parameter:

    $ strun --ini /etc/suites/foo.ini
    
    $ nano /etc/suites/foo.ini
    
    <main>
    
      foo 1
      bar 2
    
    </main>

There is no special magic behind ini files, except this should be L<Config::General|https://metacpan.org/pod/Config::General> compliant configuration file.

Or you can choose YAML format for suite configuration by using C<--yaml> parameter:

    $ strun --yaml /etc/suites/foo.yaml
    
    $ nano /etc/suites/foo.yaml
    
    main :
      foo : 1
      bar : 2

Unless user sets path to the configuration file explicitly either by C<--ini> or C<--yaml> or C<--json>  story runner looks for the 
files named suite.ini and I<then> ( if suite.ini is not found ) for suite.yaml, suite.json at the current working directory.

If configuration file is passed and read, the configuration data is accessible in a story hook file via config() function:

    $ nano hook.pl
    
      my $foo = config()->{main}->{foo};
      my $bar = config()->{main}->{bar};

Examples for other languages:

Bash:

    $ nano hook.bash
    
      foo=$(config main.foo )
      bar=$(config main.bar )

Python:

    $ nano hook.py
    
    from outthentic import *
    
      foo = config()['main']['foo']
      bar = config()['main']['bar']

Ruby:

    $ nano hook.rb
    
      foo = config['main']['foo']
      bar = config['main']['bar']


=head1 Runtime configuration

Runtime configuration parameters override ones in suite configuration. Consider this example:

    $ nano suite.yaml
    foo :
      bar : 10
      
    $ strun --param foo.bar=20 # will override foo.bar parameter to 20


=head1 Free style command line parameters

Alternative way to pass input parameters into outthentic scripts is a I<free style> command line arguments:

    $ strun -- <arguments>

Consider a simple example. We want to create a wrapper for some external script which accepts the following 
command line arguments:

    script {flags} {named parameters} {value} 

Where flags are:

    --verbose
    --debug

Named parameters are:

    --foo foo-value
    --var bar-value

And value is just a string:

    foo-value

It's quite demanding to map external script parameters into Outthentic configuration. More over 
some parameters of external scripts are optional. 

Here is free style command line arguments to the rescue:

    $ nano story.bash
    script $(args_cli)        

That's all. Now we are safe to run our story-wrapper with command line arguments I<in terms of> external script:

    $ strun -- --foo foo-value --debug the-value


=head1 Auto coercion of configuration data into free style command line parameters

Moreover it's possible declare external script parameters in suite configuration:

    $ nano suite.yaml
    
      ---
    
      args:
        - foo: foo-value
        -
          - debug 
          - verbose 
        - the-value
    
    $ strun

This is end up in running story with following command line arguments for external script:

    --foo foo-value --debug --verbose the-value


=head1 Auto coercion rules

=over

=item *

Args should be array which elements are processed in order, for every elements rules are applied depending on element's type


=item *

Scalars are turned into scalars: C<<< the-value ---> the-value >>>


=item *

Arrays are turned into scalars with double dashes perpended: C<<< (debug, verbose) ---> --debug --verbose >>>. This is useful for declaring
boolean flags 


=item *

Hashes are turned into named parameters: C<<< foo: foo-value ---> --foo foo-value >>>


=back


=head1 Auto coercion, using single dashes instead of double dashes

Double dashes are default behavior of how named parameters and flags 
converted. If you need single dashes, prepend parameters in configuration file with C<~> :

    $ nano suite.yaml
    
      ---
    
      args:
        - '~foo': foo-value
        -
          - ~debug 
          - ~verbose 


=head1 Environment variables

=over

=item *

C<OUTTHENTIC_MATCH> - overrides default value for C<--match_l> parameter of story runner.



=item *

C<SPARROW_ROOT> - sets the prefix for the path to the cache directory with compiled story files, see also L<story runner|#story-runner>.



=item *

C<SPARROW_NO_COLOR> - disable color output, see C<--nocolor> option of story runner.



=item *

C<OUTTHENTIC_CWD> - sets working directory for strun, see C<--cwd> parameter of story runner



=item *

C<OUTTHENTIC_FORMAT> - overrides default value for C<--format> parameter of story runner.



=back

Cache directory resolution:

    +---------------------+----------------------+
    | The Cache Directory | SPARROW_ROOT Is Set? |
    +---------------------+----------------------+
    | ~/.outthentic/tmp/  | No                   |
    | $SPARROW_ROOT/tmp/  | Yes                  |
    +---------------------+----------------------+


=head1 Examples

An example stories can be found in examples/ directory, to run them:

    $ strun --root examples/ --story $story-name

Where C<$story-name> is any top level directory inside examples/.


=head1 Check files syntax

=over

=item *

Brief introduction of check file syntax could be found here - L<https://github.com/melezhik/outthentic/blob/master/check-files-syntax.md|https://github.com/melezhik/outthentic/blob/master/check-files-syntax.md>



=item *

For the full detailed explanation follow Outthentic::DSL doc pages at L<https://github.com/melezhik/outthentic-dsl|https://github.com/melezhik/outthentic-dsl>



=back


=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Home Page

L<https://github.com/melezhik/outthentic|https://github.com/melezhik/outthentic>


=head1 See also

=over

=item *

L<Sparrow|https://github.com/melezhik/sparrow> - Multipurposes scenarios manager.



=item *

L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl> - Outthentic::DSL specification.



=item *

L<Swat|https://github.com/melezhik/swat> - Web testing framework.



=back


=head1 Thanks

To God as the One Who inspires me in my life!
