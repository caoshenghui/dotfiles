if (-not (Get-Command wt -ErrorAction SilentlyContinue)) {
    Exit
}

$script_path = Split-Path $MyInvocation.MyCommand.Path
$file_name = "settings.json"
$wt_path = (Get-Item "${env:LOCALAPPDATA}\Packages\Microsoft.WindowsTerminal_*")
$settings_file = Join-Path $wt_path "LocalState" $file_name
Remove-Item $settings_file 2>$null
# New-Item -ItemType HardLink -Path $settings_file -Target (Join-Path $script_path $file_name) *>$null
Copy-Item -Path (Join-Path $script_path $file_name) -Destination $settings_file  *>$null

# wt icon
Copy-Item -Path (Join-Path $script_path "assets") -Destination (Join-Path $wt_path "RoamingState") -Recurse *>$null
