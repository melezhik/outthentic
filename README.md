# outhentic

print something into stdout and test

# description
Othentic is text oriented test framework. Istead of hack into objects and methods it deals with text appeared in STDOUT.
It's a blackbox testing framework

# tutorial

- Create a story file:

```
# story.pl

print "I am OK\n";
print "I am outhentic";

```

Story file is just a any perl script print out to a STDIN.


- Create a story check:

```
# story.check

  I am OK
  I am outhentic

```
Story check is a bunch of lines STDOUT should match. Here we require to have `I am OK' and `I am outhentic' lines in STDOUT. 

- Run a story:

```
  story_check
  
```
Story_check script finds a story files, runs stories and validates STDOUT against story checks.


# Write your stories

Here is a formal escription of outhentic project layout.

## Project

Ouhtentic project is bunch of related stroies. Every outhentic project needs a directory where all the stuff is placed. Let's create it project to test a simple calculator application:

```

  mkdir calc-app
  cd calc-app
  
```

## Stories and story checks

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
  print $calc(2+2), "\n";

  # multiplication/story.pl
  use MyCalc;
  my $calc = MyCalc->new();
  print $calc(2*3), "\n";

```

