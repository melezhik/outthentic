use inc::Module::Install;

# Define metadata
name           'Outthentic';
abstract       'Generic testing, reporting, monitoring framework consuming Outthentic::DSL';

all_from       'lib/Outthentic.pm';

# Specific dependencies
requires    'Test::More';
requires    'Test::Harness';
requires    'File::Temp';
requires    'Config::Tiny';
requires    'YAML';

requires    'Outthentic::DSL', "0.1.0";

license     'perl';
repository  'https://github.com/melezhik/outthentic';

install_script 'bin/strun';

no_index    directory => 'examples';

WriteAll;


