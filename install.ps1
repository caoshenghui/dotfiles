$script_dir = $PSScriptRoot

function InstallScript{
    param(
        [string]$dir
    )
    $script = Join-Path $dir "install.ps1"
    if (Test-Path $script){
        Invoke-Expression $script
    }
    else {
        Write-Error "$script not found."
    }
}

if ($args) {
    foreach ($arg in $args) {
        InstallScript -dir (join-Path $script_dir $arg)
    }
}
else {
    $sub_dirs = Get-ChildItem ./ -Directory
    foreach ($sub_dir in $sub_dirs) {
        InstallScript -dir $sub_dir.FullName
    }
}

# $config_dir = "$env:USERPROFILE\.config"
# New-Item -ItemType Directory -Path $config_dir *>$null
