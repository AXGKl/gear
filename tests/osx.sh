#!/usr/bin/env bash
set -e
test -e "gear" || exit 1
here="$(pwd)"

function main {
    ./gear up

    # we've put it there. change to your liking
    PATH="$HOME/.local/bin:$PATH"

    # first in your shell act:
    source "$HOME/.activate_gears"

    gear install gdu
    gdu -n "/tmp"

    gear install nodejs 17.1.1 # asdf
    node --version

    gear install redis-server
    redis-server --version

}
main "$@"
