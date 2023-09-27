#!/usr/bin/env bash

D_HOME="/home/"
set -eu

function tests {
    ./gear -h
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
function main:osx {
    D_HOME='/Users/'
    tests

}

function main:fatlinux {
    tests
}

main() {
    local testset="$1"
    "main:$testset"
}

main "$@"
