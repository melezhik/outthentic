if test -f "${story_dir}/common.bash"; then
  source "${story_dir}/common.bash"
fi

if test -f "${cache_dir}/variables.bash"; then
  source "${cache_dir}/variables.bash"
fi

function set_stdout {
  echo $* 1>>"${stdout_file}"
}

function ignore_story_err {
  echo ignore_story_err: $1
}

function run_story {

  story_to_run=$1
  shift

  while [[ $# > 0 ]]
  do
  key="$1"
  shift
  value="$1"
  shift
  echo "story_var_bash: ${key} ${value}"
  done

  echo story: $story_to_run


}


function config {
   perl -MOutthentic::Glue::Bash -e config "${cache_dir}/config.json" $1
}

function story_var {
   perl -MOutthentic::Glue::Bash -e variables "${cache_dir}/variables.json" $1
}

