#!/usr/bin/env bash
set -e
test -e "gear" || exit 1
here="$(pwd)"

function main {
    ./gear up || true

    # we've put it there. change to your liking
    PATH="$HOME/.local/bin:$PATH"

    # first in your shell act:
    source "$HOME/.activate_gears"

    gear install gdu
    gdu -n "$HOME/.hostedtoolcache"

    gear install nodejs 17.1.1 # asdf
    node --version

    gear install redis-server
    redis-server --version

}
main "$@"
