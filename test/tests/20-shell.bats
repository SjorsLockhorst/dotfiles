#!/usr/bin/env bats
load helpers
bats_require_minimum_version 1.5.0

setup() {
    skip_unless zsh
}

@test "oh-my-zsh and its plugins are installed" {
    [ -f ~/.oh-my-zsh/oh-my-zsh.sh ]
    [ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]
}

@test "zsh is the login shell" {
    shell=$(getent passwd "$(id -un)" | cut -d: -f7)
    [ "$(basename "$shell")" = zsh ]
    # sddm doesn't list users whose shell isn't in /etc/shells
    grep -qx "$shell" /etc/shells
}

@test "an interactive zsh starts without errors" {
    run --separate-stderr zsh -i -c 'echo ok'
    echo "stderr: $stderr"
    [ "$status" -eq 0 ]
    [ "$output" = ok ]
    [ -z "$stderr" ]
}

@test "starship prompt is set up" {
    run zsh -i -c 'echo $STARSHIP_SHELL'
    [ "$output" = zsh ]
}

@test "nvm is installed and loads in zsh" {
    run zsh -i -c 'type nvm'
    [ "$status" -eq 0 ]
}
