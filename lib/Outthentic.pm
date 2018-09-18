package Outthentic;

our $VERSION = '0.4.0';

1;

package main;

use Carp;
use Config::General;
use YAML qw{LoadFile};
use JSON;
use Cwd;

use strict;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Outthentic::Story;
use Term::ANSIColor;
use Hash::Merge qw{merge};
use Time::localtime;
use Capture::Tiny;

Hash::Merge::specify_behavior(
    {
                'SCALAR' => {
                        'SCALAR' => sub { $_[1] },
                        'ARRAY'  => sub { [ $_[0], @{$_[1]} ] },
                        'HASH'   => sub { $_[1] },
                },
                'ARRAY' => {
                        'SCALAR' => sub { $_[1] },
                        'ARRAY'  => sub { [ @{$_[1]} ] },
                        'HASH'   => sub { $_[1] }, 
                },
                'HASH' => {
                        'SCALAR' => sub { $_[1] },
                        'ARRAY'  => sub { [ values %{$_[0]}, @{$_[1]} ] },
                        'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
                },
        }, 
        'Strun', 
);

my $config_data; 

our $STATUS = 1;

sub execute_cmd {
    my $cmd = shift;
    note("execute cmd: $cmd") if debug_mod2();
    (system($cmd) == 0);
}

sub execute_cmd2 {

    my $cmd = shift;
    my $out;

    my $format = get_prop('format');

    note("execute scenario: $cmd") if debug_mod2();

    my $stdout; my $stderr; my $exit;

    if ($format eq 'production'){
      ( $stdout, $stderr, $exit) =  Capture::Tiny::capture { system( $cmd ) };
    } else{
      ( $stdout, $stderr, $exit) =  Capture::Tiny::tee { system( $cmd ) };
    }

    return ($exit >> 8,$stdout.$stderr);
}

sub config {
  $config_data
}

sub dump_config {
  my $json = JSON->new->pretty;
  print $json->encode(config());
}

sub nocolor {
  get_prop('nocolor')
}

sub populate_config {

    unless (config()){
        if (get_prop('ini_file_path') and -f get_prop('ini_file_path') ){
          my $path = get_prop('ini_file_path');
          my %c  = Config::General->new( 
            -InterPolateVars => 1 ,
            -InterPolateEnv  => 1 ,
            -ConfigFile => $path 
          )->getall or confess "file $path is not valid config file";
          $config_data = {%c};
        }elsif(get_prop('yaml_file_path') and -f get_prop('yaml_file_path')){
          my $path = get_prop('yaml_file_path');
          ($config_data) = LoadFile($path);
        }elsif ( get_prop('json_file_path') and -f get_prop('json_file_path') ){
          my $path = get_prop('json_file_path');
          open DATA, $path or confess "can't open file $path to read: $!";
          my $json_str = join "", <DATA>;
          close DATA;
          $config_data = from_json($json_str);
        }elsif ( -f 'suite.ini' ){
          my $path = 'suite.ini';
          my %c  = Config::General->new( 
            -InterPolateVars => 1 ,
            -InterPolateEnv  => 1 ,
            -ConfigFile => $path 
          )->getall or confess "file $path is not valid config file";
          $config_data = {%c};
        }elsif ( -f 'suite.yaml'){
          my $path = 'suite.yaml';
          ($config_data) = LoadFile($path);
        }elsif ( -f 'suite.json'){
          my $path = 'suite.json';
          open DATA, $path or confess "can't open file $path to read: $!";
          my $json_str = join "", <DATA>;
          close DATA;
          $config_data = from_json($json_str);
        }else{
          $config_data = { };
        }
    }

    my $default_config;

    if ( -f 'suite.ini' ){
      my $path = 'suite.ini';
      my %c  = Config::General->new( 
        -InterPolateVars => 1 ,
        -InterPolateEnv  => 1 ,
        -ConfigFile => $path 
      )->getall or confess "file $path is not valid config file";
      $default_config = {%c}; 
    }elsif ( -f 'suite.yaml'){
      my $path = 'suite.yaml';
      ($default_config) = LoadFile($path);
    }elsif ( -f 'suite.json'){
      my $path = 'suite.json';
      open DATA, $path or confess "can't open file $path to read: $!";
      my $json_str = join "", <DATA>;
      close DATA;
      $default_config = from_json($json_str);
    }else{
      $default_config = { };
    }


    my @runtime_params;

    if (my $args_file = get_prop('args_file') ){
      open ARGS_FILE, $args_file or die "can't open file $args_file to read: $!";
      while (my $l = <ARGS_FILE>) {
        chomp $l;
        next unless $l=~/\S/;
        push @runtime_params, $l;
      }
      close ARGS_FILE;
    } else {
      @runtime_params = split /:::/, get_prop('runtime_params');
    }

    my $config_res = merge( $default_config, $config_data );

    PARAM: for my $rp (@runtime_params){

      my $value;

      if ($rp=~s/=(.*)//){
        $value = $1;
      }else{
        next PARAM;
      }  

      my @pathes = split /\./, $rp;
      my $last_path = pop @pathes;

      my $root = $config_res;
      for my $path (@pathes){
        next PARAM unless defined $root->{$path};
        $root = $root->{$path};
      }
      $root->{$last_path} = $value;
    }

    open CONFIG, '>', story_cache_dir().'/config.json' 
      or die "can't open to write file ".story_cache_dir()."/config.json : $!";
    my $json = JSON->new();
    print CONFIG $json->encode($config_res);
    close CONFIG;

    note("configuration populated and saved to ".story_cache_dir()."/config.json") if debug_mod12;

    # populating cli_args from config_data{args}
    unless (get_prop('cli_args')){
      if ($config_res->{'args'} and ref($config_res->{'args'}) eq 'ARRAY'){
        note("populating cli args from args in configuration data") if debug_mod12;
        my @cli_args;
        for my $item (@{$config_res->{'args'}}){
          if (! ref $item){
            push @cli_args, $item;
          } elsif(ref $item eq 'HASH'){
            for my $k ( keys %{$item}){
              my $k1 = $k;
              if ($k1=~s/^~//){
                push @cli_args, '-'.$k1, $item->{$k};
              }else{
                push @cli_args, '--'.$k1, $item->{$k};
              }
            }
          } elsif(ref $item eq 'ARRAY'){
            push @cli_args, map {
              my $v = $_;
              $v=~s/^~// ? '-'.$v : '--'.$v;
            } @{$item};
          };
        }
        note("cli args set to: ".(join ' ', @cli_args)) if debug_mod12;
        set_prop('cli_args', join ' ', @cli_args );
      }
   }

    open CLI_ARGS, '>', story_cache_dir().'/cli_args' 
      or die "can't open to write file ".story_cache_dir()."/cli_args : $!";
    print CLI_ARGS get_prop('cli_args');
    close CLI_ARGS;

    note("cli args populated and saved to ".story_cache_dir()."/cli_args") if debug_mod12;

    # it should be done once
    # and it always true
    # as populate_config() reach this lines
    # only once, when config is really populated

    if ( get_prop('cwd') ) {
      unless (chdir(get_prop('cwd'))){
        $STATUS = 0;
        die "can't change working directory to: ".(get_prop('cwd'))." : $!";
      }

    }
    
    return $config_data = $config_res;
    return $config_data;
}

sub print_story_header {

    my $task_name = get_prop('task_name');

    my $format = get_prop('format');
    my $data;
    if ($format eq 'production') {
        $data = timestamp().' : '.($task_name || '').' '.(short_story_name($task_name))
    } elsif ($format ne 'concise') {
        $data = timestamp().' : '.($task_name ||  '' ).' '.(nocolor() ? short_story_name($task_name) : colored(['yellow'],short_story_name($task_name)))
    }
    if ($format eq 'production'){
      note($data,1)
    } else {
      note($data)
    }
}

sub run_story_file {

    return get_prop('stdout') if defined get_prop('stdout');

    set_prop('has_scenario',1);

    my $format = get_prop('format');

    my $story_dir = get_prop('story_dir');

    if ( get_stdout() ){


        print_story_header();

        note("stdout is already set") if debug_mod12;

        unless ($format eq 'production') {
          for my $l (split /\n/, get_stdout()){
            note($l);
          }
        }

        set_prop( stdout => get_stdout() );
        set_prop( scenario_status => 1 );

        Outthentic::Story::Stat->set_scenario_status(1);
        Outthentic::Story::Stat->set_stdout(get_stdout());

    } else {


        my $story_command;

        if ( -f "$story_dir/story.pl" ){

          if (-f project_root_dir()."/cpanfile" ){
			if ( $^O  =~ 'MSWin'  ){
				$story_command  = "set PATH=%PATH%;".project_root_dir()."/local/bin/ && perl -I ".story_cache_dir().
		        " -I ".project_root_dir()."/local/lib/perl5 -I".project_root_dir()."/lib " ."-MOutthentic::Glue::Perl $story_dir/story.pl";						
			} else {
	            $story_command  = "PATH=\$PATH:".project_root_dir()."/local/bin/ perl -I ".story_cache_dir().
		        " -I ".project_root_dir()."/local/lib/perl5 -I".project_root_dir()."/lib " ."-MOutthentic::Glue::Perl $story_dir/story.pl";	
			}
          } else {
            $story_command = "perl -I ".story_cache_dir()." -I ".project_root_dir()."/lib"." -MOutthentic::Glue::Perl $story_dir/story.pl";
          }

          print_story_header();

        }elsif(-f "$story_dir/story.rb") {

            my $story_file = "$story_dir/story.rb";

            my $ruby_lib_dir = File::ShareDir::dist_dir('Outthentic');

            if (-f project_root_dir()."/Gemfile" ){
              $story_command  = "cd ".project_root_dir()." && bundle exec ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $story_file";
            } else {
              $story_command = "ruby -I $ruby_lib_dir -r outthentic -I ".story_cache_dir()." $story_file";
            }

          print_story_header();

        }elsif(-f "$story_dir/story.py") {

            my $python_lib_dir = File::ShareDir::dist_dir('Outthentic');
            $story_command  = "PYTHONPATH=\$PYTHONPATH:".(story_cache_dir()).
            ":$python_lib_dir python $story_dir/story.py";

            print_story_header();

        } elsif(-f "$story_dir/story.bash") {

            my $bash_lib_dir = File::ShareDir::dist_dir('Outthentic');
            $story_command = "bash -c 'source ".story_cache_dir()."/glue.bash";
            $story_command.= " && source $bash_lib_dir/outthentic.bash";
            $story_command.= " && source $story_dir/story.bash'";

            print_story_header();

        } else {

          # print "empty story\n";

          return;
        }

        my ($ex_code, $out) = execute_cmd2($story_command);

        print_story_messages($out) if $format eq 'production';

        if ($ex_code == 0) {
            outh_ok(1, "scenario succeeded" ) unless $format eq 'production';
            set_prop( scenario_status => 1 );
            Outthentic::Story::Stat->set_scenario_status(1);
            Outthentic::Story::Stat->set_stdout($out);

        }elsif(ignore_story_err()){
            outh_ok(1, "scenario failed, still continue due to `ignore_story_err' is set");
            set_prop( scenario_status => 2 );
            Outthentic::Story::Stat->set_scenario_status(2);
            Outthentic::Story::Stat->set_stdout($out);
        }else{
            if ( $format eq 'production'){
              print "$out";
              outh_ok(0, "scenario succeeded", $ex_code);
            } else {
              outh_ok(0, "scenario succeeded", $ex_code);
            }
            set_prop( scenario_status => 0 );
            Outthentic::Story::Stat->set_scenario_status(0);
            Outthentic::Story::Stat->set_stdout($out);
            Outthentic::Story::Stat->set_status(0);
        }

        set_prop( stdout => $out );

    }


    return get_prop('stdout');
}

sub header {

    my $project = project_root_dir();
    my $story = get_prop('story');
    my $story_type = get_prop('story_type');
    my $story_file = get_prop('story_file');
    my $debug = get_prop('debug');
    my $ignore_story_err = ignore_story_err();
    
    note("project: $project");
    note("story: $story");
    note("story_type: $story_type");
    note("debug: $debug");
    note("ignore story errors: $ignore_story_err");

}

sub run_and_check {

    my $story_check_file = shift;

    my $format = get_prop('format');

    header() if debug_mod2();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    eval { dsl()->{output} = run_story_file() };

  
    if ($@) {
      $STATUS = 0;
      die "story run error: $@";
    }

    return unless get_prop('scenario_status'); # we don't run checks for failed scenarios

    return unless $story_check_file;
    return unless -s $story_check_file; # don't run check when check file is empty

    eval {
          open my $fh, $story_check_file or confess $!;
          my $check_list = join "", <$fh>; close $fh;
          dsl()->validate($check_list)
    };

    my $err = $@;
    my $check_fail=0;
    for my $r ( @{dsl()->results}){
        note($r->{message}) if $r->{type} eq 'debug';
        if ($r->{type} eq 'check_expression' ){
          Outthentic::Story::Stat->add_check_stat($r);
          $check_fail=1 unless $r->{status};
          if ($format eq 'production'){
            outh_ok($r->{status}, $r->{message}) unless $r->{status}; 
          } else {
            outh_ok($r->{status}, $r->{message}); 
          }
          Outthentic::Story::Stat->set_status(0) unless $r->{status};
        };

    }


    if ($err) {
      $STATUS = 0;
      die "validator error: $err";
    }

    if ($format eq 'production' and $check_fail) {
      print get_prop("stdout");
    }
}

      
sub print_story_messages {
  my $out = shift;
  print " [msg] " if $out=~/outthentic_message/;
  my @m = ($out=~/outthentic_message:\s+(.*)/g);
  print join " ", @m;
  print "\n";
}

sub outh_ok {

    my $status    = shift;
    my $message   = shift;
    my $exit_code = shift;

    my $format = get_prop('format');

    if ($format ne 'concise'){
      if ($status) {
        print nocolor() ? "ok\t$message\n" : colored(['green'],"ok\t$message")."\n";
      } else {
        print nocolor() ? "not ok\t$message\n" : colored(['red'], "not ok\t$message")."\n";
      }
    }

    if ($status == 0 and $STATUS != 0 ){
      $STATUS = ($exit_code == 1 ) ? -1 : 0;
    }
}

sub note {

    my $message = shift;
    my $no_new_line = shift;

    binmode(STDOUT, ":utf8");
    print $message;
    print "\n" unless $no_new_line;

}


sub print_meta {

    open META, get_prop('story_dir')."/meta.txt" or die $!;

    my $task_name = get_prop('task_name');

    #note( ( nocolor() ? short_story_name($task_name) : colored( ['yellow'], short_story_name($task_name) ) ));

    while (my $i = <META>){
        chomp $i;
        $i='@ '.$i;
        note( nocolor() ? $i : colored( ['magenta'],  "$i" ));
    }
    close META;

}

sub short_story_name {

    my $task_name = shift;

    my $story_dir = get_prop('story_dir');

    my $cwd_size = scalar(split /\//, get_prop('project_root_dir'));

    my $short_story_dir;

    my $i;

    for my $l (split /\//, $story_dir){
      $short_story_dir.=$l."/" unless $i++ < $cwd_size;

    }

    my $story_vars = story_vars_pretty();

    $short_story_dir ||= "/";

    my @ret;

    push @ret, "[path] $short_story_dir" if $short_story_dir;
    push @ret, "[params] $story_vars" if $story_vars;

    join " ", @ret;

}

sub timestamp {
  sprintf '%02d-%02d-%02d %02d:%02d:%02d', 
    localtime->year()+1900, 
    localtime->mon()+1, localtime->mday, 
    localtime->hour, localtime->min, localtime->sec;
}

END {

  #print "STATUS: $STATUS\n";

  if ($STATUS == 1){
    exit(0);
  } elsif($STATUS == -1){
    exit(1);
  } else{
    exit(2);
  }

  
}

1;


__END__

=pod


=encoding utf8


=head1 Name

Outthentic - Multipurpose scenarios framework.


=head1 Synopsis

Multipurpose scenarios framework.


=head1 Build status

L<![Build Status](https://travis-ci.org/melezhik/outthentic.svg)|https://travis-ci.org/melezhik/outthentic>


=head1 Install

    $ cpanm Outthentic

=head1 Documentation

See L<GH pages|https://github.com/melezhik/outthentic>

=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Home Page

L<https://github.com/melezhik/outthentic|https://github.com/melezhik/outthentic>


=head1 See also

=over

=item *

L<Sparrow|https://github.com/melezhik/sparrow> - Multipurposes scenarios manager.



=item *

L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl> - Outthentic::DSL specification.



=item *

L<Swat|https://github.com/melezhik/swat> - Web testing framework.



=back


=head1 Thanks

To God as the One Who inspires me in my life!

