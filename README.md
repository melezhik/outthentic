# Outhentic

print something into stdout and test

# Synopsis
Othentic is a text oriented test framework. Istead of hack into objects and methods it deals with text appeared in STDOUT. It's a blackbox testing framework.

# Short story

This is five minutes tutorial on othentic workflow.

- Create a story file:

```
# story.pl

print "I am OK\n";
print "I am outhentic";

```

Story file is just an any perl script print something into STDOUT.

- Create a story check:

```
# story.check

  I am OK
  I am outhentic

```
Story check is a bunch of lines STDOUT should match. Here we require to have `I am OK' and `I am outhentic' lines in STDOUT. 

- Run a story:

Othentic provides test runner called `story_check', it finds a story files, runs story files and validates STDOUT against story checks.

```
  story_check
  
```

( TODO: ) Add output of story_check here.


# Long story

Here is a step by step description of outhentic project layout.

## Project

Ouhtentic project is bunch of related stroies. Every outhentic project needs a directory where all the stuff is placed. Let's create a project to test a simple calculator application:

```

  mkdir calc-app
  cd calc-app
  
```

## Stories

Inside a project root directory one may create outhentic stroies. Every stories should be kept under a distinct directory:

```
  mkdir addition
  mkdir multiplication
```
Now lets create a stories , this should be files named story.pl:

```
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

Story checks files similiraly should be placed at distinct directories and be named as story.check:


```
  # addition/story.check
  4
  6
  
  # multiplication/story.check
  6
  12  
  
```


# Story runner

This is detailed explanation of how story runner compiles and then executes stories.

Story_check script consequentially hits two phases when execute stories:

- **Compilation phase** where stories are converted into Test::Harness format.
- **Execution phase** where perl test files are recursively executed by prove.

## Story to Test::Harness compilation

One important thing about story checksis that internally they are represented as Test::More asserts. This is how it work: 

Recalling call-app project with 2 stroies:

    addition/(story.pl,story.check)
    multiplication/(story.pl,story.check)

Story_check parse every story and the creates a perl test file for it:

    addition/story.t
    multiplication/story.t

Every story check is converted into the list of the Test::More asserts:

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
     
This is a time diagram for story runner workflow:

    - Hits compilation phase
    - For every story found:
        - Calculates story settings comes from various ini files
        - Creates a perl test file at Test::Harness format
    - The end of compilation phase
    - Hits execution phase - runs \`prove' recursively on a directory with a perl test files
    - For every perl test file gets executed:
        - Require story.pm if exists
        - Iterate over Test::More asserts
            - Execute story file and save STDOUT in a STDOUT file
            - Execute Test::More assert against a content of STDOUT file
        - The end of Test::More asserts iterator
    - The end of execution phase
    

# Story checks syntax 

Story check is a bunch of lines STDOUT should match. In other words this the list of check expressions, indeed not only check expressions, there are some - comments, blank lines, text blocks , perl expressions and generators we will talk about all of them later.

Let's start with check expressions.

## Check expressions

Story check expressions declares _what should be_ in a stdout: 

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
        HELLO Outhentic
        

The code above declares that stdout should have lines matches to 'I am ok' and 'HELLO Othentic'.

- **regular expression**

Similarly to plain strings, you may ask story runner to check if stdout has a lines matching to a regular expressions:

        regexp: \d\d\d\d-\d\d-\d\d # date in format of YYYY-MM-DD
        regexp: 20\d # successful http status 200, 201 etc
        regexp: App Version Number: \d+\.\d+\.\d+ # version number

Regular expression should start with \`regexp:' marker.
 
You may use \`(,)' symbols to capture subparts of matching strings, the captured chunks will be saved and could be used further, 

- **captures**

Note, that story runner does not care about how many times a given check expression is matched by stdout, 
outhentic "assumes" it at least should be matched once. However it's possible to accumulate 
all matching lines and save them for further processing, just use \`(,)' symbols to capture subparts of matching strings:

        regexp: Hello, my name is (\w+)

See ["captures"](#captures) section for full explanation of a captures:


## Comments, blank lines and text blocks 

- **comments**

    Comment lines start with \`#' symbol, story runner ignores comments chunks when parse story checks:

        # comments could be represented at a distinct line, like here
        The begining of story
        Hello World # or could be added to existed matchers to the left, like here

- **blank lines**

    Blank lines are ignored. You may use blank lines to improve code readability:

        # check output
        The begining of story
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

- **text blocks**

Sometimes it is very helpful to match a response against a \`block of strings' goes consequentially, like here:

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

This check list will succeed when gets executed against this chunk:

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
story runner will remain in a \`text block' mode till the end of your story check, which is probably not you want:

        begin:
            here we begin
            and till the very end of test
            we are in `text block` mode

## Perl expressions

Perl expressions are just a pieces of perl code to _get evaled_ inside your story. This is how it works:

        # this is my story
        Once upon a time
        code: print "hello I am Outhentic"
        Lived a boy called Othentic


First story runner converts story check into perl code with eval "{code}" chunk added into it, this is called compilation phase:

        ok($status,"stdout matches 200 OK");
        eval 'print "Lived a boy called Othentic"';
        ok($status,"stdout matches Lived a boy called Othentic");

Then prove execute the code above.

Follow ["Story runner"](#story-runner) to know how outhentic compile stories into a perl code.

Anyway, the example with 'print "Lived a boy called Othentic"' is quite useless, there are of course more effective ways how you code use perl expressions in your stories.

One of useful thing you could with perl expressions is to call some Test::More functions to modify test workflow:

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


Perl expressions are executed by perl eval function, please take this into account.
Follow [http://perldoc.perl.org/functions/eval.html](http://perldoc.perl.org/functions/eval.html) to get know more about perl eval.

## Generators


Story generators is the way to _create story check lists  on the fly_. Generators like perl expressions are just a piece of perl code with the only difference that generator code should always return _an array reference_.

An array returned by generator code should contain check list items, _serialized_ as perl strings.
New check list items are passed back to story runner and will be appended to a current check list. Here is a simple example:

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

Generators expressions start with \`:generator' marker. Here is more example:

        # this generator generates comment lines 
        # and plain string check expressions:

        generator: my %d = { 'foo' => 'foo value', 'bar' => 'bar value' }; [ map  { ( "# $_", "$data{$_}" )  } keys %d ]


        # final check list:

            # foo
            foo value
            # bar
            bar value

Note about **PERL5LIB**. 

Story runner adds \`project_root_directory/lib' path to PERL5LIB path, so you may perl modules here and then \`use' them:

        my-app/lib/Foo/Bar/Baz.pm

        # now it is possible to use Foo::Bar::Baz
        code: use Foo::Bar::Baz; # etc ...

- **multiline expressions**

As long as outhentic deals with check expressions ( both plain strings or regular expressions ) it works in a single line mode,  that means that check expressions are single line strings and response is checked in line by line way:

           # check list
           Multiline
           string
           here    
           regexp: Multiline \n string \n here    

           # http response
           Multiline \n string \n here
           
        
           # test output
           "Multiline" matched
           "string" matched
           "here" matched
           "Multiline \n string \n here" not matched


Use text blocks instead if you want to achieve multiline checks.

However when writing perl expressions or generators one could use multilines there.  \`\' delimiters breaks a single line text on a multi lines:


        # What about to validate response
        # With sqlite database entries?

        generator:                                                          \

        use DBI;                                                            \
        my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","","");   \
        my $sth = $dbh->prepare("SELECT name from users");                  \
        $sth->execute();                                                    \
        my $results = $sth->fetchall_arrayref;                              \

        [ map { $_->[0] } @${results} ]


# Captures

Captures are pieces of data get captured when story runner checks stdout with regular expressions:

    # stdout
    # it's my family ages.
    alex    38
    julia   25
    jan     2


    # let's capture name and age chunks
    regexp: /(\w+)\s+(\d+)/

_After_ this regular expression check gets executed captured data will stored into a array:

    [
        ['alex',    38 ]
        ['julia',   32 ]
        ['jan',     2  ]
    ]

Then captured data might be accessed for example by code generator to define some extra checks:

    code:                               \
    my $total=0;                        \
    for my $c (@{captures()}) {         \
        $total+=$c->[0];                \
    }                                   \
    cmp_ok( $total,'==',72,"total age of my family" );

\`captures()' function is used to access captured data array, it returns an array reference holding all chunks captured during _latest regular expression check_.

Here some more examples:

    # check if response contains numbers,
    # then calculate total amount
    # and check if it is greater then 10

    regexp: (\d+)
    code:                               \
    my $total=0;                        \
    for my $c (@{captures()}) {         \
        $total+=$c->[0];                \
    }                                   \
    cmp_ok( $total,'>',10,"total amount is greater than 10" );


    # check if response contains lines
    # with date formatted as date: YYYY-MM-DD
    # and then check if first date found is yesterday

    regexp: date: (\d\d\d\d)-(\d\d)-(\d\d)
    code:                               \
    use DateTime;                       \
    my $c = captures()->[0];            \
    my $dt = DateTime->new( year => $c->[0], month => $c->[1], day => $c->[2]  ); \
    my $yesterday = DateTime->now->subtract( days =>  1 );     \
    cmp_ok( DateTime->compare($dt, $yesterday),'==',0,"first day found is - $dt and this is a yesterday" );

You also may use \`capture()' function to get a _first element_ of captures array:

    # check if response contains numbers
    # a first number should be greater then ten

    regexp: (\d+)
    code: cmp_ok( capture()->[0],'>',10,"first number is greater than 10" );


# TAP

Othentic produces output in [TAP](https://testanything.org/) format, that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this. 

Here is example for having output in JUNIT format:

    story_check --formatter TAP::Formatter::JUnit

# Prove settings

Othentic utilize [prove utility](http://search.cpan.org/perldoc?prove) to run tests, all prove related parameters are passed as is to prove. Here are some examples:

    story_check -Q # don't show anythings unless test summary
    story_check -q -s # run prove tests in random and quite mode


# Story client

Once othentic is installed you get story_check client at the \`PATH':

    story_check <project_root_dir> <prove settings>

# Examples

There is plenty of examples at ./examples directory

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

https://github.com/melezhik/outhentic


# Thanks

- to God as:
```
- For the LORD giveth wisdom: out of his mouth cometh knowledge and understanding.
(Proverbs 2:6)
```
- to the Authors of : perl, TAP, Test::More, Test::Harness

