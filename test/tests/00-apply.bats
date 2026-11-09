#!/usr/bin/env bats
# The bootstrap itself: a non-interactive `chezmoi init --apply` on a fresh install.

@test "chezmoi init --apply succeeds" {
    cat /out/apply.log
    [ "$(cat /out/apply.status)" -eq 0 ]
}

@test "chezmoi manages the dotfiles" {
    [ "$(chezmoi managed | wc -l)" -gt 50 ]
    [ -f ~/.zshrc ]
}

@test "the deployed files match the source (chezmoi verify)" {
    chezmoi verify
}

@test "nothing left to apply (chezmoi diff is empty)" {
    run chezmoi diff --no-pager
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "a second apply succeeds and changes nothing" {
    chezmoi apply --no-tty </dev/null
    run chezmoi diff --no-pager
    [ -z "$output" ]
}

@test "encrypted files are decrypted" {
    [ -f ~/.ssh/id_rsa ]
    head -1 ~/.ssh/id_rsa | grep -q 'PRIVATE KEY'
}
