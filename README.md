# outhentic

print something into stdout and test

# description
Othentic is text oriented test framework. Istead of hack into objects and methods it deals with text apeared in STDOUT.
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

- Run a story:

```
  story_check
  
```
