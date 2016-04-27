if test -f "${story_dir}/common.bash"; then
  source "${story_dir}/common.bash"
fi

function set_stdout {
  echo $* 1>>"${stdout_file}"
}
