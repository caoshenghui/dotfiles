<#
.SYNOPSIS
    WSL 环境初始化脚本
.DESCRIPTION
    此脚本负责 Windows 端的 WSL 配置，用户创建和权限设置
    系统级配置由 install.sh 的 root 部分处理
#>

# 检查 WSL 是否安装
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Error "WSL 未安装，请先安装 WSL"
    exit 1
}

# 获取脚本路径
$cpath = Split-Path $MyInvocation.MyCommand.Path
$wslconfig_file = Join-Path $HOME ".wslconfig"

# 复制 WSL 配置文件
Write-Output "复制 WSL 配置文件..."
Copy-Item (Join-Path $cpath "wslconfig") -Destination $wslconfig_file -Force

# 关闭所有 WSL 实例
Write-Output "关闭 WSL 实例..."
wsl --shutdown
Start-Sleep -Seconds 8

# 获取所有 WSL 发行版
$distros = Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object { (Get-ItemProperty -Path $_.PSPath).DistributionName }

foreach ($distro in $distros) {
    if (-not $distro -or $distro.Trim() -eq "") {
        Write-Warning "跳过空的发行版名称"
        continue
    }
    $name = $distro.ToLower()
    $path = Join-Path $cpath $name
    $install_sh = Join-Path $path "install.sh"

    if (Test-Path $install_sh) {
        Write-Output "`n配置 WSL 发行版: $name"

        # 1. 确保使用 WSL2
        Write-Output "设置为 WSL2..."
        wsl --set-version $name 2

        # 2. 转换为 WSL 路径
        $script = wsl wslpath -u ($install_sh -replace '\\','/')

        # 3. 执行系统级配置 (通过 install.sh --root)
        Write-Output "执行系统级配置..."
        wsl --distribution $name --user root -- bash -c "bash '$script' --root"

        # 4. 创建用户
        $username = Read-Host "请输入 $name 的用户名"
        if (-not $username) {
            Write-Warning "用户名不能为空，跳过 $name"
            continue
        }

        # 5. 设置用户密码
        $password = Read-Host "设置 $username 的密码" -AsSecureString
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

        # 6. 直接调用整合后的用户创建功能
        Write-Output "创建默认用户..."
        wsl --distribution $name --user root -- bash -c "bash '$script' --add-user '$username' '$plainPassword'"

        # 7. 设置默认用户（可选，如果 --add-user 已处理）
        wsl --manage $name --set-default-user $username
    }
}

Write-Output "`nWSL 配置完成!"
