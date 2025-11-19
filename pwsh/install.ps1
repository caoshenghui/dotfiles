if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Exit
}
$file_name = "Microsoft.PowerShell_profile.ps1"
$cpath = Split-Path $MyInvocation.MyCommand.Path
$profile_path = Split-Path $PROFILE
New-Item -ItemType Directory -Path $profile_path 2>$null
$profile = Join-Path $profile_path $file_name
Remove-Item $profile 2>$null
New-Item -ItemType HardLink -Path $profile -Target (Join-Path $cpath $file_name) *>$null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name Terminal-Icons
