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
