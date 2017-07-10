# Check files syntax

Here is brief introduction into [Outthentic::DSL](https://github.com/melezhik/outthentic-dsl) which is used to define rules in check files.

# Plain strings checks

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

# Regular expressions

You may use regular expressions as well:


    # check file

    regexp: L+
    regexp: \d


    # verification output

    OK - output matches /L+/
    OK - output matches /\d/

See [check-expressions](https://github.com/melezhik/outthentic-dsl#check-expressions) in Outthentic::DSL documentation pages.

# Inline code, generators and asserts

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

## Generators

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


## Asserts

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


## Text blocks

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

