# outhentic

print something into stdout and test

# synopsis
Othentic is a text oriented test framework. Istead of hack into objects and methods it deals with text appeared in STDOUT. It's a blackbox testing framework.

# tutorial

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

Othentic provides test runner called `story_check', it finds a story files, runs stories and validates STDOUT against story checks.

```
  story_check
  
```

( TODO: ) Add output of story_check here.


# Write your stories

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


# Story runner workflow

This is detailed explanation of how story runner compiles and then executes stories.

Story_check script consequentially hits two phases when execute swat stories:

- **Compilation phase** where stories are converted into Test::Harness format.
- **Execution phase** where perl test files are recursively executed by prove.

## Story to Test::Harness compilation

One important thing about story checksis that internally they are represented as Test::More asserts. This is how it work: 

Let's have 3 stories:

    addition/story.pl,story.check
    multiplication/story.pl,story.check

Story_check parse every story and the creates a perl test file for it:

    addition/story.t
    multiplication/story.t

Every story check is converted into the list of the Test::More asserts:

```
    # addition/story.t
    SKIP {
        ok($status,'response matches 6'); 
        ok($status,'response matches 12');
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
            - Execute Test::More assert
        - The end of Test::More asserts iterator
    - The end of execution phase
    

# TAP

Othentic produces output in [TAP](https://testanything.org/) format, that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this. 

Here is example for converting swat tests into JUNIT format:

    story_check --formatter TAP::Formatter::JUnit

# Prove settings

Othentic utilize [prove utility](http://search.cpan.org/perldoc?prove) to run tests, all prove related parameters are passed as is to prove.
Here are some examples:

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
- Authors of - perl, TAP, Test::More, Test::Harness

