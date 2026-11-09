#!/usr/bin/env bats

@test "tmux loads its config" {
    tmux -L bats -f ~/.tmux.conf new-session -d
    tmux -L bats kill-server
}

@test "tpm is installed" {
    [ -x ~/.tmux/plugins/tpm/tpm ]
}

@test "vim starts without errors" {
    # -es hides errors: dump :messages to see them
    run vim -es -N -u ~/.vimrc +"redir! > $BATS_TEST_TMPDIR/msgs" +'silent messages' +'redir END' +qa
    cat "$BATS_TEST_TMPDIR/msgs"
    [ "$status" -eq 0 ]
}

@test "vim-plug is installed" {
    [ -f ~/.vim/autoload/plug.vim ]
}

@test "git config is valid" {
    git config --global --list >/dev/null
}

@test "own scripts in ~/.local/bin are executable" {
    for f in theme-set theme-list theme-render theme-menu tmux-sessionizer; do
        [ -x ~/.local/bin/$f ]
    done
}
