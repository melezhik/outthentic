package Outthentic;

our $VERSION = '0.2.18';

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

my $config; 

our $STATUS = 1;

sub execute_cmd {
    my $cmd = shift;
    note("execute cmd: $cmd") if debug_mod2();
    (system($cmd) == 0);
}

sub execute_cmd2 {

    my $cmd = shift;
    my $out;
    my $status = 1;

    note("execute scenario: $cmd") if debug_mod2();

    open(OUT, "$cmd 2>&1 |") || die "can't fork: $!";

    while (my $l = <OUT>) {
        $out.=$l;
        chomp $l;
        note( nocolor() ? $l : colored(['white'],$l)) if get_prop('verbose');
    }

    $status = 0 unless close OUT;

    return ($status,$out);
}

sub config {
  $config
}

sub dump_config {
  my $json = JSON->new->pretty;
  print $json->encode(config());
}

sub nocolor {
  get_prop('nocolor')
}

sub populate_config {

    unless ($config){
        if (get_prop('ini_file_path') and -f get_prop('ini_file_path') ){
          my $path = get_prop('ini_file_path');
          my %config  = Config::General->new( 
            -InterPolateVars => 1 ,
            -InterPolateEnv  => 1 ,
            -ConfigFile => $path 
          )->getall or confess "file $path is not valid config file";
          $config = {%config};
        }elsif(get_prop('yaml_file_path') and -f get_prop('yaml_file_path')){
          my $path = get_prop('yaml_file_path');
          ($config) = LoadFile($path);
        }elsif ( get_prop('json_file_path') and -f get_prop('json_file_path') ){
          my $path = get_prop('json_file_path');
          open DATA, $path or confess "can't open file $path to read: $!";
          my $json_str = join "", <DATA>;
          close DATA;
          $config = from_json($json_str);
        }elsif ( -f 'suite.ini' ){
          my $path = 'suite.ini';
          my %config  = Config::General->new( 
            -InterPolateVars => 1 ,
            -InterPolateEnv  => 1 ,
            -ConfigFile => $path 
          )->getall or confess "file $path is not valid config file";
          $config = {%config};
        }elsif ( -f 'suite.yaml'){
          my $path = 'suite.yaml';
          ($config) = LoadFile($path);
        }elsif ( -f 'suite.json'){
          my $path = 'suite.json';
          open DATA, $path or confess "can't open file $path to read: $!";
          my $json_str = join "", <DATA>;
          close DATA;
          $config = from_json($json_str);
        }else{
          $config = { };
        }
    }

    my $default_config = {};

    if ( -f 'suite.ini' ){
      my $path = 'suite.ini';
      my %config  = Config::General->new( 
        -InterPolateVars => 1 ,
        -InterPolateEnv  => 1 ,
        -ConfigFile => $path 
      )->getall or confess "file $path is not valid config file";
      $default_config = {%config};
    }

    my @runtime_params = split /:::/, get_prop('runtime_params');

    Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );

    $config = merge( $default_config, $config );

    PARAM: for my $rp (@runtime_params){

      my $value;

      if ($rp=~s/=(.*)//){
        $value = $1;
      }else{
        next PARAM;
      }  

      my @pathes = split /\./, $rp;
      my $last_path = pop @pathes;

      my $root = $config;
      for my $path (@pathes){
        next PARAM unless defined $root->{$path};
        $root = $root->{$path};
      }
      $root->{$last_path} = $value;
    }

    open CONFIG, '>', story_cache_dir().'/config.json' 
      or die "can't open to write file ".story_cache_dir()."/config.json : $!";
    my $json = JSON->new();
    print CONFIG $json->encode($config);
    close CONFIG;

    note("configuration populated and saved to ".story_cache_dir()."/config.json") if debug_mod12;

    return $config;
}

sub run_story_file {

    return get_prop('stdout') if defined get_prop('stdout');

    my $story_dir = get_prop('story_dir');

    my $cwd_size = scalar(split /\//, get_prop('project_root_dir'));

    note("\n". ( nocolor() ? short_story_name() : colored(['yellow'],short_story_name()) )." started");

    if ( get_stdout() ){

        note("stdout is already set") if debug_mod12;
        if ( get_prop('verbose') ){
          for my $l (split /\n/, get_stdout()){
            note( nocolor() ? $l : colored(['white'],$l));
          };
        }
        set_prop( stdout => get_stdout() );
        set_prop( scenario_status => 1 );

    }else{


        my $story_command;

        if ( -f "$story_dir/story.pl" ){

          if (-f project_root_dir()."/cpanfile" ){
            $story_command  = "PATH=\$PATH:".project_root_dir()."/local/bin/ perl -I ".story_cache_dir().
            " -I ".project_root_dir()."/local/lib/perl5 -MOutthentic::Glue::Perl $story_dir/story.pl";
          } else {
            $story_command = "perl -I ".story_cache_dir()." -MOutthentic::Glue::Perl $story_dir/story.pl";
          }

        }elsif(-f "$story_dir/story.rb") {

            my $story_file = "$story_dir/story.rb";

            my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

            if (-f project_root_dir()."/Gemfile" ){
              $story_command  = "cd ".project_root_dir()." && bundle exec ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $story_file";
            } else {
              $story_command = "ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $story_file";
            }

        }elsif(-f "$story_dir/story.bash") {

            my $bash_lib_dir = File::ShareDir::dist_dir('Outthentic');
            $story_command = "bash -c 'source ".story_cache_dir()."/glue.bash";
            $story_command.= " && source $bash_lib_dir/outthentic.bash";
            $story_command.= " && source $story_dir/story.bash'";
        }

        my ($st, $out) = execute_cmd2($story_command);

        if ($st) {
            outh_ok(1, "scenario succeeded" );
            set_prop( scenario_status => 1 );
            Outthentic::Story::Stat->set_scenario_status(1);
            Outthentic::Story::Stat->set_stdout($out);

        }elsif(ignore_story_err()){
            outh_ok(1, "scenario failed, still continue due to `ignore_story_err' is set");
            set_prop( scenario_status => 2 );
            Outthentic::Story::Stat->set_scenario_status(2);
            Outthentic::Story::Stat->set_stdout($out);
        }else{
            outh_ok(0, "scenario succeeded");
            set_prop( scenario_status => 0 );
            Outthentic::Story::Stat->set_scenario_status(0);
            Outthentic::Story::Stat->set_stdout($out);
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

sub generate_asserts {

    my $story_check_file = shift;

    header() if debug_mod2();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    eval { dsl()->{output} = run_story_file() };


    if ($@) {
      $STATUS = 0;
      die "story run error: $@";
    }

    return unless get_prop('scenario_status'); # we don't run checks for failed scenarios

    return unless -s $story_check_file; # don't run check when check file is empty

    eval { dsl()->validate($story_check_file) };

    my $err = $@;

    for my $r ( @{dsl()->results}){
        note($r->{message}) if $r->{type} eq 'debug';
        if ($r->{type} eq 'check_expression' ){
          Outthentic::Story::Stat->add_check_stat($r);
          outh_ok($r->{status}, $r->{message}) 
        };

    }


    if ($err) {
      $STATUS = 0;
      die "validator error: $err";
    }

}

      

sub outh_ok {

    my $st      = shift;
    my $message = shift;

    if ($st) {
      print nocolor() ? "ok\t$message\n" : colored(['green'],"ok\t$message")."\n";
    } else {
      print nocolor() ? "not ok\t$message\n" : colored(['red'], "not ok\t$message")."\n";
    };

    $STATUS = 0 unless $st;
}

sub note {

    my $message = shift;

    print "$message\n";

}

sub print_meta {

    open META, get_prop('story_dir')."/meta.txt" or die $!;

    note( "\n\n". ( nocolor() ? short_story_name() : colored( ['yellow'],  short_story_name() ) )." started\n");

    while (my $i = <META>){
        chomp $i;
        note( nocolor() ? $i : colored( ['magenta'],  "$i" ));
    }
    close META;

}

sub short_story_name {


    my $story_dir = get_prop('story_dir');

    my $cwd_size = scalar(split /\//, get_prop('project_root_dir'));

    my $short_story_dir = "/";

    my $i;

    for my $l (split /\//, $story_dir){
      $short_story_dir.="$l/" unless $i++ < $cwd_size;

    }

    return $short_story_dir.' '.story_vars_pretty();
}

END {

  exit(1) unless $STATUS;

}

1;


__END__

=pod


=encoding utf8


=head1 Name

Outthentic


=head1 Synopsis

Multipurpose scenarios framework.


=head1 Build status

L<![Build Status](https://travis-ci.org/melezhik/outthentic.svg)|https://travis-ci.org/melezhik/outthentic>


=head1 Install

    $ cpanm Outthentic


=head1 Short introduction

This is a quick tutorial on outthentic usage.


=head2 Run your scenarios

Scenario is just a script that you B<run> and that yields something into B<stdout>.

Perl scenario example:

    $ cat story.pl
    
    print "I am OK\n";
    print "I am outthentic\n";

Ruby scenario example:

    $ cat story.rb
    
    puts "I am OK"
    puts "I am outthentic"

Bash scenario example:

    $ cat story.bash
    
    echo I am OK
    echo I am outthentic

Outthentic scenarios could be written on one of three languages:

=over

=item *

Perl 


=item *

Ruby


=item *

Bash


=back

Choose you favorite language ;) !

Outthentic relies on file names to determine scenario language. 

This is the table to describe language / file name conventions:

    +-----------+--------------+
    | Language  | File         |
    +-----------+--------------+
    | Perl      | story.pl     |
    | Ruby      | story.rb     |
    | Bash      | story.bash   |
    +-----------+--------------+


=head2 Check file

Check file contains rules to B<verify> a stdout produced by scenario script. 

Here we require that our scenario should produce  `I am OK' and `I am outthentic' lines in stdout:

    $ cat story.check
    
    I am OK
    I am outthentic

NOTE: You can leave check file empty, but it's required anyway

    $ touch story.check

Empty check file means you just want to ensure that your story succeed ( exit code 0 ) and don't want
run any checks for story stdout.


=head2 Story

Outthentic story is a scenarios + check file. When outthentic B<run> story it:

=over

=item *

executes scenario script and saves stdout into file.


=item *

verifies stdout against a check file


=back

See also L<story runner|#story-runner>.


=head2 Suite

Outthentic suites are a bunch of related stories. You may also call suites as (outthentic) projects.

One may have more then one story at the project.

Just create a new directories with a story data inside:

    $ mkdir perl-story
    $ echo 'print "hello from perl";' > perl-story/story.pl
    $ echo 'hello from perl' > perl-story/story.check
    
    $ mkdir ruby-story
    $ echo 'puts "hello from ruby"' > ruby-story/story.rb
    $ echo 'hello from ruby' > ruby-story/story.check
    
    $ mkdir bash-story
    $ echo 'echo hello from bash' > bash-story/story.bash
    $ echo 'hello from bash' > bash-story/story.check

Now, let's use C<strun> command to run suite stories:

    $ strun --story perl-story
    
    /perl-story/ started
    
    hello from perl
    OK  scenario succeeded
    OK  output match 'hello from perl'
    ---
    STATUS  SUCCEED
    
    $ strun --story bash-story # so on ...

Summary:

=over

=item *

Stories are just a directories with story scenarios and check files.      




=item *

Strun - a [S]tory [R]unner - a console script to execute story scenarios and validate output by given check lists.



=item *

Outthentic suites are bunches of I<related> stories.



=item *

By default strun looks for story.(pl|rb|bash) file at the project root directory. This is so called a default story.



=item *

One can point strun a distinct story by C<--story> parameter:

$ strun --root /path/to/project/root/ --story /path/to/story/directory/inside/project/root



=back

C<Story> should point a directory relative to project root directory.

=over

=item *

Project root directory - a directory holding all related stories. 


=back

A project root directory could be set explicitly using C<--root> parameter:

    $ strun --root /path/to/my/root/

If C<--root> is not set strun assumes project root directory to be equal current working directory:

    $ strun # all the stories should be here


=head1 Calculator project example

Here is more detailed tutorial where we will build a test suite for calculator program.

Let's repeat it again - there are three basic outthentic entities: 

=over

=item *

suite


=item *

scenarios 


=item *

check files


=back


=head2 Project

Outthentic project is a bunch of related stories. Every project is I<represented> by a directory.

Let's create a project to test a simple calculator application:

    $ mkdir calc-app
    $ cd calc-app


=head2 Scenarios

Scenarios are just a scripts to be executed so that their output to be verified by rules defined at check files.

In other words, every story is like a small program to be executed and then gets tested ( by it's output )

Let's create two stories for our calc project. One story for `addition' operation and another for `multiplication':

    # story directories
    
    $ mkdir addition # a+b
    $ mkdir multiplication # a*b
    
    
    # scenarios
    
    $ cat  addition/story.pl
    use MyCalc;
    my $calc = MyCalc->new();
    print $calc->add(2,2), "\n";
    print $calc->add(3,3), "\n";
    
    $ cat  multiplication/story.pl
    use MyCalc;
    my $calc = MyCalc->new();
    print $calc->mult(2,3), "\n";
    print $calc->mult(3,4), "\n";


=head2 Check files

Check file contains validation rules to test script output. Every scenario B<is always accompanied by> story check file. 

Check files should be placed at the same directory as scenario and be named as C<story.check>.

Lets add some rules for `multiplication' and `addition' stories:

    $ cat addition/story.check
    4
    6
     
    $ cat multiplication/story.check
    6
    12

And finally lets run our suite:

    $ strun


=head1 Story runner

Story runner - is a script to run outthentic stories. It is called C<strun>.

Runner consequentially goes several phases:


=head2 A compilation phase. 

Stories are converted into perl files *.pl ( compilation phase ) and saved into temporary directory.


=head2 An execution phase. 

Perl executes a compiled perl file. As it was told before if not set explicitly strun looks for 
something like story.(pl|rb|bash) at the top of project root directory and then compiles it in 
regular perl script and then give it Perl to run to execute such a script.


=head1 Check files syntax

Outthentic consumes L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl>, so check files contain
rules defined in terms of Outthentic DSL - a language to validate unstructured text data.

Below some examples of check file syntax, you may learn more at Outthentic::DSL documentation.


=head2 plain strings checks

Often all you need is to ensure that stdout has some strings in:

    # scenario stdout
    
    HELLO
    HELLO WORLD
    123456
    
    
    # check file
    
    HELLO
    123
    
    # verification output
    
    OK - output matches 'HELLO'
    OK - output matches 'HELLO WORLD'
    OK - output matches '123'


=head2 regular expressions

You may use regular expressions as well:

    # check file
    
    regexp: L+
    regexp: \d
    
    
    # verification output
    
    OK - output matches /L+/
    OK - output matches /\d/

See L<check-expressions|https://github.com/melezhik/outthentic-dsl#check-expressions> in Outthentic::DSL documentation pages.


=head2 inline code, generators and asserts

You may inline code from other language to add some extra logic into your check file:


=head3 Inline code

    # check file
    
    code: <<CODE
    !bash
    echo 'this is debug message will be shown at console'
    CODE
    
    code: <<CODE
    !ruby
    puts 'this is debug message will be shown at console'
    CODE
    
    code: <<CODE
    # by default Perl language is used
    print("this is debug message will be shown at console\n");
    CODE


=head3 generators

You may generate new B<check entries> on runtime:

    # check file
    # with 2 check entries
       
    Say
    HELLO
       
    generator: <<CODE
    !bash
    
    echo say 
    echo hello 
    echo again
    
    CODE
    
    # a new check list would be:
       
    Say
    HELLO
    say
    hello
    again

Here examples on using other languages in generator expressions:

Perl:

    generator: <<CODE
    !perl
    [ 
      qw { say hello again } 
    ]
    
    CODE

Ruby:

    generator: <<CODE
    !ruby
    puts 'say'
    puts 'hello'
    puts 'again'
    
    CODE


=head3 asserts

Asserts are statements returning true of false with some extra text description.

Asserts are very powerful feature when combined with B<captures> and B<generators>:

    # scenario output
    
    ten       for 10
    twenty   for 20
    thirty    for 30
    
    # check file
    
    regexp: \w+\s+for\s(\d+)
    
    generator: <<CODE
    !ruby
      sum=0
      (captures()).each do |c|
        sum+=c.first
      end
    puts "assert: #{sum==60} sum should be 60!"
    CODE  

Follow L<code expressions|https://github.com/melezhik/outthentic-dsl#code-expressions>, L<generators|https://github.com/melezhik/outthentic-dsl#generators> and L<asserts|https://github.com/melezhik/outthentic-dsl#asserts>
in Outthentic::DSL documentation pages to learn more about code expressions, generators and asserts.


=head3 text blocks

Need to validate that some lines goes successively?

    # stdout
    
    this string followed by
    that string followed by
    another one string
    with that string
    at the very end.
    
    
    # check list
    # this text block
    # consists of 5 strings
    # goes consequentially
    # line by line:
    
    begin:
        # plain strings
        this string followed by
        that string followed by
        another one
        # regexp patterns:
    regexp: with (this|that)
        # and the last one in a block
        at the very end
    end:

See L<comments-blank-lines-and-text-blocks|https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks> in Outthentic::DSL documentation pages.


=head1 Hooks

Story hooks are extension points to change L<story runner|#story-runner> behavior. 

It's just a scripts gets executed I<before scenario script>. 

You should name your hooks as C<hook.*> and place them into story directory

    $ cat perl/hook.pl
    
    print "this is a story hook!";

Hooks could be written on one of three languages:

=over

=item *

Perl 


=item *

Ruby


=item *

Bash


=back

Here is naming convention for hook files:

    +-----------+--------------+
    | Language  | File         |
    +-----------+--------------+
    | Perl      | hook.pl      |
    | Ruby      | hook.rb      |
    | Bash      | hook.bash    |
    +-----------+--------------+

Reasons why you might need a hooks:

=over

=item *

execute some I<initialization code> before running a scenario script


=item *

redefine scenario stdout


=item *

call downstream stories


=back


=head1 Hooks API

Story hooks API provides several functions to hack into story runner execution process:


=head2 Redefine stdout

Redefining stdout feature means you define a scenario output on the hook side ( thus scenario script is never executed ). 

This might be helpful when for some reasons you do not want to run or you don't have by hand a proper scenario script.

This is simple an example:

    $ cat hook.pl
    set_stdout("THIS IS I FAKE RESPONSE \n HELLO WORLD");
    
    $ cat story.check
    THIS IS FAKE RESPONSE
    HELLO WORLD

You may call C<set_stdout()> more then once:

    set_stdout("HELLO WORLD");
    set_stdout("HELLO WORLD2");

An effective scenario stdout will be:

    HELLO WORLD
    HELLO WORLD2

Here is C<set_stdout()> function signatures list for various languages:

    +-----------+-----------------------+
    | Language  | signature             |
    +-----------+-----------------------+
    | Perl      | set_stdout(SCALAR)    |
    | Ruby      | set_stdout(STRING)    |
    | Bash      | set_stdout(STRING)    |
    +-----------+-----------------------+

IMPORTANT: You should only use a set_stdout inside story hook, not scenario file.


=head2 Upstream and downstream stories

It is possible to run one story from another with the help of downstream stories.

Downstream stories are reusable stories ( aka modules ). 

Story runner never executes downstream stories I<directly>.

Downstream story always gets called from the I<upstream> one. This is example:

    $ cat modules/knock-the-door/story.rb
    
    # this is a downstream story
    # to make story downstream
    # simply create story files 
    # in modules/ directory
    
    puts 'knock-knock!'
     
    $ cat modules/knock-the-door/story.check
    knock-knock!
    
     
    $ cat open-the-door/hook.rb
    
    # this is a upstream story
    # to run downstream story
    # call run_story function
    # inside upstream story hook
    
    # with a single parameter - story path,
    # notice that you have to remove
    # `modules/' chunk from story path parameter
    
    run_story( 'knock-the-door' );
    
    $ cat open-the-door/story.rb
    puts 'opening ...' 
    
    $ cat open-the-door/story.check
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

Summary:

=over

=item *

to make story a downstream simply create a story  in a C<modules/> directory.



=item *

to run downstream story call C<run_story(story_path)> function inside upstream story hook.



=item *

you can call as many downstream stories as you wish.



=item *

you can call the same downstream story more than once.



=item *

downstream stories in turn may call other downstream stories.



=back

Here is an example of multiple downstream story calls:

    $ mkdir module/up
    $ mkdir module/down
    $ echo 'UP!' > module/up/story.check
    $ echo 'and DOWN!' > module/down/story.check
    $ echo 'print qq{UP!}' > modules/up/story.pl 
    $ echo 'print qq{DOWN!}' > modules/down/story.pl 
    
    $ cat two-jumps/hook.pl
    
    run_story( 'up' );
    run_story( 'down' );
    run_story( 'up' );
    run_story( 'down' );


=head3 story variables 

You may pass a variables to downstream story using second argument of C<run_story()>  function. For example:

    $ mkdir modules/greeting
    
    $ cat hook.pl
    
    run_story( 
      'greeting', {  name => 'Alexey' , message => 'hello' }  
    );

Or using Ruby:

    $ cat hook.rb
    
    run_story  'greeting', {  'name' => 'Alexey' , 'message' => 'hello' }

Or Bash:

    $ cat hook.bash
    
    run_story  greeting name Alexey message hello 

Here is the C<run_story> signature list for various languages:

    +-----------+----------------------------------------------+
    | Language  | signature                                    |
    +-----------+----------------------------------------------+
    | Perl      | run_story(SCALAR,HASHREF)                    |
    | Ruby      | run_story(STRING,HASH)                       | 
    | Bash      | run_story(STORY_NAME NAME VAL NAME2 VAL2 ... | 
    +-----------+----------------------------------------------+

Story variables are accessible via C<story_var()> function. For example:

    $ cat modules/greeting/story.rb
    
    puts "#{story_var('name')} say #{story_var('message')}"

Or if you use Perl:

    $ cat modules/greeting/story.pl
    
    print (story_var('name')).'say '.(story_var('message'))

Or finally Bash (1-st way):

    $ cat modules/greeting/story.bash
    
    echo $name say $message

Bash (2-nd way):

    $ cat modules/greeting/story.bash
    
    echo $(story_var name) say $(story_var message)

You may access story variables inside story hooks and check files as well.

And finally:

=over

=item *

downstream stories may invoke other downstream stories.



=item *

you can't only use story variables inside downstream stories.



=back

Here is the how you access story variable in all three languages

    +------------------+---------------------------------------------+
    | Language         | signature                                   |
    +------------------+---------------------------------------------+
    | Perl             | story_var(SCALAR)                           |
    | Ruby             | story_var(STRING)                           | 
    | Bash (1-st way)  | $foo $bar ...                               |
    | Bash (2-nd way)  | $(story_var foo.bar)                        |
    +------------------+---------------------------------------------+


=head2 Story properties

Some story properties have a proper accessors functions. Here is the list:

=over

=item *

C<project_root_dir()> - Root directory of outthentic project.



=item *

C<test_root_dir()> - Test root directory. Root directory of generated perl test files , see also L<story runner|#story-runner>.



=item *

C<config()> - Returns suite configuration hash object. See also L<suite configuration|#suite-configuration>.



=back


=head2 Helper functions and variables

Outthentic provides some helpers and variables:

    +------------------+-----------------------------------------------------+
    | Language         | Type     | Name | Comment                           |
    +------------------+-----------------------------------------------------+
    | Perl             | function | os() | get a name of OS distribution     |
    | Bash             | variable | os   | get a name of OS distribution     |
    +------------------+-----------------------------------------------------+


=head2 Meta stories

Meta stories are special type of outthentic stories.

The essential property of meta story is it has no scenario file at all:

    # foo/bar story
    mkdir foo/bar
    
    # it's a meta story
    touch foo/bar/meta.txt

Placing a special `meta.txt' file into story directory makes that story a meta.

You may live `meta.txt' empty file or add some useful description to be printed  when story is executed:

    nano foo/bar/meta.txt
    
        This is my cool story.
        Take a look at this!

How one could use meta stories?

Meta stories are just I<containers> for other downstream stories. Usually one defines some downstream
stories call inside meta story's hook file:

    nano foo/bar/hook.pm
    
        run_story( '/story1' );
        run_story( '/story2' );

Meta stories are very similar to upstream stories with redefined stdout, with the only exclusion 
that as meta story has no scenario file there is no need for redefining a stdout.

You may also call meta stories as downstream stories:

    nano modules/foo/bar/meta.txt


=head2 Ignore unsuccessful story code

Every story is a script gets executed and thus returning an exit code. If exit code is bad (!=0)
this is treated as story verification failure. 

Use C<ignore_story_err()> function to ignore unsuccessful story code:

    $ cat hook.rb
    
    ignore_story_err 1


=head2 Story libraries

Story libraries are files to keep your libraries code to I<automatically required> into story hooks and check files context:

Here are some examples:

Perl:

    $ cat common.pm
    sub abc_generator {
      print $_, "\n" for a..z;
    } 
    
    $ cat story.check
    
    generator: <<CODE;
    !perl
      abc_generator()
    CODE

Ruby:

    $ cat common.rb
    def super_utility arg1, arg2
      # I am cool! But I do nothing!
    end
    
    $ cat hook.pl
    
    super_utility 'foo', 'bar'

Here is the list for library file names for various languages:

    +-----------+-----------------+
    | Language  | file            |
    +-----------+-----------------+
    | Perl      | common.pm       |
    | Ruby      | common.rb       |
    | Bash      | common.bash     |
    +-----------+-----------------+


=head1 Language libraries


=head2 Perl

I<PERL5LIB>

$project_root_directory/lib path gets added to $PERL5LIB variable. 

This make it easy to place custom Perl modules under project root directory:

    $ cat my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    1;
    
    $ cat common.pm
    use Foo::Bar::Baz;


=head1 Story runner client

    $ strun <options>


=head2 Options

=over

=item *

C<--root>



=back

Root directory of outthentic project. If root parameter is not set current working directory is assumed as project root directory.

=over

=item *

C<--debug> 


=back

Enable/disable debug mode:

    * Increasing debug value results in more low level information appeared at output
    
    * Default value is 0, which means no debugging 
    
    * Possible values: 0,1,2,3

=over

=item *

C<--silent> 


=back

Run in silent mode. By default strun prints all scenarios output, to disable this choose C<--silent> option.

=over

=item *

C<--purge-cache>


=back

Purge strun cache upon exit. By default C<--purge-cache> is disabled ( cache remains to allow debugging and troubleshooting ).

=over

=item *

C<--match_l> 


=back

Truncate matching strings. In a TAP output truncate matching strings to {match_l} bytes;  default value is 200.

=over

=item *

C<--story> 


=back

Run only single story. This should be path to a directory containing story inside project. A path should 
be relative against project root directory. Examples:

    # A project  with 3 stories
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

Configuration ini file path.

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

If set - disable color output. By default C<strun> prints with colors.

=over

=item *

C<--dump-config>


=back

If set - dumps a suite configuration and exit not doing any other actions. See also suite configuration section.


=head1 Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are three type of configuration files are supported:

=over

=item *

Config::General format


=item *

YAML format


=item *

JSON format


=back

Config::General  style configuration files are passed by C<--ini> parameter

    $ strun --ini /etc/suites/foo.ini
    
    $ cat /etc/suites/foo.ini
    
    <main>
    
      foo 1
      bar 2
    
    </main>

There is no special magic behind ini files, except this should be L<Config::General|https://metacpan.org/pod/Config::General> compliant configuration file.

Or you can choose YAML format for suite configuration by using C<--yaml> parameter:

    $ strun --yaml /etc/suites/foo.yaml
    
    $ cat /etc/suites/foo.yaml
    
    main :
      foo : 1
      bar : 2

Unless user sets path to configuration file explicitly by C<--ini> or C<--yaml> or C<--json>  story runner looks for the 
files named suite.ini and I<then> ( if suite.ini is not found ) for suite.yaml, suite.json at the current working directory.

If configuration file is passed and read a related configuration data is accessible via config() function, 
for example in story hook file:

    $ cat hook.pl
    
    my $foo = config()->{main}->{foo};
    my $bar = config()->{main}->{bar};

Examples for other languages:

Ruby:

    $ cat hook.rb
    
    foo = config['main']['foo']
    bar = config['main']['bar']

Bash:

    $ cat hook.bash
    
    foo=$(config main.foo )
    bar=$(config main.bar )


=head1 Runtime configuration

Runtime configuration parameters is way to override suite configuration data. Consider this example:

    $ cat suite.ini
    <foo>
      bar 10
    </foo>
      
    $ strun --param foo.bar=20

This way we will override foo.bar to value `20'.


=head1 Environment variables

=over

=item *

C<match_l> - In a suite runner output truncate matching strings to {match_l} bytes. See also C<--match_l> in L<options|#options>.



=item *

C<SPARROW_ROOT> - if set, used as prefix for test root directory.



=item *

C<SPARROW_NO_COLOR> - disable color output (see --nocolor option of C<strun>)



=back

Test root directory resolution table:

    +---------------------+----------------------+
    | Test root directory | SPARROW_ROOT Is Set? |
    +---------------------+----------------------+
    | ~/.outthentic/tmp/  | No                   |
    | $SPARROW_ROOT/tmp/  | Yes                  |
    +---------------------+----------------------+


=head1 Examples

An example outthentic project lives at examples/ directory, to run it say this:

    $ strun --root examples/


=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Home Page

L<https://github.com/melezhik/outthentic|https://github.com/melezhik/outthentic>


=head1 See also

=over

=item *

L<Sparrow|https://github.com/melezhik/sparrow> - outthentic suites manager.



=item *

L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl> - Outthentic::DSL specification.



=item *

L<Swat|https://github.com/melezhik/swat> - web testing framework consuming Outthentic::DSL.



=back


=head1 Thanks

To God as the One Who inspires me to do my job!
