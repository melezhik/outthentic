# SYNOPSIS

Execute bash commands

# INSTALL

    $ sparrow plg install bash

# USAGE

## Manually

    $ sparrow plg run bash --param user=foo --param command="'echo hello world'"


## With sparrowdo

    $ cat sparrowfile

    task-run "server uptime", "bash", %(
      user      => 'root',
      command   => 'uptime',
      debug     => 1,
    );


# Parameters

## user

A user to execute a command. No default value. Optional.

## command

A command to be executed. No default value. Obligatory.

## expect_stdout

This is optional parameter. Verify if command print something into stdout. This should be Perl5 regex string.

Example:

    $ sparrow plg run --param command="echo I AM OK" --param expect_stdout='I AM \S+'

Or via sparrowdo:


    task-run "server uptime", "bash", %(
      command   => 'uptime',
      debug     => 0,
      expect_stdout => '\d\d:\d\d:\d\d'
    );
    

## debug

Set bash debug mode on. Default value is `0` ( do not set ).

## passing environment variables

Use envvars parameter. For example:

    task-run "http GET request", "bash", %(
      command   => 'curl https://sparrowhub.org',
      envvars   => %(
        http_proxy  => input_params('HttpProxy'),
        https_proxy => input_params('HttpsProxy'),
      )
    );

# cwd

Change to `cwd` directory priorly

# Author

[Alexey Melezhik](mailto:melezhik@gmail.com)

