if test -f "${story_dir}/common.bash"; then
  source "${story_dir}/common.bash"
fi

if test -f "${cache_dir}/variables.bash"; then
  source "${cache_dir}/variables.bash"
fi

function set_stdout {
  echo $* 1>>"${stdout_file}"
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

