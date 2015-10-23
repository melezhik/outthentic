# Outthentic

print something into stdout and test

# Synopsis

Outthentic is a text oriented test framework. Instead of hack into objects and methods it deals with text appeared in stdout. It's a black box testing framework.

# Install

    cpanm Outthentic


# Short story

This is a five minutes tutorial on outthentic framework workflow.

**Create a story file**. Story is just an any perl script that yields something into stdout:

    # story.pl

    print "I am OK\n";
    print "I am outthentic\n";




**Create a story check file**. Story check is a bunch of lines stdout should match. Here we require to have \`I am OK' and \`I am outthentic' lines in stdout:

    # story.check

    I am OK
    I am outthentic

**Run a story**. Story runner is script that parses and then executes stories, it:

* finds and execute story files.
* remembers stdout.
* validates stdout against a story checks content.

Follow [story runner](#story-runner) section for details on story runner "guts".

To execute story runner say \`strun':


    $ strun
    /tmp/.outthentic/13952/home/vagrant/projects/outthentic/examples/hello-world/story.t ..
    ok 1 - perl /home/vagrant/projects/outthentic/examples/hello-world/story.pl succeeded
    ok 2 - stdout saved to /tmp/.outthentic/13952/ZgAZGUcduG
    ok 3 - /home/vagrant/projects/outthentic/examples/hello-world stdout has I am OK
    ok 4 - /home/vagrant/projects/outthentic/examples/hello-world stdout has I am outthentic
    1..4
    ok
    All tests successful.
    Files=1, Tests=4,  1 wallclock secs ( 0.07 usr  0.01 sys +  0.14 cusr  0.00 csys =  0.22 CPU)
    Result: PASS
 





# Long story

Here is a step by step explanation of outthentic project layout. We explain here basic outthentic entities:

* project
* stories
* story checks

## Project

Outthentic project is bunch of related stories. Every project is _represented_ by a directory where all the stuff is placed at.

Let's create a project to test a simple calculator application:

```
  mkdir calc-app
  cd calc-app

```

## Stories

Stories are just perl scripts placed at project directory and named \`story.pl'. In a testing context, stories are pieces of logic to be testsed.

Think about them like \`*.t' files in a perl unit test system.

To tell one story file from another one should keep them in different directories.

Let's create two stories for our calc project. One story to represent addition operation and other for addition operation:


```

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
 

```

## Story checks

Story checks are files that contain lines for validation of stdout from story scripts.

Story check file should be placed at the same directory as story file and named \`story.check'.

Following are story checks for a multiplication and addition stories:


```
  # addition/story.check
  4
  6
 
  # multiplication/story.check
  6
  12
 
```

Now we ready to invoke a story runner:

```
   strun

```

# Story term ambiguity

Sometimes term \`story' refers to a couple of files representing story unit - story.pl and story.check,
in other cases this term refers to a single story file - story.pl.


# Story runner

This is detailed explanation of story runner life cycle.

Story runner script consequentially hits two phases:

- **Compilation phase** where stories are converted into perl test files.
- **Execution phase** where perl test files are recursively executed by prove.

## Compilation phase

When story runner iterate through story files and story check it convert both of them into single perl test file.
Perl test file _looks like_ list of Test::More asserts.

Recalling call-app project with 2 stories:

    addition/(story.pl,story.check)
    multiplication/(story.pl,story.check)

Story runner parses every story and the creates a perl test file for it:

    addition/story.t
    multiplication/story.t

Every perl test file holds a list of the Test::More asserts:

```
    # addition/story.t
 
    run_story('multiplication/story.pl');
 
    SKIP {
        ok($status,'story stdout matches 4');
        ok($status,'story stdout matches 6');
    }

    # multiplication/story.t
 
    run_story('multiplication/story.pl');
 
    SKIP {
        ok($status,'story stdout matches 6');
        ok($status,'story stdout matches 12');
    }

```

## Execution phase
 
Once perl test files are generated and placed at temporary directory story runner calls prove which recursively execute all test files.
That's it.


## Time diagram

This is a time diagram for story runner life cycle:

    - Hits compilation phase
    - For every story and story check file found:
        - Creates a perl test file
    - The end of compilation phase
    - Hits execution phase - runs \`prove' recursively on a directory with a perl test files
    - For every perl test file gets executed:
        - Require hook ( story.pm ) if exists
        - Iterate over Test::More asserts
            - Execute story file and save stdout in temporary file
            - Execute Test::More asserts against a content of temporary file
        - The end of Test::More asserts iterator
    - The end of execution phase
 

# Story checks syntax

Story check is a bunch of lines stdout should match.

It's convenient to talk about a _check list_ - is list of none empty lines in a story check file.

Basically every item of check list is so called  _check expression_.

There are other expressions could be in a check file, but we will talk about them later:

* comments
* blank lines
* text blocks
* perl expressions
* generators

## Check expressions

Check expressions defines _what lines stdout should have_

    # stdout
    HELLO
    HELLO WORLD
    My birth day is: 1977-04-16


    # check list
    HELLO
    regexp: \d\d\d\d-\d\d-\d\d


    # check output
    HELLO matches
    regexp: \d\d\d\d-\d\d-\d\d matches



There are two type of check expressions - plain strings and regular expressions.

- **plain string**

        I am ok
        HELLO Outthentic
 

The code above declares that stdout should have lines 'I am ok' and 'HELLO Outthentic'.

- **regular expression**

Similarly to plain strings matching, you may require that stdout has lines matching the regular expressions:

        regexp: \d\d\d\d-\d\d-\d\d # date in format of YYYY-MM-DD
        regexp: Name: \w+ # name
        regexp: App Version Number: \d+\.\d+\.\d+ # version number

Regular expressions should start with \`regexp:' marker.
 

- **captures**

Story runner does not care about _how many times_ a given check expression is found in stdout.

It's only required that at least one line in stdout match the check expression ( this is not the case with text blocks, see later )

However it's possible to _accumulate_ all matching lines and save them for further processing:

        regexp: (Hello, my name is (\w+))

See ["captures"](#captures) section for full explanation of a captures mechanism:


## Comments, blank lines and text blocks

Comments and blank lines don't get added to check list. See further.


* **comments**

    Comment lines start with \`#' symbol, story runner ignores comments chunks when parse story check files:

        # comments could be represented at a distinct line, like here
        The beginning of story
        Hello World # or could be added to existed expression to the right, like here

* **blank lines**

    Blank lines are ignored. You may use blank lines to improve code readability:

        # check output
        The beginning of story
        # then 2 blank lines


        # then another check
        HELLO WORLD

But you **can't ignore** blank lines in a \`text block matching' context ( see \`text blocks' subsection ), use \`:blank_line' marker to match blank lines:

        # :blank_line marker matches blank lines
        # this is especially useful
        # when match in text blocks context:

        begin:
            this line followed by 2 blank lines
            :blank_line
            :blank_line
        end:

* **text blocks**

Sometimes it is very helpful to match a stdout against a \`block of strings' goes consequentially, like here:

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

This test will succeed when gets executed against this chunk:

        this string followed by
        that string followed by
        another one string
        with that string
        at the very end.

But **will not** for this chunk:

        that string followed by
        this string followed by
        another one string
        with that string
        at the very end.

\`begin:' \`end:' markers decorate \`text blocks' content. \`:being|:end' markers should not be followed by any text at the same line.

Also be aware if you leave "dangling" \`begin:' marker without closing \`end': somewhere else
story runner will remain in a \`text block' mode till the end of your story check file, which is probably not you want:

        begin:
            here we begin
            and till the very end of test
            we are in `text block` mode

## Perl expressions

Perl expressions are just a pieces of perl code to _get evaled_ inside your story. This is how it works:

        # this is my story
        Once upon a time
        code: print "hello I am Outthentic"
        Lived a boy called Outthentic


Story check files get turned into a perl test file. All \`code' lines are turned into \`eval {code}' chunks:

        ok($status,"stdout matches Once upon a time");
        eval 'print "Lived a boy called Outthentic"';
        ok($status,"stdout matches Lived a boy called Outthentic");

Then prove execute generated perl test file.

Example with 'print "Lived a boy called Outthentic"' is quite useless, there are of course more effective ways how you could use perl expressions in your stories.

One of useful thing you could with perl expressions is to call some Test::More functions to modify Test::More workflow:

        # skip tests

        code: skip('next 3 checks are skipped',3) # skip three next checks forever
        color: red
        color: blue
        color: green

        number:one
        number:two
        number:three

        # skip tests conditionally

        color: red
        color: blue
        color: green

        code: skip('numbers checks are skipped',3)  if $ENV{'skip_numbers'} # skip three next checks if skip_numbers set

        number:one
        number:two
        number:three


Perl expressions are executed by perl eval function, please be aware of that.

Follow [http://perldoc.perl.org/functions/eval.html](http://perldoc.perl.org/functions/eval.html) to get know more about perl eval.

## Generators


Generators is the way to _populate story check lists on the fly_.

Generators like perl expressions are just a piece of perl code.

The only requirement for generator code - it should return _reference to array of strings_.

An array returned by generator code could contain:

* check expressions items
* comments
* blank lines
* text blocks
* perl expressions
* generators


An array items are passed back to story runner and gets appended to a current check list. Here is a simple example:

        # original check list

        Say
        HELLO
 
        # this generator generates plain string check expressions:
        # new items will be appended into check list

        generator: [ qw{ say hello again } ]


        # final check list:

        Say
        HELLO
        say
        hello
        again

Generators expressions start with \`:generator' marker. Here is more complicated example:

        # this generator generates comment lines
        # and plain string check expressions:

        generator: my %d = { 'foo' => 'foo value', 'bar' => 'bar value' }; [ map  { ( "# $_", "$data{$_}" )  } keys %d ]


        # final check list:

            # foo
            foo value
            # bar
            bar value


Note about **PERL5LIB**.

Story runner adds \`project_root_directory/lib' path to PERL5LIB path, so you may define some modules here and then \`use' them inside your story check:

        my-app/lib/Foo/Bar/Baz.pm

        # story.check
        # now it is possible to use Foo::Bar::Baz
        code: use Foo::Bar::Baz; # etc ...

- **multiline expressions**

As long as outthentic deals with check expressions ( both plain strings or regular expressions ) it works in a single line mode,
that means that check expressions are single line strings and stdout is validated in line by line way:

           # check list
           Multiline
           string
           here
           regexp: Multiline \n string \n here

           # stdout
           Multiline \n string \n here
   
 
           # test output
           "Multiline" matched
           "string" matched
           "here" matched
           "Multiline \n string \n here" not matched


Use text blocks instead if you want to achieve multiline checks.

However when writing perl expressions or generators one could use multilines there.  \`\' delimiters breaks a single line text on a multi lines:

```
    # What about to validate stdout response
    # With sqlite database entries?

    generator:                                                          \

    use DBI;                                                            \
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","","");   \
    my $sth = $dbh->prepare("SELECT name from users");                  \
    $sth->execute();                                                    \
    my $results = $sth->fetchall_arrayref;                              \

    [ map { $_->[0] } @${results} ]
```

# Captures

Captures are pieces of data get captured when story runner checks stdout with regular expressions:

```
    # stdout
    # it's my family ages.
    alex    38
    julia   25
    jan     2


    # let's capture name and age chunks
    regexp: /(\w+)\s+(\d+)/
```

_After_ this regular expression check gets executed captured data will stored into a array:

    [
        ['alex',    38 ]
        ['julia',   32 ]
        ['jan',     2  ]
    ]

Then captured data might be accessed for example by code generator to define some extra checks:

```
    code:                               \
    my $total=0;                        \
    for my $c (@{captures()}) {         \
        $total+=$c->[0];                \
    }                                   \
    cmp_ok( $total,'==',72,"total age of my family" );

```

\`captures()' function is used to access captured data array, it returns an array reference holding all chunks captured during _latest regular expression check_.


Here some more examples:

    # check if stdout response contains numbers,
    # then calculate total amount
    # and check if it is greater then 10

    regexp: (\d+)
    code:                               \
    my $total=0;                        \
    for my $c (@{captures()}) {         \
        $total+=$c->[0];                \
    }                                   \
    cmp_ok( $total,'>',10,"total amount is greater than 10" );


    # check if stdout response contains lines
    # with date formatted as date: YYYY-MM-DD
    # and then check if first date found is yesterday

    regexp: date: (\d\d\d\d)-(\d\d)-(\d\d)
    code:                               \
    use DateTime;                       \
    my $c = captures()->[0];            \
    my $dt = DateTime->new( year => $c->[0], month => $c->[1], day => $c->[2]  ); \
    my $yesterday = DateTime->now->subtract( days =>  1 );                        \
    cmp_ok( DateTime->compare($dt, $yesterday),'==',0,"first day found is - $dt and this is a yesterday" );

You also may use \`capture()' function to get a _first element_ of captures array:

    # check if stdout response contains numbers
    # a first number should be greater then ten

    regexp: (\d+)
    code: cmp_ok( capture()->[0],'>',10,"first number is greater than 10" );

# Hooks

Story Hooks are extension points to hack into story run time phase. It's just files with perl code gets executed in the beginning of a story. You should named your hook file as \`story.pm' and place it into \`story' directory:


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


## Upstream and downstream stories

Story runner allow you to call one story from another, using notion of downstream stories.

Downstream stories are reusable stories. Runner never executes downstream stories directly, instead you have to call downstream story from _upstream_ one:

```
 
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

```

Here are the brief comments to the example above:

* to make story as downstream simply create story file at modules/ directory

* call \`run_story(story_path)' function inside upstream story hook to run downstream story.

* you can call as many downstream stories as you wish.

* you can call the same downstream story more than once.

Here is an example code snippet:

```
    # story.pm
    run_story( 'some_story' )
    run_story( 'yet_another_story' )
    run_story( 'some_story' )

```

* downstream stories have variables you may pass to when invoke one:

```
    run_story( 'create_calc_object', { use_floats => 1, use_complex_numbers => 1, foo => 'bar'   }  )
```

* one may access story variables using \`story_var' function:

```
    # create_calc_object/story.pm
    story_var('use_float');
    story_var('use_complex_numbers');
    story_var('foo');

```

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

* project_root_dir() - root directory of outthentic project

* test_root_dir() - root directory of generated perl tests , see [story runner](#story-runner) section

## Ignore unsuccessful codes when run stories

As every story is a perl script gets run via system call, it returns an exit code. None zero exit codes result in test failures, this default behavior , to disable this say:

```
    ignore_story_err(1);
```

# Story runner client

    strun <options>
 
## Options

* `--root`  - root directory of outthentic project, if not set story runner starts with current working directory

* `--debug` - add debug info to test output, one of possible values : \`0,1,2'. default value is \`0'

* `--runner_debug` - add low level debug info to test output, mostly useful by me :) when debugging story runner

* `--story` -  run only single story, this should be file path without extensions (.pl,.check):


```
  foo/story.pl
  foo/bar/story.pl
  bar/story.pl
 
  --story 'foo' # runs foo/* stories
  --story foo/story # runs foo/story.pl
  --story foo/bar/ # runs foo/bar/* stories

```

* `--prove-opts` - prove parameters, see [prove settings](#prove-settings) section
 

# TAP

Outthentic produces output in [TAP](https://testanything.org/) format, that means you may use your favorite tap parser to bring result to another test / reporting systems, follow TAP documentation to get more on this.

Here is example for having output in JUNIT format:

    strun --prove_opts "--formatter TAP::Formatter::JUnit"

# Prove settings

Outthentic utilize [prove utility](http://search.cpan.org/perldoc?prove) to execute tests, one my pass prove related parameters using \`--prove-opts'. Here are some examples:

    strun --prove_opts "-Q" # don't show anythings unless test summary
    strun --prove_opts "-q -s" # run prove tests in random and quite mode



# Examples

An example outthentic project lives at examples/ directory, to run it say this:

```
    strun --root examples/
```

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

https://github.com/melezhik/outthentic


# Thanks

* to God as:
```
- For the LORD giveth wisdom: out of his mouth cometh knowledge and understanding.
(Proverbs 2:6)
```
* to the Authors of : perl, TAP, Test::More, Test::Harness
