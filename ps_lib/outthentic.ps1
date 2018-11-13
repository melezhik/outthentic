
function ping {

  Write-Host "pong"

}

function story_var {

  Param($Name)  

  $cache_dir = cache_dir

  $file = "$cache_dir/variables.json"

  $json = Get-Content -Raw -Path $file | ConvertFrom-Json

  return $json.$Name

}

function config {

  Param($Name)  

  $cache_dir = cache_dir

  $file = "$cache_dir/config.json"

  $json = Get-Content -Raw -Path $file | ConvertFrom-Json

  return $json.$Name

}


function set_stdout {

  Param($line)

  $file = stdout_file

  $line | Out-File $file

}


function run_story {

    Param($path, $params)

    $debug_mod12 = debug_mod12

    if ( $debug_mod12 -eq '1' ) {
        Write-Host "# run downstream story: $path"
    }

    my $params_json = $params | ConvertTo-Json -Depth 10

    Write-Host "story_var_json_begin"

    Write-Host $params_json

    Write-Host "story_var_json_end"

    Write-Host "story: $path"

}


function ignore_story_err {

  Param($val)

  Write-Host "ignore_story_err: $val"

}

function quit {

  Param($msg)

  Write-Host "quit: $msg"

  exit

}

function outthentic_die {

  Param($msg)

  Write-Host "outthentic_die: $msg"

  exit

}


