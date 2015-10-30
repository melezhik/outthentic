use inc::Module::Install;

# Define metadata
name           'Outthentic';
abstract       'text oriented blackbox testing framework';

all_from       'lib/Outthentic.pm';

# Specific dependencies
requires    'Test::More';
requires    'Test::Harness';
requires    'File::Temp';

requires    'Outthentic::DSL', "0.0.2";

license     'perl';
repository  'https://github.com/melezhik/outthentic';

install_script 'bin/strun';

no_index    directory => 'examples';

WriteAll;


