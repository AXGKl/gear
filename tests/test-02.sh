#!/usr/bin/env bash

D_HOME="/home/"
set -x

function tests {
    ./gear i nix:firefox brew:gdu
    source "${HOME}/.gears"
    gdu-go -v
    type firefox
    firefox --version
}

function main:fatlinux {
    tests
}

main() {
    local testset="$1"
    "main:$testset"
}

main "$@"
