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

* Perl 
* Bash
* Python
* Ruby

Choose you favorite language ;) !

Outthentic relies on file names convention to determine scenario language. 

This table describes `file name -> language` mapping for scenarios:

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

    $ nano story.check

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



To execute different stories launch story runner command called [strun](#story-runner):

    $ strun --story perl-story
    $ strun --story bash-story 
    # so on ...
    

# The project root directory resolution and story paths

If `--root` parameter is not set the project root directory is the current working directory.

By default, if `--story` parameter is not given, strun looks for the file named story.(pl|rb|bash) at the project root directory
and run it.

Here is an example:


    $ nano story.bash
    echo 'hello world'

    $ strun # will run story.bash 


It's always possible to pass the project root directory explicitly:

    $ strun --root /path/to/project/root/

To run the certain story use `--story` parameter:

    $ strun --story story1

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

    $ nano story.bash
    sudo service nginx status
 
    $ nano story.check
    running

# Story runner

Story runner is a console tool to run stories. It is called `strun`.

When executing stories strun consequentially goes through several phases:

# Compilation phase

Stories are compiled into Perl files and saved into cache directory.

# Execution phase

Compiled Perl files are executed and results are dumped out to console. 
 
# Hooks

Story hooks are story runner's extension points. 

Hook features:

* Hooks like scenarios are scripts written on different languages (Perl,Bash,Ruby,Python)

* Hooks always _binds to some story_, to create a hook you should place hook's script into story directory.
 
* Hooks are are executed _before_ scenarios
   
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

* Execute some *initialization code* before running a scenario
* Simulate scenario's output
* Call another stories

# Simulate scenario output

Sometimes you want to override story output at hook level. 

This is for example might be useful if you want to _test_ the rules in check files without running real script.

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



You may call `set_stdout` function more then once:

    $ nano hook.pl
      set_stdout("HELLO WORLD");
      set_stdout("HELLO WORLD2");

It will "produce" two line of a story output:

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

(*) You need to `from outthentic import *` in Python to import set_stdout function.

# Run stories from other stories

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
    

Stories that run other stories are called _upstream stories_.

Stories being called from other ones are _downstream story_.
    
Summary:

* To create downstream story place a story data in `modules/` directory inside the project root directory.

* To run downstream story call `run_story(story_path)` function inside the upstream story's hook.

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

Variables might be passed to downstream story by the second argument of `run_story()` function. 

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


This table describes how `run_story()` function is called in various languages:

    +------------+----------------------------------------------+
    | Language   | signature                                    |
    +------------+----------------------------------------------+
    | Perl       | run_story(SCALAR,HASHREF)                    |
    | Bash       | run_story STORY_NAME NAME VAL NAME2 VAL2 ... | 
    | Python(**) | run_story(STRING,DICT)                       | 
    | Ruby       | run_story(STRING,HASH)                       | 
    +------------+----------------------------------------------+

(*) Story variables are accessible(*) in downstream story by `story_var()` function. 

(**) You need to `from outthentic import *` in Python to import set_stdout function.

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

(*) You need to `from outthentic import *` in Python to import story_var() function.

# Stories without scenarios

The minimal set of files should be present in outthentic story is either scenario file or hook script,
the last option is story without scenario.


Examples:

    # Story with scenario only

    $ nano story.pl


    # Story with hook only

    $ nano hook.pl

# Story helper functions

Here is the list of function one can use _inside hooks_:

* `project_root_dir()` - the project root directory.

* `cache_root_dir()` - the cache root directory ( see  [strun](#story-runner) ).

* `cache_dir()` - storie's cache directory ( containing story's compiled files )

* `story_dir()` - the directory containing story data.

* `config()` - returns suite configuration hash object. See also [suite configuration](#suite-configuration).

* os() - return a mnemonic ID of operation system where story is executed.


(*) You need to `from outthentic import *` in Python to import os() function.
(**) in Bash these functions are represented by variables, e.g. $project_root_dir, $os, so on.

# Recognizable OS list

* alpine
* amazon
* archlinux
* centos5
* centos6
* centos7
* debian
* fedora
* minoca
* ubuntu

# Story meta headers

Story meta headers are just plain text files with some useful description.

The content of the meta headers will be shown when story is executed.

Example:

    $ nano meta.txt

      The beginning of the story ...


# Ignore scenario failures


If scenario fails ( the exit code is not equal to zero ), the story executor marks such a story as unsuccessful and this
results in overall failure. To suppress any story errors use `ignore_story_err()` function.


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

# Story libraries

Story libraries are files to make your libraries' code _automatically required_ into the story hooks and check files context:

Here are some examples:

Perl:

    $ nano common.pm
      sub abc_generator {
        print $_, "\n" for a..z;
      } 

    $ nano story.check
      generator: <<CODE;
      !perl
        abc_generator()
      CODE


Ruby:

    $ nano common.rb
      def super_utility arg1, arg2
        # I am cool! But I do nothing!
      end
  
    $ nano hook.pl
      super_utility 'foo', 'bar'

This table describes `file name -> language` mapping for story libraries:

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

    $ nano my-app/lib/Foo/Bar/Baz.pm
      package Foo::Bar::Baz;
      1;

    $ nano common.pm
      use Foo::Bar::Baz;

# Story runner console tool

    $ strun <options>
 
# Options

* `--root`  

The project root directory. Default value is the current working directory.

* `--cwd`  

Sets working directory when strun executes stories.

* `--debug` 

Enable/disable debug mode:

    * Increasing debug value results in more low level information appeared at output.

    * Default value is 0, which means no debugging. 

    * Possible values: 0,1,2,3.

* `--format` 

Sets reports format. Available formats are: `concise|default`. Default value is `default`.

In concise format strun shrinks output to only STDOUT/STDERR comes from scenarios.

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

    $ nano /etc/suites/foo.ini

    <main>

      foo 1
      bar 2

    </main>

There is no special magic behind ini files, except this should be [Config::General](https://metacpan.org/pod/Config::General) compliant configuration file.

Or you can choose YAML format for suite configuration by using `--yaml` parameter:

    $ strun --yaml /etc/suites/foo.yaml

    $ nano /etc/suites/foo.yaml

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

    $ nano hook.py

    from outthentic import *

      foo = config()['main']['foo']
      bar = config()['main']['bar']


Ruby:

    $ nano hook.rb

      foo = config['main']['foo']
      bar = config['main']['bar']



# Runtime configuration

Runtime configuration parameters override ones in suite configuration. Consider this example:

    $ nano suite.yaml
    foo :
      bar : 10
  
    $ strun --param foo.bar=20 # will override foo.bar parameter to 20
  

# Free style command line parameters

Alternative way to pass input parameters into outthentic scripts is a _free style_ command line arguments:

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

That's all. Now we are safe to run our story-wrapper with command line arguments _in terms of_ external script:

    $ strun -- --foo foo-value --debug the-value


# Auto coercion of configuration data into free style command line parameters

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

# Auto coercion rules

* Args should be array which elements are processed in order, for every elements rules are applied depending on element's type
* Scalars are turned into scalars: `the-value ---> the-value`
* Arrays are turned into scalars with double dashes perpended: `(debug, verbose) ---> --debug --verbose`. This is useful for declaring
boolean flags 
* Hashes are turned into named parameters: `foo: foo-value ---> --foo foo-value`

# Auto coercion, using single dashes instead of double dashes

Double dashes are default behavior of how named parameters and flags 
converted. If you need single dashes, prepend parameters in configuration file with `~` :

    $ nano suite.yaml

      ---
    
      args:
        - ~foo: foo-value
        -
          - ~debug 
          - ~verbose 


# Environment variables

* `OUTTHENTIC_MATCH` - overrides default value for `--match_l` parameter of story runner.

* `SPARROW_ROOT` - sets the prefix for the path to the cache directory with compiled story files, see also [story runner](#story-runner).

* `SPARROW_NO_COLOR` - disable color output, see `--nocolor` option of story runner.

* `OUTTHENTIC_CWD` - sets working directory for strun, see `--cwd` parameter of story runner

Cache directory resolution:
    
    +---------------------+----------------------+
    | The Cache Directory | SPARROW_ROOT Is Set? |
    +---------------------+----------------------+
    | ~/.outthentic/tmp/  | No                   |
    | $SPARROW_ROOT/tmp/  | Yes                  |
    +---------------------+----------------------+
    
        
# Examples

An example stories can be found in examples/ directory, to run them:

    $ strun --root examples/ --story $story-name

Where `$story-name` is any top level directory inside examples/.


# Check files syntax

* Brief introduction of check file syntax could be found here - [https://github.com/melezhik/outthentic/blob/master/check-files-syntax.md](https://github.com/melezhik/outthentic/blob/master/check-files-syntax.md)

* For the full detailed explanation follow Outthentic::DSL doc pages at [https://github.com/melezhik/outthentic-dsl](https://github.com/melezhik/outthentic-dsl)

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

[https://github.com/melezhik/outthentic](https://github.com/melezhik/outthentic)

# See also

* [Sparrow](https://github.com/melezhik/sparrow) - Multipurposes scenarios manager.

* [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl) - Outthentic::DSL specification.

* [Swat](https://github.com/melezhik/swat) - Web testing framework.

# Thanks

To God as the One Who inspires me in my life!




