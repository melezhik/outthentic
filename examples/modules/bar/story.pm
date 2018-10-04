#push our @foo, "bar was here";

set_stdout(
    "bar done\n".story_var('VAR')."\n"
);
