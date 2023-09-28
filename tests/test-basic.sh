#!/usr/bin/env bash
set -eu

case "$(uname)" in Linux) OS=linux ;; Darwin) OS=darwin ;; *) OS= ;; esac

function linux_or_osx_base {
    D_HOME="/home/"
    test "$OS" = darwin && D_HOME='/Users/'
    test $(whoami) = 'root' && D_HOME='/root/'
    ./gear up b a mm
    source "$HOME/.gears"
    ./gear e gdu
    gdu -v
    ./gear i redis-server,lazygit b:rg a:nodejs:node
    type redis-server | grep micromamba/bin/redis-server
    redis-server --version | grep Redis
    type lazygit | grep "$D_HOME"
    lazygit --version
    type rg | grep "$D_HOME"
    rg --version
    type npm
    npm --version
    type npm | grep "$D_HOME"
}

function with_nix_and_brew {
    ./gear i n:firefox brew:gdu
    test -e "$HOME/.nix-profile/bin/firefox"
    source "$HOME/.gears"
    gdu-go --version
    type gdu-go | grep linuxbrew
}

main() {
    test "${1:-}" = "-pdb" && { export GEAR_NO_EXIT_AT_ERR=true && shift; }
    "${1:-/bin/bash}"
}

main "$@"
