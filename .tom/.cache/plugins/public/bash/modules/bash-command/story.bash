user=$(config user)
command=$(config command)
debug=$(config debug)
envvars=$(story_var envvars)
cwd=$(config cwd)

if test $debug -eq 1; then
  set -x;
fi

#if  test ! -z "${envvars}"; then
#  echo $envvars
#fi


if  test ! -z "${cwd}"; then
  cwd_cmd="cd $cwd &&"
fi

if test -z $user; then
  bash -c "${cwd_cmd} ${envvars} ${command}" || exit 1
else

  if [[ $os == alpine ]]; then
    su -s `type -P bash` -l -c "${cwd_cmd} ${envvars} ${command}" $user || exit 1
  else
    su --shell `type -P bash` --login -c "${cwd_cmd} ${envvars} ${command}" $user || exit 1
  fi
fi


