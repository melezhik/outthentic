package Outthentic;

our $VERSION = '0.0.10';


1;

package main;

use Carp;
use Config::Tiny;

use strict;
use Test::More;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Outthentic::Story;

my $config; 

sub execute_cmd {
    my $cmd = shift;
    diag("execute cmd: $cmd") if debug_mod2();
    (system($cmd) == 0);
}

sub config {

    unless ($config){
        $config = Config::Tiny->read( $ENV{'suite_ini_file'} || 'suite.ini' );
    }
    return $config;
}

sub run_story_file {

    return get_prop('stdout') if defined get_prop('stdout');

    my ($fh, $content_file) = tempfile( DIR => get_prop('test_root_dir') );

    if (get_prop('my_stdout')){

        ok(1,"stdout is already set");

        open F, ">", $content_file or die $!;
        print F (join "\n", @{get_prop('my_stdout')});
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

    my $project = project_root_dir();
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

sub generate_asserts {

    my $story_check_file = shift;

    header() if debug_mod12();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    dsl()->{output} = run_story_file();

    eval { dsl()->validate($story_check_file) };

    my $err = $@;

    for my $r ( @{dsl()->results}){
        ok($r->{status}, $r->{message}) if $r->{type} eq 'check_expression';
        diag($r->{message}) if $r->{type} eq 'debug';

    }

    confess "parser error: $err" if $err;

}

1;


__END__

=encoding utf8


=head1 Outthentic

print something into stdout and test


=head1 Synopsis

Outthentic is a text oriented test framework. Instead of hack into objects and methods it deals with text appeared in stdout. It's a black box testing framework.


=head1 Install

    cpanm Outthentic


=head1 Short story

This is a five minutes tutorial on outthentic framework workflow.

=over

=item *

Create a story file 


=back

Story is just an any perl script that yields something into stdout:

    # story.pl
    
    print "I am OK\n";
    print "I am outthentic\n";

=over

=item *

Create a story check file


=back

Story check is a bunch of lines stdout should match. Here we require to have `I am OK' and `I am outthentic' lines in stdout:

    # story.check
    
    I am OK
    I am outthentic

=over

=item *

Run a story


=back

Story runner is script that parses and then executes stories, it:

=over

=item *

finds and executes story files.


=item *

remembers stdout.


=item *

validates stdout against a story checks content.


=back

Follow L<story runner|#story-runner> section for details on story runner "guts".

To execute story runner say `strun':

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


=head1 Long story

Here is a step by step explanation of outthentic project layout. We explain here basic outthentic entities:

=over

=item *

project


=item *

stories


=item *

story checks


=back


=head2 Project

Outthentic project is bunch of related stories. Every project is I<represented> by a directory where all the stuff is placed at.

Let's create a project to test a simple calculator application:

    mkdir calc-app
    cd calc-app


=head2 Stories

Stories are just perl scripts placed at project directory and named `story.pl'. In a testing context, stories are pieces of logic to be testsed.

Think about them like `*.t' files in a perl unit test system.

To tell one story file from another one should keep them in different directories.

Let's create two stories for our calc project. One story to represent addition operation and other for addition operation:

    # let's create story directories
    mkdir addition # a+b
    mkdir multiplication # a*b
    
    
    # then create story files
    # addition/story.pl
    use MyCalc;
    my $calc = MyCalc->new();
    print $calc->add(2,2), "\n";
    print $calc->add(3,3), "\n";
    
    # multiplication/story.pl
    use MyCalc;
    my $calc = MyCalc->new();
    print $calc->mult(2,3), "\n";
    print $calc->mult(3,4), "\n";


=head2 Story check files

Story check files (or short form story checks)  are files that contain lines for validation of stdout from story scripts.

Story checks should be placed at the same directory as story file and named `story.check'.

Following are story check for a multiplication and addition stories:

    # addition/story.check
    4
    6
     
    # multiplication/story.check
    6
    12

Now we ready to invoke a story runner:

    $ strun


=head1 Story term ambiguity

Sometimes term `story' refers to a couple of files representing story unit - story.pl and story.check,
in other cases this term refers to a single story file - story.pl.


=head1 Story runner

This is detailed explanation of story runner life cycle.

Story runner script consequentially hits two phases:

=over

=item *

stories are converted into perl test files ( compilation phase )


=item *

perl test files are recursively executed by prove ( execution phase )


=back

Generating Test::More asserts sequence

=over

=item *

for every story found:

=over

=item *

new instance of Outthentic::DSL object (ODO) is created 


=item *

story check file passed to ODO


=item *

story file is executed and it's stdout passed to ODO


=item *

ODO makes validation of given stdout against given story check file


=item *

validation results are turned into a I<sequence> of Test::More ok() asserts


=back



=back


=head2 Time diagram

This is a time diagram for story runner life cycle:

=over

=item *

Hits compilation phase



=item *

For every story and story check file found:

=over

=item *

Creates a perl test file


=back



=item *

The end of compilation phase



=item *

Hits execution phase - runs `prove' recursively on a directory with a perl test files



=item *

For every perl test file gets executed:

=over

=item *

Test::More asserts sequence is generated


=back



=item *

The end of execution phase



=back


=head1 Story checks syntax

Story checks syntax complies L<Outthentic DSL|https://github.com/melezhik/outthentic-dsl> format.

There are lot of possibilities here!

( For full explanation of outthentic DSL please follow L<documentation|https://github.com/melezhik/outthentic-dsl>. )

A few examples:

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

Follow L<https://github.com/melezhik/outthentic-dsl#check-expressions|https://github.com/melezhik/outthentic-dsl#check-expressions> to know more.

=over

=item *

generators


=back

Yes you may generate new check list on run time:

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

Follow L<https://github.com/melezhik/outthentic-dsl#generators|https://github.com/melezhik/outthentic-dsl#generators> to know more.

=over

=item *

inline perl code


=back

What about inline arbitrary perl code? Well, it's easy!

    # check list
    regexp: number: (\d+)
    validator: [ ( capture()->[0] '>=' 0 ), 'got none zero number') ];

Follow L<https://github.com/melezhik/outthentic-dsl#perl-expressions|https://github.com/melezhik/outthentic-dsl#validators> to know more.

=over

=item *

text blocks


=back

Need to valiade that some lines goes successively?

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

Follow L<https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks|https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks>
to know more.


=head1 Hooks

Story Hooks are extension points to hack into story run time phase. It's just files with perl code gets executed in the beginning of a story. You should named your hook file as `story.pm' and place it into `story' directory:

    # addition/story.pm
    diag "hello, I am addition story hook";
    sub is_number { [ 'regexp: ^\\d+$' ] }
     
    
    # addition/story.check
    generator: is_number

There are lot of reasons why you might need a hooks. To say a few:

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

Story hooks API provides several functions to change story behavior at run time


=head2 Redefine stdout

I<set_stdout(string)>

Using set_stdout means that you never call a real story to get a tested data, but instead set stdout on your own side. It might be helpful when you still have no a certain knowledge of tested code to produce a stdout:

This is simple an example :

    # story.pm
    set_stdout("THIS IS I FAKE RESPONSE\n HELLO WORLD");
    
    # story.check
    THIS IS FAKE RESPONSE
    HELLO WORLD


=head2 Upstream and downstream stories

Story runner allow you to call one story from another, using notion of downstream stories.

Downstream stories are reusable stories. Runner never executes downstream stories directly, instead you have to call downstream story from I<upstream> one:

    # modules/create_calc_object/story.pl
    # this is a downstream story
    # to make story downstream
    # simply create story file
    # in modules/ directory
    use MyCalc;
    our $calc = MyCalc->new();
    print ref($calc), "\n"
     
    # modules/create_calc_object/story.check
    MyCalc
    
    # addition/story.pl
    # this is a upstream story
    our $calc->addition(2,2);
     
    # addition/story.pm
    # to run downstream story
    # call run_story function
    # inside upstream story hook
    # with a single parameter - story path,
    # note that you don't have to
    # leave modules/ directory in the path
    run_story( 'create_calc_object' );
     
     
    # multiplication/story.pl
    # this is a upstream story too
    our $calc->multiplication(2,2);
     
    # multiplication/story.pm
    run_story( 'create_calc_object' );

Here are the brief comments to the example above:

=over

=item *

to make story as downstream simply create story file at modules/ directory



=item *

call `run_story(story_path)' function inside upstream story hook to run downstream story.



=item *

you can call as many downstream stories as you wish.



=item *

you can call the same downstream story more than once.



=back

Here is an example code snippet:

    # story.pm
    run_story( 'some_story' )
    run_story( 'yet_another_story' )
    run_story( 'some_story' )

=over

=item *

stories variables 


=back

You may pass variables to downstream story with the second argument of `run_story'  function:

    run_story( 'create_calc_object', { use_floats => 1, use_complex_numbers => 1, foo => 'bar'   }  )

Story variables get accessed by  `story_var' function:

    # create_calc_object/story.pm
    story_var('use_float');
    story_var('use_complex_numbers');
    story_var('foo');

=over

=item *

downstream stories may invoke other downstream stories



=item *

you can't use story variables in a none downstream story



=back

One word about sharing state between upstream/downstream stories. As downstream stories get executed in the same process as upstream one there is no magic about sharing data between upstream and downstream stories.
The straightforward way to share state is to use global variables :

    # upstream story hook:
    our $state = [ 'this is upstream story' ]
    
    # downstream story hook:
    push our @$state, 'I was here'

Of course more proper approaches for state sharing could be used as singeltones or something else.


=head2 Story variables accessors

There are some variables exposed to hooks API, they could be useful:

=over

=item *

projectI<root>dir() - root directory of outthentic project



=item *

testI<root>dir() - root directory of generated perl tests , see L<story runner|#story-runner> section



=back


=head2 Ignore unsuccessful codes when run stories

As every story is a perl script gets run via system call, it returns an exit code. None zero exit codes result in test failures, this default behavior , to disable this say:

    ignore_story_err(1);


=head2 PERL5LIB

`project_root_directory'/lib is added to PERL5LIB path, 
which make it easy to place some custom modules under `project_root_directory'/lib directory:

    # my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    ...
    
    # hook.pm
    use Foo::Bar::Baz;
    ...


=head1 Story runner client

    strun <options>


=head2 Options

=over

=item *

C<--root>  - root directory of outthentic project, if not set story runner starts with current working directory



=item *

C<--debug> - enable outthentic debugging

=over

=item *

Increasing debug value results in more low level information appeared at output



=item *

Default value is 0, which means no debugging 



=item *

Possible values: 0,1,2,3



=back



=item *

C<--match_l> - in TAP output truncate matching strings to {match_l} bytes;  default value is `30'



=item *

C<--story> -  run only single story, this should be file path without extensions (.pl,.check):

  foo/story.pl
  foo/bar/story.pl
  bar/story.pl

  --story 'foo' # runs foo/I< stories
  --story foo/story # runs foo/story.pl
  --story foo/bar/ # runs foo/bar/> stories



=item *

C<--prove-opts> - prove parameters, see L<prove settings|#prove-settings> section



=back


=head1 TAP

Outthentic produces output in L<TAP|https://testanything.org/> format, that means you may use your favorite tap parser to bring result to another test / reporting systems, follow TAP documentation to get more on this.

Here is example for having output in JUNIT format:

    strun --prove_opts "--formatter TAP::Formatter::JUnit"


=head1 Prove settings

Outthentic utilize L<prove utility|http://search.cpan.org/perldoc?prove> to execute tests, one my pass prove related parameters using `--prove-opts'. Here are some examples:

    strun --prove_opts "-Q" # don't show anythings unless test summary
    strun --prove_opts "-q -s" # run prove tests in random and quite mode


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

L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl>


=item *

L<swat|https://github.com/melezhik/swat> 


=back


=head1 Thanks

=over

=item *

to God as - I<For the LORD giveth wisdom: out of his mouth cometh knowledge and understanding. (Proverbs 2:6)>



=item *

to the Authors of : perl, TAP, Test::More, Test::Harness



=back
