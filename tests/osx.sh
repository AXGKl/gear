#!/usr/bin/env bash
set -e
test -e "gear" || exit 1
here="$(pwd)"

function main {
    echo "$PATH"
    ./gear up
    cd $HOME
    ls -lta
    source .activate_gears || true
    binenv install gdu
}
main "$@"
