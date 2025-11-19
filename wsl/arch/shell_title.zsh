system_name=$(cat /etc/os-release | grep -oP '^NAME="\K[^"]+' | cut -d ' ' -f 1)
prefix="$system_name@$USERNAME"
print -Pn "\e]2;$prefix: %~\a"

precmd () {
    print -Pn "\e]2;$prefix: %~\a"
}
preexec () {
    local app_name=${1% *}
    print -Pn "\e]2;$prefix [$app_name]\a"
}

