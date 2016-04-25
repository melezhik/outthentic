# Name

Outthentic

# Synopsis

Generic testing, reporting, monitoring framework consuming [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl).

# Install

  $ cpanm Outthentic

# Short introduction

This is a quick tutorial on outthentic usage.

## Story being tested

Story is just a script that yields something into stdout.

Perl story example:

    $ cat story.pl

    print "I am OK\n";
    print "I am outthentic\n";

Ruby story example:

    $ cat story.rb

    puts "I am OK"
    puts "I am outthentic"

Sometimes we can also call story file as scenario.

Story could be written on Perl or Ruby:


    | Language  | File      |
    ------------+------------
    | Perl      | story.pl  |
    | Ruby      | story.rb  |
  

## Check file

Story check is a bunch of lines stdout should match. Here we require to have \`I am OK' and \`I am outthentic' lines in stdout:

    $ cat story.check

    I am OK
    I am outthentic

## Story run

Story run is process of verification of your story. A story verification is based on rules defined in story check file.

The verification process consists of:

* executing story script and saving stdout into file.
* validating stdout against a story check.
* returning result as the list of statuses, where every status relates to a single rule.

See also [story runner](#story-runner).

## Suite

A bunch of related stories is called project or suite. Sure you may have more then one story at your project.
Just create a new directories with stories inside:

    $ mkdir perl
    $ echo 'print "hello from perl";' > perl/story.pl
    $ echo 'hello from perl' > perl/story.check
    $ mkdir ruby
    $ echo 'puts "hello from ruby"' > ruby/story.rb
    $ echo 'hello from ruby' > ruby/story.check

`strun` is a command to run stories:

    $ strun 
    /tmp/.outthentic/3359/home/melezhik/projects/outthentic-dsl-examples/perl-and-ruby/perl/story.t ..
    ok 1 - output match 'hello from perl'
    1..1
    ok
    /tmp/.outthentic/3359/home/melezhik/projects/outthentic-dsl-examples/perl-and-ruby/ruby/story.t .. 
    ok 1 - output match 'hello from ruby'
    1..1
    ok
    All tests successful.
    Files=2, Tests=2,  0 wallclock secs ( 0.01 usr  0.01 sys +  0.07 cusr  0.02 csys =  0.11 CPU)
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

## Story scripts

Stories are just a scripts to be executed and then resulted stdout is analyzed by rules defined at check files.

Thus every story is a small program with some stdout gets tested.

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
 

## Check files

Story check file contains validation rules to test script output. Every story script is always accompanied by story check file. 

Story check files should be placed at the same directory as story script and be named as `story.check`.

Lets add some rules for \`multiplication' and \`addition' stories:

    $ cat addition/story.check
    4
    6
 
    $ cat multiplication/story.check
    6
    12
 

And finally lets run test suite:

    $ strun

# Story runner

Story runner - is a script to run outthentic stories. It is called `strun`.

Runner consequentially goes several phases:

## A compilation phase. 

Stories are converted into perl test files \*.t ( compilation phase ) and saved into temporary directory.

## An execution phase. 

[Prove](https://metacpan.org/pod/distribution/Test-Harness/bin/prove) utility recursively executes 
test files under temporary directory and thus gives a final suite execution status.

So after all outthentic project is just perl test project with \*.t files inside, the difference is that
while with common test project \*.t files _are created by user_, in outthentic project \*.t files _are generated_
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

See [check-expressions](https://github.com/melezhik/outthentic-dsl#check-expressions) in Outthentic::DSL documentation pages.

* generators

Yes you may generate new check entries on run time:

    # original check list
   
    Say
    HELLO
   
    # check list
    # this generator creates 3 new check expressions:
    generator: <<CODE
    !perl

    print "say\n";
    print "hello\n";
    print "again\n";

    CODE

    # final check list:
   
    Say
    HELLO
    say
    hello
    again

You may use many languages in generator expressions:

Bash:

    generator: <<CODE
    !bash
    echo say
    echo hello
    echo again

    CODE

Ruby:

    generator: <<CODE
    !ruby
    puts 'say'
    puts 'hello'
    puts 'again'

    CODE

Follow [generators](https://github.com/melezhik/outthentic-dsl#generators) in Outthentic::DSL documentation pages
to get more.

* inline code

What about inline arbitrary code? Well, it's easy!


    # check list
    regexp: number: (\d+)

    validator: <<CODE
    !perl
        print capture()->[0] '>=' 0, ' ', 'got none zero number' 
    CODE

    code: <<CODE
    !ruby
        puts '# I like Ruby as well'
    CODE

Follow [perl-expressions](https://github.com/melezhik/outthentic-dsl#perl-expressions), [validators](https://github.com/melezhik/outthentic-dsl#validators) and
[Inline code from other languages](https://github.com/melezhik/outthentic-dsl#inline-code-from-other-languages) in Outthentic::DSL documentation pages to get more.


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

See [comments-blank-lines-and-text-blocks](https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks) in Outthentic::DSL documentation pages.

# Hooks

Story hooks are extension points to change [story run](#story-run) process. 

It's just a scripts  gets executed _in the beginning_ of a story. 
  
You should name your hooks as `hook.*` and place them into story directory


    $ cat perl/hook.pl
    
    print "this is a story hook!";

Hooks could be written on Perl or Ruby:


    | Language  | File      |
    ------------+------------
    | Perl      | hook.pl   |
    | Ruby      | hook.rb   |

Reasons why you might need a hooks:

* execute story initialization code
* redefine story stdout
* call downstream stories


# Hooks API

Story hooks API provides several functions to hack into story run process:

## Redefine stdout

Redefining stdout feature means you define a story output on the hook side ( thus story script is not executed ). 

This might be helpful when for some reasons you do not want provide story script.

This is simple an example:

    $ cat hook.pl
    set_stdout("THIS IS I FAKE RESPONSE \n HELLO WORLD");

    $ cat story.check
    THIS IS FAKE RESPONSE
    HELLO WORLD

You may call `set_stdout()` more then once:

    set_stdout("HELLO WORLD");
    set_stdout("HELLO WORLD2");

A final stdout will be:

    HELLO WORLD
    HELLO WORLD2

Here is `set_stdout()` function signatures list for various languages:

    | Language  | signature             |
    ------------+------------------------
    | Perl      | set_stdout($SCALAR)   |
    | Ruby      | set_stdout(STRING)    |


## Upstream and downstream stories

It is possible to run one story from another with the help of downstream stories.

Downstream stories are reusable stories ( modules ). 

Story runner never executes downstream stories _directly_.

Downstream story always gets called from the _upstream_ one:

    $ cat modules/knock-the-door/story.rb

    # this is a downstream story
    # to make story downstream
    # simply create story 
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
    # note that you don't have to
    # leave modules/ directory in the path

    run_story( 'knock-the-door' );

    $ cat open-the-door/story.rb
    puts 'opening ...' 

    $ cat open-the-door/story.check
    opening
 
    $ strun 
    /tmp/.outthentic/3815/home/melezhik/projects/outthentic-dsl-examples/downstream/open-the-door/story.t .. 
    ok 1 - output match 'knock-knock!'
    ok 2 - output match 'opening'
    1..2
    ok
    All tests successful.
    Files=1, Tests=2,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.05 cusr  0.01 csys =  0.08 CPU)
    Result: PASS
    
Here are the brief comments to the example above:

* to make story as downstream simply create a story in `modules/` directory.

* to run downstream story call `run_story(story_path)` function inside upstream story hook.

* you can call as many downstream stories as you wish.

* you can call the same downstream story more than once.

Here is an example of multiple downstream stories calls:


    $ cat two-jumps/hook.pl

    run_story( 'up' );
    run_story( 'down' );
    run_story( 'up' );
    run_story( 'down' );

* story variables 

You may pass variables to downstream story with the second argument of `run_story()`  function:


    # cat hook.pl

    run_story( 
      'greeting', {  name => 'Alexey' , message => 'hello' }  
    );



Story variables are accessed by  calling `story_var()` function inside downstream story hook:

    $ cat hook.pl

    story_var('name');
    story_var('message');

Here is the `run_story` signature list for various languages:


    | Language  | signature                     | comment                                 |
    ------------+-------------------------------+-----------------------------------------+
    | Perl      | run_story($SCALAR,$HASHREF)   |                                         |
    | Ruby      | run_story(STRING)             | passing story variables not implemented |


And finally:

* downstream stories may invoke other downstream stories.

* you can't only use story variables inside downstream stories.

## Story properties

Some story properties have a proper accessors functions. Here is the list:


* `project_root_dir()` - Root directory of outthentic project.

* `test_root_dir()` - Test root directory. Root directory of generated perl test files , see also [story runner](#story-runner).

* `config()` - Returns suite configuration hash object. See also [suite configuration](#suite-configuration).

* `host()` - Returns value of \`--host' parameter.

## Ignore unsuccessful story code

Every story is a script gets executed and thus returning an exit code. If exit code is bad (!=0)
this is treated as story verification failure. 

Use `ignore_story_err()` function to ignore unsuccessful story code:

    $ cat hook.rb

    ignore_story_err 1

## Story libraries

Story libraries are files to keep your libraries code to _automatically required_ into story hooks and check files context:

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

    | Language  | file        |
    ------------+--------------
    | Perl      | common.pm   |
    | Ruby      | common.rb   |
    
# Language libraries

## Perl

*PERL5LIB*

$project\_root\_directory/lib path gets added to $PERL5LIB variable. 

This make it easy to place custom Perl modules under project root directory:

    $ cat my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    1;

    $ cat common.pm
    use Foo::Bar::Baz;

# Story runner client

    $ strun <options>
 
## Options

* `--root`  

Root directory of outthentic project. If root parameter is not set current working directory is assumed as project root directory.

* `--debug` 

Enable/disable debug mode:

    * Increasing debug value results in more low level information appeared at output

    * Default value is 0, which means no debugging 

    * Possible values: 0,1,2,3

* `--match_l` 

Truncate matching strings. In a TAP output truncate matching strings to {match_l} bytes;  default value is 200.

* `--story` 

Run only single story. This should be file path without extensions ( .pl, .rb, .check ):

    foo/story.pl
    foo/bar/story.rb
    bar/story.pl

    --story foo # runs foo/ stories
    --story foo/story # runs foo/story.pl
    --story foo/bar/ # runs foo/bar/ stories


* `--prove` 

Prove parameters. See [prove settings](#prove-settings) section for details.

* `--host`

This optional parameter sets base url or hostname of a service or application being tested.

* `--ini`  

Configuration ini file path.

See [suite configuration](#suite-configuration) section for details.

* `--yaml` 

Yaml configuration file path. 

See [suite configuration](#suite-configuration) section for details.


# Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are two type of configuration files are supported:

* .Ini style format
* YAML format

.Ini  style configuration files are passed by `--ini` parameter

    $ strun --ini /etc/suites/foo.ini

    $ cat /etc/suites/foo.ini

    [main]

    foo = 1
    bar = 2

There is no special magic behind ini files, except this should be [Config Tiny](https://metacpan.org/pod/Config::Tiny) compliant configuration file.

Or you can choose YAML format for suite configuration by using `--yaml` parameter:

    $ strun --yaml /etc/suites/foo.yaml

    $ cat /etc/suites/foo.yaml

    main:
      foo : 1
      bar : 2


Unless user sets path to configuration file explicitly by `--ini` or `--yaml` story runner looks for the 
files named suite.ini and _then_ ( if suite.ini is not found ) for suite.yaml at the current working directory.

If configuration file is passed and read a related configuration data is accessible via config() function, 
for example in story hook file:

    $ cat hook.pl

    my $foo = config()->{main}->{foo};
    my $bar = config()->{main}->{bar};

# Runtime configuration

WARNING: this feature is quite experimental, needs to be tested and is could be buggy, don't use it unless this warning will be removed 

Runtime configuration parameters is way to override suite configuration data. Consider this example:


    $ cat suite.ini
    [foo]
    bar = 10
  
  
    $ strun --param foo.bar=20
  
This way we will override foo.bar to value \`20'.


It is possible to override any data in configuration files, for example arrays values:


    $ cat suite.ini
    
    [foo]
    bar = 1
    bar = 2
    bar = 3
    
    
    $ suite --param foo.bar=11 --param foo.bar=22 --param foo.bar=33
    

# TAP

Story runner emit results in a [TAP](https://testanything.org/) format.

You may use your favorite TAP parser to port result to another test / reporting systems.

Follow [TAP](https://testanything.org/) documentation to get more on this.

Here is example for having output in JUNIT format:

    strun --prove "--formatter TAP::Formatter::JUnit"

# Prove settings

Story runner uses [prove utility](https://metacpan.org/pod/distribution/Test-Harness/bin/prove) to execute generated perl tests,
you may pass prove related parameters using `--prove-opts`. Here are some examples:

    strun --prove "-Q" # don't show anythings unless test summary
    strun --prove "-q -s" # run prove tests in random and quite mode

# Environment variables

* `match_l` - In a suite runner output truncate matching strings to {match_l} bytes. See also `--match_l` in [options](#options).

* `outth_show_story` - If set, then content of story.pl file gets dumped in TAP output.

# Examples

An example outthentic project lives at examples/ directory, to run it say this:

    $ strun --root examples/

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

https://github.com/melezhik/outthentic

# See also

* [Sparrow](https://github.com/melezhik/sparrow) - outthentic suites manager.

* [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl) - Outthentic::DSL specification.

* [Swat](https://github.com/melezhik/swat) - web testing framework consuming Outthentic::DSL.

* Perl prove, TAP, Test::More

# Thanks

To God as the One Who inspires me to do my job!


