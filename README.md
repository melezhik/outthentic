# outhentic

print something into stdout and test

# description
Othentic is text oriented test framework. Istead of hack into objects and methods it deals with text appeared in STDOUT.
It's blackbox testing framework

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
