# Name

Outthentic

# Synopsis

Multipurpose scenarios framework.

# Build status

[![Build Status](https://travis-ci.org/melezhik/outthentic.svg)](https://travis-ci.org/melezhik/outthentic)


# Install

    $ cpanm Outthentic

# Short introduction

This is a quick tutorial on outthentic usage.

## Run your scenarios

Scenario is just a script that you **run** and that yields something into **stdout**.

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

* Perl 
* Ruby
* Bash

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
  

## Check file

Check file contains rules to **verify** a stdout produced by scenario script. 

Here we require that our scenario should produce  \`I am OK' and \`I am outthentic' lines in stdout:

    $ cat story.check

    I am OK
    I am outthentic

## Story

Outthentic story is a scenarios + check file. When outthentic **run** story it:

* executes scenario script and saves stdout into file.
* verifies stdout against a check file

See also [story runner](#story-runner).

## Suite

Outthentic suite is a bunch of related stories. You may also call suite as projects.

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

Now, let's use `strun` command to run suite:

    $ strun

    /tmp/.outthentic/19311/home/melezhik/projects/outthentic-demo/bash-story/story.t .. 
    ok 1 - output match 'hello from bash'
    1..1
    ok
    /tmp/.outthentic/19311/home/melezhik/projects/outthentic-demo/perl-story/story.t .. 
    ok 1 - output match 'hello from perl'
    1..1
    ok
    /tmp/.outthentic/19311/home/melezhik/projects/outthentic-demo/ruby-story/story.t .. 
    ok 1 - output match 'hello from ruby'
    1..1
    ok
    All tests successful.
    Files=3, Tests=3,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.18 cusr  0.04 csys =  0.24 CPU)
    Result: PASS


Summary:

* Stories are executed independently, means *generally* one story **is not dependent upon** another story (but see "downstream stories section").        

* Outthentic suite is bunch of related scenarios ( one or many ) to **be run** and to **be verified** ( by analyzing scenarios output against rules )

* strun - suite runner - produces result in [TAP](https://testanything.org/) format, which is  is a simple text-based interface between testing modules in a test harness.

# Calculator project example

Here is more detailed tutorial where we will build a test suite for calculator program.

Let's repeat it again - there are three basic outthentic entities: 

* suite
* scenarios 
* check files

## Project

Outthentic project is a bunch of related stories. Every project is _represented_ by a directory.

Let's create a project to test a simple calculator application:

    $ mkdir calc-app
    $ cd calc-app

## Scenarios

Scenarios are just a scripts to be executed so that their output to be verified by rules defined at check files.

In other words, every story is like a small program to be executed and then gets tested ( by it's output )

Let's create two stories for our calc project. One story for \`addition' operation and another for \`multiplication':

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
 

## Check files

Check file contains validation rules to test script output. Every scenario **is always accompanied by** story check file. 

Check files should be placed at the same directory as scenario and be named as `story.check`.

Lets add some rules for \`multiplication' and \`addition' stories:

    $ cat addition/story.check
    4
    6
 
    $ cat multiplication/story.check
    6
    12
 

And finally lets run our suite:

    $ strun

# Story runner

Story runner - is a script to run outthentic stories. It is called `strun`.

Runner consequentially goes several phases:

## A compilation phase. 

Stories are converted into perl test files \*.t ( compilation phase ) and saved into temporary directory.

## An execution phase. 

[Prove](https://metacpan.org/pod/distribution/Test-Harness/bin/prove) utility recursively executes 
test files under temporary directory and thus produces a **final suite execution status**.

So, after all outthentic project *is very like* a perl test project with \*.t files inside, with the difference that
outthentic \*.t files *are generated  by story files* dynamically.

 
# Check files syntax

Outthentic consumes [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl), so check files contain
rules defined in terms of Outthentic DSL - a language to validate unstructured text data.

Below some examples of check file syntax, you may learn more at Outthentic::DSL documentation.

## plain strings checks

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

## regular expressions

You may use regular expressions as well:


    # check file

    regexp: L+
    regexp: \d


    # verification output

    OK - output matches /L+/
    OK - output matches /\d/

See [check-expressions](https://github.com/melezhik/outthentic-dsl#check-expressions) in Outthentic::DSL documentation pages.

## inline code, generators and asserts

You may inline code from other language to add some extra logic into your check file:

### Inline code

    # check file

    code: <<CODE
    !bash
    echo '# this is debug message will be shown at console'
    CODE

    code: <<CODE
    !ruby
    puts '# this is debug message will be shown at console'
    CODE

    code: <<CODE
    # by default Perl language is used
    note('this is debug message will be shown at console')
    CODE

### generators

You may generate new **check entries** on runtime:

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


###  asserts

Asserts are statements returning true of false with some extra text description.

Asserts are very powerful feature when combined with **captures** and **generators**:


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
    

Follow [code expressions](https://github.com/melezhik/outthentic-dsl#code-expressions), [generators](https://github.com/melezhik/outthentic-dsl#generators) and [asserts](https://github.com/melezhik/outthentic-dsl#asserts)
in Outthentic::DSL documentation pages to learn more about code expressions, generators and asserts.


### text blocks

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

Story hooks are extension points to change [story runner](#story-runner) behavior. 

It's just a scripts gets executed _before scenario script_. 
  
You should name your hooks as `hook.*` and place them into story directory


    $ cat perl/hook.pl
    
    print "this is a story hook!";

Hooks could be written on one of three languages:

* Perl 
* Ruby
* Bash

Here is naming convention for hook files:


    +-----------+--------------+
    | Language  | File         |
    +-----------+--------------+
    | Perl      | hook.pl      |
    | Ruby      | hook.rb      |
    | Bash      | hook.bash    |
    +-----------+--------------+

Reasons why you might need a hooks:

* execute some *initialization code* before running a scenario script
* redefine scenario stdout
* call downstream stories


# Hooks API

Story hooks API provides several functions to hack into story runner execution process:

## Redefine stdout

Redefining stdout feature means you define a scenario output on the hook side ( thus scenario script is never executed ). 

This might be helpful when for some reasons you do not want to run or you don't have by hand a proper scenario script.

This is simple an example:

    $ cat hook.pl
    set_stdout("THIS IS I FAKE RESPONSE \n HELLO WORLD");

    $ cat story.check
    THIS IS FAKE RESPONSE
    HELLO WORLD

You may call `set_stdout()` more then once:

    set_stdout("HELLO WORLD");
    set_stdout("HELLO WORLD2");

An effective scenario stdout will be:

    HELLO WORLD
    HELLO WORLD2

Here is `set_stdout()` function signatures list for various languages:

    +-----------+-----------------------+
    | Language  | signature             |
    +-----------+-----------------------+
    | Perl      | set_stdout(SCALAR)    |
    | Ruby      | set_stdout(STRING)    |
    | Bash      | set_stdout(STRING)    |
    +-----------+-----------------------+

IMPORTANT: You should only use a set\_stdout inside story hook, not scenario file.


## Upstream and downstream stories

It is possible to run one story from another with the help of downstream stories.

Downstream stories are reusable stories ( aka modules ). 

Story runner never executes downstream stories _directly_.

Downstream story always gets called from the _upstream_ one. This is example:

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
 
    $ strun 
    /tmp/.outthentic/3815/home/melezhik/projects/outthentic-dsl-examples/downstream/open-the-door/story.t .. 
    ok 1 - output match 'knock-knock!'
    ok 2 - output match 'opening'
    1..2
    ok
    All tests successful.
    Files=1, Tests=2,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.05 cusr  0.01 csys =  0.08 CPU)
    Result: PASS
    
Summary:

* to make story a downstream simply create a story  in a `modules/` directory.

* to run downstream story call `run_story(story_path)` function inside upstream story hook.

* you can call as many downstream stories as you wish.

* you can call the same downstream story more than once.

* downstream stories in turn may call other downstream stories.

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

### story variables 

You may pass a variables to downstream story using second argument of `run_story()`  function. For example:

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


Here is the `run_story` signature list for various languages:

    +-----------+----------------------------------------------+
    | Language  | signature                                    |
    +-----------+----------------------------------------------+
    | Perl      | run_story(SCALAR,HASHREF)                    |
    | Ruby      | run_story(STRING,HASH)                       | 
    | Bash      | run_story(STORY_NAME NAME VAL NAME2 VAL2 ... | 
    +-----------+----------------------------------------------+

Story variables are accessible via `story_var()` function. For example:

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

* downstream stories may invoke other downstream stories.

* you can't only use story variables inside downstream stories.

Here is the how you access story variable in all three languages

    +------------------+---------------------------------------------+
    | Language         | signature                                   |
    +------------------+---------------------------------------------+
    | Perl             | story_var(SCALAR)                           |
    | Ruby             | story_var(STRING)                           | 
    | Bash (1-st way)  | $foo $bar ...                               |
    | Bash (2-nd way)  | $(story_var foo.bar)                        |
    +------------------+---------------------------------------------+

## Story properties

Some story properties have a proper accessors functions. Here is the list:


* `project_root_dir()` - Root directory of outthentic project.

* `test_root_dir()` - Test root directory. Root directory of generated perl test files , see also [story runner](#story-runner).

* `config()` - Returns suite configuration hash object. See also [suite configuration](#suite-configuration).


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

    +-----------+-----------------+
    | Language  | file            |
    +-----------+-----------------+
    | Perl      | common.pm       |
    | Ruby      | common.rb       |
    | Bash      | common.bash     |
    +-----------+-----------------+
    
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

* `--silent` 

Run in silent mode. By default strun prints all scenarios output (in green color), to disable this choose `--silent` option.
 

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


* `--ini`  

Configuration ini file path.

See [suite configuration](#suite-configuration) section for details.

* `--yaml` 

YAML configuration file path. 

See [suite configuration](#suite-configuration) section for details.

* `--json` 

JSON configuration file path. 

See [suite configuration](#suite-configuration) section for details.

# Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are three type of configuration files are supported:

* Config::General format
* YAML format
* JSON format

Config::General  style configuration files are passed by `--ini` parameter

    $ strun --ini /etc/suites/foo.ini

    $ cat /etc/suites/foo.ini

    <main>

      foo 1
      bar 2

    </main>

There is no special magic behind ini files, except this should be [Config::General](https://metacpan.org/pod/Config::General) compliant configuration file.

Or you can choose YAML format for suite configuration by using `--yaml` parameter:

    $ strun --yaml /etc/suites/foo.yaml

    $ cat /etc/suites/foo.yaml

    main :
      foo : 1
      bar : 2


Unless user sets path to configuration file explicitly by `--ini` or `--yaml` or `--json`  story runner looks for the 
files named suite.ini and _then_ ( if suite.ini is not found ) for suite.yaml, suite.json at the current working directory.

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


# Runtime configuration

Runtime configuration parameters is way to override suite configuration data. Consider this example:

    $ cat suite.ini
    <foo>
      bar 10
    </foo>
  
    $ strun --param foo.bar=20
  
This way we will override foo.bar to value \`20'.

# TAP

Story runner emits results in a [TAP](https://testanything.org/) format.

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

* `SPARROW_ROOT` - if set, used as prefix for test root directory.

    +---------------------+----------------------+
    | Test root directory | SPARROW_ROOT Is Set? |
    +---------------------+----------------------+
    | /tmp/.outthentic    | No                   |
    | $SPARROW_ROOT/tmp/  | Yes                  |
    +---------------------+----------------------+

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


