package Outthentic;

our $VERSION = '0.1.0';

1;

package main;

use Carp;
use Config::General;
use YAML qw{LoadFile};
use JSON;

use strict;
use Test::More;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Outthentic::Story;

my $config; 

sub execute_cmd {
    my $cmd = shift;
    note("execute cmd: $cmd") if debug_mod2();
    (system($cmd) == 0);
}

sub config {
  $config
}

sub populate_config {

    unless ($config){
        if (get_prop('ini_file_path') and -f get_prop('ini_file_path') ){
          my $path = get_prop('ini_file_path');
          my %config  = Config::General->new($path)->getall or confess "file $path is not valid .ini file";
          $config = {%config};
        }elsif(get_prop('yaml_file_path') and -f get_prop('yaml_file_path')){
          my $path = get_prop('yaml_file_path');
          ($config) = LoadFile($path);
        }elsif ( -f 'suite.ini' ){
          my $path = 'suite.ini';
          my %config = Config::General->new($path)->getall or confess "file $path is not valid .ini file";
          $config = {%config};
        }elsif ( -f 'suite.yaml'){
          my $path = 'suite.yaml';
          ($config) = LoadFile($path);
        }else{
          $config = { };
        }
    }


    my @runtime_params = split /:::/, get_prop('runtime_params');

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

    my ($fh, $content_file) = tempfile( DIR => get_prop('test_root_dir') );

    if ( get_stdout() ){

        note("stdout is already set at ".stdout_file()) if debug_mod12;

        open F, ">", $content_file or die $!;
        print F get_stdout();
        close F;
        note("stdout saved to $content_file") if debug_mod12;

    }else{

        my $story_dir = get_prop('story_dir');
        my $story_command;
        my $story_file;

        if ( -f "$story_dir/story.pl" ){
            $story_file = "$story_dir/story.pl";
            $story_command = "perl $story_dir/story.pl";

        }elsif(-f "$story_dir/story.rb") {
            $story_file = "$story_dir/story.rb";
            my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');
            $story_command = "ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir();
            $story_command.= " $story_dir/story.rb";
        }

        if ($ENV{outth_show_story}){
            open STR, $story_file or die $!;
            my $sdata = join "", <STR>;
            close CNT;
            note("story file:\n$sdata");
        }

        my $st = execute_cmd("$story_command 1>$content_file 2>&1 && test -f $content_file");

        if ($st) {
            note("$story_command succeeded") if debug_mod12;
        }elsif(ignore_story_err()){
            note("$story_command failed, still continue due to ignore_story_err enabled");
        }else{
            ok(0, "$story_command succeeded");
            open CNT, $content_file or die $!;
            my $rdata = join "", <CNT>;
            close CNT;
            note("story output \n===>\n$rdata");
        }

        note("story output saved to $content_file") if debug_mod12;

    }

    open F, $content_file or die $!;
    my $cont = '';
    $cont.= $_ while <F>;
    close F;

    set_prop( stdout => $cont );

    my $debug_bytes = get_prop('debug_bytes');

    note `head -c $debug_bytes $content_file` if debug_mod2();

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

    populate_config();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    dsl()->{output} = run_story_file();

    eval { dsl()->validate($story_check_file) };

    my $err = $@;

    for my $r ( @{dsl()->results}){
        note($r->{message}) if $r->{type} eq 'debug';
        ok($r->{status}, $r->{message}) if $r->{type} eq 'check_expression';

    }

    confess "parser error: $err" if $err;

}

1;


__END__

=pod


=encoding utf8


=head1 Name

Outthentic


=head1 Synopsis

Generic testing, reporting, monitoring framework consuming L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl>.


=head1 Install

  $ cpanm Outthentic


=head1 Short introduction

This is a quick tutorial on outthentic usage.


=head2 Story being tested

Story is just a perl script that yields something into stdout:

    $ cat story.pl
    
    print "I am OK\n";
    print "I am outthentic\n";

Sometimes we can also call story file as scenario.


=head2 Check file

Story check is a bunch of lines stdout should match. Here we require to have `I am OK' and `I am outthentic' lines in stdout:

    $ cat story.check
    
    I am OK
    I am outthentic


=head2 Story run

Story run is process of verification of your story. A story verification is based on rules defined in story check file.

The verification process consists of:

=over

=item *

executing story file and saving stdout into file.


=item *

validating stdout against a story check.


=item *

returning result as the list of statuses, where every status relates to a single rule.


=back

See also L<story runner|#story-runner>.


=head2 Suite

A bunch of related stories is called project or suite. Sure you may have more then one story at your project.
Just create a new directories with story files inside:

    $ mkdir hello
    $ echo 'print "hello"' > hello/story.pl
    $ echo hello > hello/story.check

Now run the suite with C<strun> command:

    $ strun
    ok 1 - perl /home/vagrant/projects/outthentic/examples/hello/story.pl succeeded
    ok 2 - stdout saved to /tmp/.outthentic/29566/QKDi3p573L
    ok 3 - output match 'hello'
    1..3
    ok
    /tmp/.outthentic/29566/home/vagrant/projects/outthentic/examples/hello/world/story.t ..
    ok 1 - perl /home/vagrant/projects/outthentic/examples/hello/world/story.pl succeeded
    ok 2 - stdout saved to /tmp/.outthentic/29566/xC3wrsS195
    ok 3 - output match 'I am OK'
    ok 4 - output match 'I am outthentic'
    1..4
    ok
    All tests successful.
    Files=2, Tests=7,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.09 cusr  0.01 csys =  0.13 CPU)
    Result: PASS


=head1 Calculator project example

Here is more detailed tutorial where we will build a test suite for calculator program.

Let's repeat it again - there are three basic outthentic entities: 

=over

=item *

project ( suite )


=item *

story files ( scenarios )


=item *

story checks ( rules )


=back


=head2 Project

Outthentic project is a bunch of related stories. Every project is I<represented> by a directory.

Let's create a project to test a simple calculator application:

    $ mkdir calc-app
    $ cd calc-app


=head2 Stories

Stories are just perl scripts placed at project sub-directories and named C<story.pl>. 

Every story is a small program with stdout gets tested.

Let's create two stories for our calc project. One story for `addition' operation and another for `multiplication':

    # story directories
    
    $ mkdir addition # a+b
    $ mkdir multiplication # a*b
    
    
    # story files
    
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


=head2 Story check files

Story checks file contain validation rules for story.pl files. Every story.pl is always accompanied by 
story.check file. Story check files should be placed at the same directory as story.pl file.

Lets add some rules for multiplication and addition stories:

    $ cat addition/story.check
    4
    6
     
    $ cat multiplication/story.check
    6
    12

And finally lets run test suite:

    $ strun


=head1 Story term ambiguity

Sometimes when we speak about I<stories> we mean an elementary scenario executed by story runner and
represented by a couple of files - story.pl,story.check. In other cases we mean just a story.pl
file or even story.check given separately. The one should always take I<the context> into account when talking about stories
to avoid ambiguity.


=head1 Story runner

Story runner - is a script to run outthentic stories. It is called C<strun>.

Runner consequentially goes several phases:


=head2 A compilation phase. 

Stories are converted into perl test files *.t ( compilation phase ) and saved into temporary directory.


=head2 An execution phase. 

L<Prove|https://metacpan.org/pod/distribution/Test-Harness/bin/prove> utility recursively executes 
test files under temporary directory and thus gives a final suite execution status.

So after all outthentic project is just perl test project with *.t files inside, the difference is that
while with common test project *.t files I<are created by user>, in outthentic project *.t files I<are generated>
by story files.


=head1 Story checks syntax

Outthentic consumes L<Outthentic DSL|https://github.com/melezhik/outthentic-dsl>, so story checks are
just rules defined in terms of Outthentic DSL - a language to validate unstructured text data.

A few ( not all ) usage examples listed below.

=over

=item *

plain strings checks


=back

Often all you need is to ensure that stdout has some strings in:

    # stdout
    HELLO
    HELLO WORLD
    123456
    
    
    # check list
    HELLO
    123
    
    # validation output
    OK - output matches 'HELLO'
    OK - output matches 'HELLO WORLD'
    OK - output matches '123'

=over

=item *

regular expressions


=back

You may use regular expressions as well:

    # check list
    regexp: L+
    regexp: \d
    
    
    # validation output
    OK - output matches /L+/
    OK - output matches /\d/

See L<check-expressions|https://github.com/melezhik/outthentic-dsl#check-expressions> in Outthentic::DSL documentation pages.

=over

=item *

generators


=back

Yes you may generate new check entries on run time:

    # original check list
       
    Say
    HELLO
       
    # this generator creates 3 new check expressions:
       
    generator: [ qw{ say hello again } ]
       
    # final check list:
       
    Say
    HELLO
    say
    hello
    again

See L<generators|https://github.com/melezhik/outthentic-dsl#generators> in Outthentic::DSL documentation pages.

=over

=item *

inline perl code


=back

What about inline arbitrary perl code? Well, it's easy!

    # check list
    regexp: number: (\d+)
    validator: [ ( capture()->[0] '>=' 0 ), 'got none zero number') ];

See L<perl expressions|https://github.com/melezhik/outthentic-dsl#perl-expressions> in Outthentic::DSL documentation pages.

=over

=item *

text blocks


=back

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
            # regexps patterns:
        regexp: with (this|that)
            # and the last one in a block
            at the very end
        end:

See L<comments-blank-lines-and-text-blocks|https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks> in Outthentic::DSL documentation pages.


=head1 Hooks

Story hooks are extension points to change L<story run|#story-run> process. 

It's just files with perl code gets executed in the beginning of a story. 

You should name your hooks as C<story.pm> and place them into story directory:

    $ cat addition/story.pm
    diag "hello, I am addition story hook";
    sub is_number { [ 'regexp: ^\\d+$' ] }
     
    
    $ cat addition/story.check
    generator: is_number

Reasons why you might need a hooks:

=over

=item *

redefine story stdout


=item *

define generators


=item *

call downstream stories


=item *

other custom code


=back


=head1 Hooks API

Story hooks API provides several functions to hack into story run process:


=head2 Redefine stdout

I<set_stdout(string)>

Using set_stdout means that you never execute a story.pl to get a stdout, but instead you set stdout on your own side. 

This might be helpful when for some reasons you can't produce a stdout via story.pl file:

This is simple an example :

    $ cat story.pm
    set_stdout("THIS IS I FAKE RESPONSE\n HELLO WORLD");
    
    $ cat story.check
    THIS IS FAKE RESPONSE
    HELLO WORLD

You may call C<set_stdout()> more then once:

    set_stdout("HELLO WORLD");
    set_stdout("HELLO WORLD2");

A final stdout will be:

    HELLO WORLD
    HELLO WORLD2


=head2 Upstream and downstream stories

It is possible to run one story from another with the help of downstream stories.

Downstream stories are reusable stories or modules. 

Story runner never executes downstream stories I<directly>, instead of downstream story always gets called from the I<upstream> one:

    $ cat modules/create_calc_object/story.pm
    # this is a downstream story
    # to make story downstream
    # simply create story 
    # in modules/ directory
    use MyCalc;
    our $calc = MyCalc->new();
    set_stdout(ref($calc));
     
    $ cat modules/create_calc_object/story.check
    MyCalc
    
     
    $ cat addition/story.pm
    # this is a upstream story
    # to run downstream story
    
    # call run_story function
    # inside upstream story hook
    # with a single parameter - story path,
    # note that you don't have to
    # leave modules/ directory in the path
    
    run_story( 'create_calc_object' );
    
    # here $calc object is created by 
    # create_calc_object story
    # so we can use it!
    
    our $calc->addition(2,2);

Here are the brief comments to the example above:

=over

=item *

to make story as downstream simply create story at modules/ directory



=item *

call C<run_story(story_path)> function inside upstream story hook to run downstream story.



=item *

you can call as many downstream stories as you wish.



=item *

you can call the same downstream story more than once.



=back

Here is an example code snippet:

    $ cat story.pm
    run_story( 'some_story' )
    run_story( 'yet_another_story' )
    run_story( 'some_story' )

=over

=item *

stories variables 


=back

You may pass variables to downstream story with the second argument of C<run_story()>  function:

    run_story( 'create_calc_object', { use_floats => 1, use_complex_numbers => 1, foo => 'bar'   }  )

Story variables get accessed by  C<story_var()> function:

    $ cat create_calc_object/story.pm
    story_var('use_float');
    story_var('use_complex_numbers');
    story_var('foo');

=over

=item *

downstream stories may invoke other downstream stories



=item *

you can't use story variables in a none downstream story



=back

One word about I<sharing state> between upstream/downstream stories. 

As downstream stories get executed in the same process as upstream one there is no magic about sharing data between upstream and downstream stories.

The straightforward way to share state is to use global variables:

    # upstream story hook:
    our $state = [ 'this is upstream story' ]
    
    # downstream story hook:
    push our @$state, 'I was here'


=head2 Story variables accessors

There are some useful variables exposed by hooks API:

=over

=item *

C<project_root_dir()> - Root directory of outthentic project.



=item *

C<test_root_dir()> - Test root directory. Root directory of generated perl test files , see also L<story runner|#story-runner>.



=item *

C<config()> - Returns suite configuration hash object. See also L<suite configuration|#suite-configuration>.



=item *

C<host()> - Returns value of `--host' parameter.



=back


=head2 Ignore unsuccessful codes when run stories

Every story is a perl script gets run by perl C<system()> function returning an exit code. 

None zero exit codes result in test failures, this default behavior, to disable this say in hook file:

    $ cat story.pm
    ignore_story_err(1);


=head2 PERL5LIB

$project_root_directory/lib path gets added to $PERL5LIB variable. 

This make it easy to place custom modules under project root directory:

    $ cat my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    ...
    
    $ cat  hook.pm
    use Foo::Bar::Baz;
    ...


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

C<--match_l> 


=back

Truncate matching strings. In a TAP output truncate matching strings to {match_l} bytes;  default value is 200.

=over

=item *

C<--story> 


=back

Run only single story. This should be file path without extensions ( .pl, .check ):

    foo/story.pl
    foo/bar/story.pl
    bar/story.pl
    
    --story 'foo' # runs foo/ stories
    --story foo/story # runs foo/story.pl
    --story foo/bar/ # runs foo/bar/ stories

=over

=item *

C<--prove> 


=back

Prove parameters. See L<prove settings|#prove-settings> section for details.

=over

=item *

C<--host>


=back

This optional parameter sets base url or hostname of a service or application being tested.

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

Yaml configuration file path. 

See L<suite configuration|#suite-configuration> section for details.


=head1 Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are two type of configuration files are supported:

=over

=item *

.Ini style format


=item *

YAML format


=back

.Ini  style configuration files are passed by C<--ini> parameter

    $ strun --ini /etc/suites/foo.ini
    
    $ cat /etc/suites/foo.ini
    
    [main]
    
    foo = 1
    bar = 2

There is no special magic behind ini files, except this should be L<Config Tiny|https://metacpan.org/pod/Config::Tiny> compliant configuration file.

Or you can choose YAML format for suite configuration by using C<--yaml> parameter:

    $ strun --yaml /etc/suites/foo.yaml
    
    $ cat /etc/suites/foo.yaml
    
    main:
      foo : 1
      bar : 2

Unless user sets path to configuration file explicitly by C<--ini> or C<--yaml> story runner looks for the 
files named suite.ini and I<then> ( if suite.ini is not found ) for suite.yaml at the current working directory.

If configuration file is passed and read a related configuration data is accessible via config() function, 
for example in story hook file:

    $ cat story.pm
    
    my $foo = config()->{main}->{foo};
    my $bar = config()->{main}->{bar};


=head1 Runtime configuration

WARNING: this feature is quite experimental, needs to be tested and is could be buggy, don't use it unless this warning will be removed 

Runtime configuration parameters is way to override suite configuration data. Consider this example:

    $ cat suite.ini
    [foo]
    bar = 10
      
      
    $ strun --param foo.bar=20

This way we will override foo.bar to value `20'.

It is possible to override any data in configuration files, for example arrays values:

    $ cat suite.ini
    
    [foo]
    bar = 1
    bar = 2
    bar = 3
    
    
    $ suite --param foo.bar=11 --param foo.bar=22 --param foo.bar=33


=head1 TAP

Story runner emit results in a L<TAP|https://testanything.org/> format.

You may use your favorite TAP parser to port result to another test / reporting systems.

Follow L<TAP|https://testanything.org/> documentation to get more on this.

Here is example for having output in JUNIT format:

    strun --prove "--formatter TAP::Formatter::JUnit"


=head1 Prove settings

Story runner uses L<prove utility|https://metacpan.org/pod/distribution/Test-Harness/bin/prove> to execute generated perl tests,
you may pass prove related parameters using C<--prove-opts>. Here are some examples:

    strun --prove "-Q" # don't show anythings unless test summary
    strun --prove "-q -s" # run prove tests in random and quite mode


=head1 Environment variables

=over

=item *

C<match_l> - In a suite runner output truncate matching strings to {match_l} bytes. See also C<--match_l> in L<options|#options>.



=item *

C<outth_show_story> - If set, then content of story.pl file gets dumped in TAP output.



=back


=head1 Examples

An example outthentic project lives at examples/ directory, to run it say this:

    $ strun --root examples/


=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Home Page

https://github.com/melezhik/outthentic


=head1 See also

=over

=item *

L<Sparrow|https://github.com/melezhik/sparrow> - outthentic suites manager.



=item *

L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl> - Outthentic::DSL specification.



=item *

L<Swat|https://github.com/melezhik/swat> - web testing framework consuming Outthentic::DSL.



=item *

Perl prove, TAP, Test::More



=back


=head1 Thanks

To God as the One Who inspires me to do my job!
