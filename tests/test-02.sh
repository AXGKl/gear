#!/usr/bin/env bash

D_HOME="/home/"
set -eu

function tests {
    ./gear -x i nix:firefox brew:gdu
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
