# Name

Outthentic

# Synopsis

Multipurpose scenarios framework.

# Build status

[![Build Status](https://travis-ci.org/melezhik/outthentic.svg)](https://travis-ci.org/melezhik/outthentic)


# Install

    $ cpanm Outthentic

# Introduction

This is an outthentic tutorial. 

# Scenarios

Scenario is just a script that you **run** and that yields something into **stdout**.

Perl scenario example:

    $ cat story.pl

    print "I am OK\n";
    print "I am outthentic\n";

Bash scenario example:

    $ cat story.bash

    echo I am OK
    echo I am outthentic

Python scenario example:

    $ cat story.py

    print "I am OK"
    print "I am outthentic"

Ruby scenario example:

    $ cat story.rb

    puts "I am OK"
    puts "I am outthentic"


Outthentic scenarios could be written on one of four languages:

* Perl 
* Bash
* Python
* Ruby

Choose you favorite language ;) !

Outthentic relies on file names convention to determine scenario language. 

This table describes file name -> language mapping for scenarios:

    +-----------+--------------+
    | Language  | File         |
    +-----------+--------------+
    | Perl      | story.pl     |
    | Bash      | story.bash   |
    | Python    | story.py     |
    | Ruby      | story.rb     |
    +-----------+--------------+
  

# Check files

Check files contain rules to **verify** stdout produced by scenarios. 

Here we require that scenario should produce  `I am OK` and `I am outthentic` lines in stdout:

    $ cat story.check

    I am OK
    I am outthentic

NOTE: Check files are optional, if one doesn't need any checks, then don't create check files.
In this case it's only ensured that a scenario succeeds ( exit code 0 ).

# Stories

Outthentic story is an abstraction for scenario and check file. 

When outthentic story gets run:

* scenario is executed and the output is saved into a file.
* the output is verified against check file

See also [story runner](#story-runner).

# Suites and projects

Outthentic suites are a bunch of related stories. You may also call suites (outthentic) projects.

Obviously project may contain more than one stories. 

Stories are mapped into directories inside project root directory.

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
      echo echo hello from bash 

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



To execute different stories let's use story runner command called [strun](#story-runner)

    $ strun --story perl-story
    $ strun --story bash-story 
    # so on ...
    

# The project root directory resolution and story paths

If `--root` parameter is not set the project root directory is the current working directory:

By default, if `--story` parameter is not given, strun looks for the file named story.(pl|rb|bash) 
at the project root directory. 

Here is an example:


    $ cat story.bash
    echo 'hello world'

    $ strun # will run story.bash 


It's always possible to pass project root directory explicitly:

    $ strun --root /path/to/project/root/

To run a certain story use `--story` parameter:

    $ strun --root /path/to/project/root/ --story /path/to/story/directory/inside/project/root

`--story` parameter should point a directory _relative_ to the project root directory.


Summary:

* Stories are just a directories with scenarios and check files inside.        

* Strun - a [S]tory [R]unner - a console tool to execute stories.

* Outthentic suites or projects are bunches of _related_ stories.


# Check files

Checks files contain rules to test scenario's output. 

Every scenario **might be accompanied by** its check file. 

Check file should be placed at the same directory as scenario and be named as `story.check`.

Here is an example:

    $ cat story.bash
    sudo service nginx status
 
    $ cat story.check
    running

# Story runner

Story runner - is a console tool to run stories. It is called `strun`.

When executing stories strun consequentially goes through several phases:

# Compilation phase

Stories are compiled into Perl files and saved into cache directory.

# Execution phase

Compiled Perl files are executed and results are dumped out to console. 
 

# Hooks

Story hooks are story runner's extension points. 

Hook features:

* Hooks like scenario are scripts written on different languages (Perl,Bash,Ruby,Python)

* Hooks always _binds to some story_ - to create a hook you should place hook's script into story directory.
 
* Hooks are are executed _before_ scenarios
   

Here is an example of hook:


    $ cat perl/hook.pl
    
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

Reasons why you might need a hooks:

* Execute some *initialization code* before running a scenario
* Override scenario output
* Call another stories

# Override scenario output

Sometimes you want to override story output at hook level. 

This is for example might be useful if you want to 
test check files. In QA methodology it's called Mock objects:

    $ nano hook.bash
    set_stdout 'running'
    $ nano story.check
    running

It's important that if overriding happens story executor never try to run scenario if it present:

    $ nano hook.bash
    set_stdout 'running'
    $ nano story.bash
    sudo service nginx status # this command won't be executed



You may call `set_stdout` function more then once

    $ nano hook.pl
    set_stdout("HELLO WORLD");
    set_stdout("HELLO WORLD2");

It will "produce" two line of story output:

    HELLO WORLD
    HELLO WORLD2

This table describes how `set_stdout()` function is called in various languages:

    +-----------+-----------------------+
    | Language  | signature             |
    +-----------+-----------------------+
    | Perl      | set_stdout(SCALAR)    |
    | Bash      | set_stdout(STRING)    |
    | Python(*) | set_stdout(STRING)    |
    | Ruby      | set_stdout(STRING)    |
    +-----------+-----------------------+

(*) you need to `from outthentic import *` in Python to import set_stdout function.

# Run stories from other stories

Hooks allow you to call one story from another. Here is an example:

    $ nano modules/knock-the-door/story.rb

    # this is a downstream story
    # to make story downstream
    # simply create story files 
    # in modules/ directory

    puts 'knock-knock!'
 
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
    

Stories that run other stories are called _upstream stories_.
Stories being called from other ones are _downstream story_.
    
Summary:

* To create downstream story place a story in `modules/` directory inside the project root directory

* To run downstream story call `run_story(story_path)` function inside upstream story's hook.

* Downstream story is always gets executed before upstream story.

* You can call as many downstream stories as you wish.

* Downstream stories may call other downstream stories.


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

# Story variables 

Variables might be passed to downstream story by second argument of `run_story()` function. 

For example, in Perl:


    $ nano hook.pl

    run_story( 
      'greeting', {  name => 'Alexey' , message => 'hello' }  
    );

Or in Ruby:

    $ nano hook.rb

    run_story  'greeting', {  'name' => 'Alexey' , 'message' => 'hello' }

Or in Python:

    from outthentic import *
    run_story('greeting', {  'name' : 'Alexey' , 'message' : 'hello' })

Or in Bash:

    $ cat hook.bash

    run_story  greeting name Alexey message hello 


This table describes how `run_story()` function is called in various languages:

    +-----------+----------------------------------------------+
    | Language  | signature                                    |
    +-----------+----------------------------------------------+
    | Perl      | run_story(SCALAR,HASHREF)                    |
    | Bash      | run_story STORY_NAME NAME VAL NAME2 VAL2 ... | 
    | Python    | run_story(STRING,DICT)                       | 
    | Ruby      | run_story(STRING,HASH)                       | 
    +-----------+----------------------------------------------+

Story variables are accessible in downstream story by `story_var()` function. 

Examples:

In Perl:

    $ nano modules/greeting/story.pl

    print story_var('name'), 'say ', story_var('message');

In Python:

    $ nano modules/greeting/story.py

    from outthentic import *
    print story_var('name') + 'say ' + story_var('message')

In Ruby:

    $ nano  modules/greeting/story.rb

    puts "#{story_var('name')} say #{story_var('message')}"


In Bash:

    $ nano modules/greeting/story.bash

    echo $name say $message

In Bash (alternative way):

    $ nano modules/greeting/story.bash

    echo $(story_var name) say $(story_var message)


Story variables are accessible inside story hooks and check files as well.

This table describes how `story_story()` function is called in various languages:

    +------------------+---------------------------------------------+
    | Language         | signature                                   |
    +------------------+---------------------------------------------+
    | Perl             | story_var(SCALAR)                           |
    | Python(*)        | story_var(STRING)                           | 
    | Ruby             | story_var(STRING)                           | 
    | Bash (1-st way)  | $foo $bar ...                               |
    | Bash (2-nd way)  | $(story_var foo.bar)                        |
    +------------------+---------------------------------------------+

(*) you need to `from outthentic import *` in Python to import story_var() function.

# Story helper functions

Here is the list of function one can use _inside hooks_:

* `project_root_dir()` - the project root directory.

* `test_root_dir()` - path to the cache directory with compiled story files ( see  [strun](#story-runner) ).

* `story_dir()` - path to the directory containing story data.

* `config()` - returns suite configuration hash object. See also [suite configuration](#suite-configuration).

* os() - return a mnemonic ID of operation system where story is executed


(*) you need to `from outthentic import *` in Python to import os() function.
(**) in Bash these functions are represented by variables, e.g. $project_root_dir, $os, so on.

# Recognized OS list

* centos5
* centos6
* centos7
* ubuntu
* debian
* minoca
* archlinux
* fedora
* amazon
* alpine

# Story meta headers

Story meta headers are just plain text files with some useful description.
The content of the meta headers will be shown when story is executed.

Example:

    $ nano meta.txt

    This is pretty cool stuff ...


# Ignore scenario failures


If scenario is failed ( exit code not equal to zero ), story executor mark such a story as unsuccessful and this
results in overall failure. To suppress story errors use `ignore_story_err()` function.


Examples:


    # Python

    $ cat hook.py
    from outthentic import *
    ignore_story_err(1)


    # Ruby

    $ cat hook.rb
    ignore_story_err 1

    # Perl

    $ cat hook.pl
    ignore_story_err(1)

    # Bash

    $ cat hook.bash
    ignore_story_err 1

# Story libraries

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

This table describes file name -> language mapping for story libraries:

    +-----------+-----------------+
    | Language  | file            |
    +-----------+-----------------+
    | Perl      | common.pm       |
    | Bash      | common.bash     |
    | Ruby      | common.rb       |
    +-----------+-----------------+

***NOTE!***  Story libraries are not supported for Python
    
# PERL5LIB

$project\_root\_directory/lib path is added to $PERL5LIB variable. 

This make it easy to place custom Perl modules under project root directory:

    $ cat my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    1;

    $ cat common.pm
    use Foo::Bar::Baz;

# Story runner console tool

    $ strun <options>
 
# Options

* `--root`  

Project root directory. Default value current working directory is assumed.

* `--cwd`  

Sets working directory when strun executes stories.

* `--debug` 

Enable/disable debug mode:

    * Increasing debug value results in more low level information appeared at output

    * Default value is 0, which means no debugging 

    * Possible values: 0,1,2,3

* `--format` 

Sets reports format. Available formats: `concise|default`. Default value is `default`.

In concise format strun shrink output to only STDOUT/STDERR comes from scenarios.

It's useful when you want to parse stories output by external commands.


* `--purge-cache`

Purge strun cache directory upon exit. By default `--purge-cache` is disabled.
 

* `--match_l` 

Truncate matching strings. When matching lines are appeared in a report they are truncated to $match_l bytes. Default value is 200.

* `--story` 

Run only a single story. This should be path _relative_ to the project root directory. 

Examples:

    # Project with 3 stories
    foo/story.pl
    foo/bar/story.rb
    bar/story.pl

    # Run various stories
    --story foo # runs foo/ stories
    --story foo/story # runs foo/story.pl
    --story foo/bar/ # runs foo/bar/ stories


* `--ini`  

Configuration file path.

See [suite configuration](#suite-configuration) section for details.

* `--yaml` 

YAML configuration file path. 

See [suite configuration](#suite-configuration) section for details.

* `--json` 

JSON configuration file path. 

See [suite configuration](#suite-configuration) section for details.

* `--nocolor`

Disable colors in reports. By default reports are color.

* `--dump-config`

Dumps suite configuration and exit. See also suite configuration section.


# Suite configuration

Outthentic projects are configurable. Configuration data is passed via configuration files.

There are three type of configuration files are supported:

* Config::General format (aka ini files)
* YAML format
* JSON format

Config::General style configuration files are passed by `--ini` parameter:

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


Unless user sets path to the configuration file explicitly either by `--ini` or `--yaml` or `--json`  story runner looks for the 
files named suite.ini and _then_ ( if suite.ini is not found ) for suite.yaml, suite.json at the current working directory.

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

    $ cat hook.py


    from outthentic import *

    foo = config()['main']['foo']
    bar = config()['main']['bar']


Ruby:

    $ cat hook.rb

    foo = config['main']['foo']
    bar = config['main']['bar']



# Runtime configuration

Runtime configuration parameters override ones in suite configuration. Consider this example:

    $ cat suite.yaml
    foo :
      bar : 10
  
    $ strun --param foo.bar=20 # will override foo.bar parameter to 20
  
# Stories without scenarios


The minimal set of files should be present in outthentic story is either scenario file or hook script,
the last option is story without scenario.


Examples:

    # Story with scenario only

    $ nano story.pl


    # Story with hook only

    $ nano hook.pl


# Environment variables

* `OUTTHENTIC_MATCH` - overrides default value for `--match_l` parameter of story runner.

* `SPARROW_ROOT` - sets the prefix for the path to the cache directory with compiled story files, see also [story runner](#story-runner).

* `SPARROW_NO_COLOR` - disable color output, see `--nocolor` option of story runner.

* `OUTTHENTIC_CWD` - sets working directory for strun, see `--cwd` parameter of story runner

Cache directory resolution:
    
    +---------------------+----------------------+
    | Cache directory     | SPARROW_ROOT Is Set? |
    +---------------------+----------------------+
    | ~/.outthentic/tmp/  | No                   |
    | $SPARROW_ROOT/tmp/  | Yes                  |
    +---------------------+----------------------+
    
        
# Examples

An example stories can be found in examples/ directory, to run them:

    $ strun --root examples/ --story $story-name

Where `$story-name` is any top level directory inside examples/.


# Check files syntax

Here is brief introduction into [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl) which is used to define rules in check files.

# plain strings checks

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

# regular expressions

You may use regular expressions as well:


    # check file

    regexp: L+
    regexp: \d


    # verification output

    OK - output matches /L+/
    OK - output matches /\d/

See [check-expressions](https://github.com/melezhik/outthentic-dsl#check-expressions) in Outthentic::DSL documentation pages.

# inline code, generators and asserts

You may inline code from other language to add some extra logic into your check file:

## Inline code

    # check file

    code: <<CODE
    !bash
    echo 'this is debug message will be shown at console'
    CODE

    code: <<CODE
    !python
    print 'this is debug message will be shown at console'
    CODE

    code: <<CODE
    !ruby
    puts 'this is debug message will be shown at console'
    CODE

    code: <<CODE
    # by default Perl language is used
    print("this is debug message will be shown at console\n");
    CODE

## generators

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

Python:

    generator: <<CODE
    !python
    print 'say'
    print 'hello'
    print 'again'

    CODE

Ruby:

    generator: <<CODE
    !ruby
    puts 'say'
    puts 'hello'
    puts 'again'

    CODE


##  asserts

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


## text blocks

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
    
See [comments-blank-lines-and-text-blocks](https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks) in Outthentic::DSL documentation pages.


# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

[https://github.com/melezhik/outthentic](https://github.com/melezhik/outthentic)

# See also

* [Sparrow](https://github.com/melezhik/sparrow) - outthentic suites manager.

* [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl) - Outthentic::DSL specification.

* [Swat](https://github.com/melezhik/swat) - web testing framework consuming Outthentic::DSL.

# Thanks

To God as the One Who inspires me to do my job!


