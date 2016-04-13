# Name

Outthentic

# Synopsis

Generic testing, reporting, monitoring framework consuming [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl)

# Install

    cpanm Outthentic

# Short introduction

This is a quick tutorial on outthentic usage.

## Story being tested

Story is just a perl script that yields something into stdout:

    $ cat story.pl

    print "I am OK\n";
    print "I am outthentic\n";

Sometimes we can also call story file as scenario.

## Check file

Story check is a bunch of lines stdout should match. Here we require to have \`I am OK' and \`I am outthentic' lines in stdout:

    $ cat story.check

    I am OK
    I am outthentic

## Story run

Story run is process of verification of your story. A story verification is based on rules defined in story check file.

The verification process consists of:

* executing story file and saving stdout into file.
* validating stdout against a story check.
* returning result as the list of statuses, where every status relates to a single rule

See also [story runner](#story-runner) section.

## Suite

A bunch of related stories is called project or suite. Sure you may have more then one story at your project.
Just create a new directories with story files inside:

    $ mkdir hello
    $ echo 'print "hello"' > hello/story.pl
    $ echo hello > hello/story.check

Now run the suite with `strun` command:

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


# Calculator project example

Here is more detailed tutorial where we will build a test suite for calculator program.

Let's repeat it again - there are three basic outthentic entities: 

* project ( suite )
* story files ( scenarios )
* story checks ( rules )

## Project

Outthentic project is a bunch of related stories. Every project is _represented_ by a directory.

Let's create a project to test a simple calculator application:

    $ mkdir calc-app
    $ cd calc-app

## Stories

Stories are just perl scripts placed at project sub-directories and named `story.pl`. 

Every story is a small program with stdout gets tested.

Let's create two stories for our calc project. One story for \`addition' operation and another for \`multiplication':

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
 

## Story check files

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

# Story term ambiguity

Sometimes when we speak about _stories_ we mean an elementary scenario executed by story runner and
represented by a couple of files - story.pl,story.check. In other cases we mean just a story.pl
file or even story.check given separately. The one should always take _the context_ into account when talking about stories
to avoid ambiguity.


# Story runner

Story runner - is a script to run outthentic stories. It is called `strun`.

Runner consequentially goes several phases:

## A compilation phase. 

Stories are converted into perl test files *.t ( compilation phase ) and saved into temporary directory.

## An execution phase. 

[Prove](https://metacpan.org/pod/distribution/Test-Harness/bin/prove) utilty recursively executes 
test files under temporary directory and thus provide final suite execution status.

So under the hood outthentic project is just perl test project with *.t inside, the difference is that
while with common test project *.t files are created by user, in outthentic project *.t files _are generated_
by story files.
 

# Story checks syntax

Outthentic consumes [Outthentic DSL](https://github.com/melezhik/outthentic-dsl), so story checks are
just rules defined in terms of Outthentic DSL - a language to validate unstructured text data.

A few ( not all ) usage examples listed below.

* plain strings checks

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

* regular expressions

You may use regular expressions as well:


    # check list
    regexp: L+
    regexp: \d


    # validation output
    OK - output matches /L+/
    OK - output matches /\d/

See [check-expressions](https://github.com/melezhik/outthentic-dsl#check-expressions) in Outthentic::DSL
documenation pages.

* generators

Yes you may generate new check enties on run time:

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

See [generators](https://github.com/melezhik/outthentic-dsl#generators) in Outthentic::DSL
documenation pages.

   
* inline perl code

What about inline arbitrary perl code? Well, it's easy!


    # check list
    regexp: number: (\d+)
    validator: [ ( capture()->[0] '>=' 0 ), 'got none zero number') ];

See [perl expressions](https://github.com/melezhik/outthentic-dsl#perl-expressions) in Outthentic::DSL
documenation pages.

* text blocks

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

See [comments-blank-lines-and-text-blocks](https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks) in Outthentic::DSL
documenation pages.

# Hooks

Story hooks are extension points to hack into story run time phase. It's just files with perl code gets executed in the beginning of a story. You should named your hook file as \`story.pm' and place it into \`story' directory:


    # addition/story.pm
    diag "hello, I am addition story hook";
    sub is_number { [ 'regexp: ^\\d+$' ] }
 

    # addition/story.check
    generator: is_number
 

There are lot of reasons why you might need a hooks. To say a few:

* redefine story stdout
* define generators
* call downstream stories
* other custom code


# Hooks API

Story hooks API provides several functions to change story behavior at run time

## Redefine stdout

*set_stdout(string)*

Using set_stdout means that you never call a real story to get a tested data, but instead set stdout on your own side. It might be helpful when you still have no a certain knowledge of tested code to produce a stdout:

This is simple an example :

    # story.pm
    set_stdout("THIS IS I FAKE RESPONSE\n HELLO WORLD");

    # story.check
    THIS IS FAKE RESPONSE
    HELLO WORLD

You may call \`set_stdout' more then once:


    set_stdout("HELLO WORLD");
    set_stdout("HELLO WORLD2");

A final stdout will be:

    HELLO WORLD
    HELLO WORLD2

## Upstream and downstream stories

Story runner allow you to call one story from another, using notion of downstream stories.

Downstream stories are reusable stories. Runner never executes downstream stories directly, instead you have to call downstream story from _upstream_ one:

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

* to make story as downstream simply create story file at modules/ directory

* call \`run\_story(story\_path)' function inside upstream story hook to run downstream story.

* you can call as many downstream stories as you wish.

* you can call the same downstream story more than once.

Here is an example code snippet:


    # story.pm
    run_story( 'some_story' )
    run_story( 'yet_another_story' )
    run_story( 'some_story' )

* stories variables 

You may pass variables to downstream story with the second argument of \`run_story'  function:

    run_story( 'create_calc_object', { use_floats => 1, use_complex_numbers => 1, foo => 'bar'   }  )


Story variables get accessed by  \`story_var' function:

    # create_calc_object/story.pm
    story_var('use_float');
    story_var('use_complex_numbers');
    story_var('foo');


* downstream stories may invoke other downstream stories

* you can't use story variables in a none downstream story


One word about sharing state between upstream/downstream stories. As downstream stories get executed in the same process as upstream one there is no magic about sharing data between upstream and downstream stories.
The straightforward way to share state is to use global variables :

    # upstream story hook:
    our $state = [ 'this is upstream story' ]

    # downstream story hook:
    push our @$state, 'I was here'
 
Of course more proper approaches for state sharing could be used as singeltones or something else.

## Story variables accessors

There are some variables exposed to hooks API, they could be useful:

* project_root_dir()

Root directory of outthentic project.

* test_root_dir() - test root directory

Root directory of generated perl tests , see [story runner](#story-runner) section for details.

* config() - returns suite configuration hash object

See [suite configuration](#suite-configuration) section for details.

* host() 

Returns value of \`--host' parameter.

## Ignore unsuccessful codes when run stories

As every story is a perl script gets run via system call, it returns an exit code. None zero exit codes result in test failures, this default behavior , to disable this say:


    ignore_story_err(1);

## PERL5LIB

$project\_root\_directory/lib is added to PERL5LIB path, which make it easy to place 
custom modules under $project\_root\_directory'/lib directory:

    # my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    ...

    # hook.pm
    use Foo::Bar::Baz;
    ...


# Story runner client

    strun <options>
 
## Options

* `--root`  - root directory of outthentic project

If root parameter is not set current working directory is assumed as project root directory.

* `--debug` - enable/disable debug mode

    * Increasing debug value results in more low level information appeared at output

    * Default value is 0, which means no debugging 

    * Possible values: 0,1,2,3

* `--match_l` - truncate matching strings 

In a TAP output truncate matching strings to {match_l} bytes;  default value is \`200'

* `--story` -  run only single story

This should be file path without extensions ( .pl, .check ):

    foo/story.pl
    foo/bar/story.pl
    bar/story.pl

    --story 'foo' # runs foo/ stories
    --story foo/story # runs foo/story.pl
    --story foo/bar/ # runs foo/bar/ stories


* `--prove` - prove parameters

See [prove settings](#prove-settings) section for details.

* `--host` - hostname 

This optional parameter sets base url or hostname of a service or application being tested.

* `--ini' - configuration ini file path

* `--yaml'- yaml configuration file path

See [suite configuration](#suite-configuration) section for details.


# Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are two type of configuration files are supported:

* .Ini style format
* YAML format

.Ini  style configuration files are passed by \`--ini' parameter

    $ strun --ini /etc/suites/foo.ini

    $ cat /etc/suites/foo.ini

    [main]

    foo = 1
    bar = 2

There is no special magic behind ini files, except this should be [Config Tiny](https://metacpan.org/pod/Config::Tiny) compliant configuration file.

Or you can choose YAML format for suite configuration by using \`--yaml' parameter:

    $ strun --ini /etc/suites/foo.yaml

    $ cat /etc/suites/foo.yaml

    main:
      foo : 1
      bar : 2


Unless user sets path to configuration file explicitly by \`--ini' or \'--yaml' story runner looks for the 
files named suite.ini and _then_ ( if suite.ini is not found ) for suite.yaml at the current working directory.

If configuration file is passed and read a related configuration data is accessible via config() function, for example in story hook file:

    # cat story.pm

    my $foo = config()->{main}{foo};
    my $bar = config()->{main}{bar};

# TAP

Outthentic produces output in [TAP](https://testanything.org/) format, that means you may use your favorite tap parser to bring result to another test / reporting systems, follow TAP documentation to get more on this.

Here is example for having output in JUNIT format:

    strun --prove "--formatter TAP::Formatter::JUnit"

# Prove settings

Outthentic utilize [prove utility](http://search.cpan.org/perldoc?prove) to execute tests, one my pass prove related parameters using \`--prove-opts'. Here are some examples:

    strun --prove "-Q" # don't show anythings unless test summary
    strun --prove "-q -s" # run prove tests in random and quite mode

# Environment variables

* `match_l` - in TAP output truncate matching strings to {match_l} bytes

See also \`--match_l' in [options](#options) section

* `outth_show_story` - if set, then content of story.pl file gets dumped in TAP output

# Examples

An example outthentic project lives at examples/ directory, to run it say this:


    $ strun --root examples/

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

https://github.com/melezhik/outthentic

# See also

* [sparrow](https://github.com/melezhik/sparrow) - outthentic suites manager.

* [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl) - Outthentic::DSL specification.

* [swat](https://github.com/melezhik/swat) - web testing framework consuming Outthentic::DSL.


# Thanks

* to God as - *For the LORD giveth wisdom: out of his mouth cometh knowledge and understanding. (Proverbs 2:6)*

* to the Authors of : perl, TAP, Test::More, Test::Harness
