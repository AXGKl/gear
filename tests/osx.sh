#!/usr/bin/env bash
set -e
test -e "gear" || exit 1
here="$(pwd)"

function main {
    echo "$PATH"
    ./gear up || true
    PATH="$HOME/.local/bin:$PATH"

    cd "$HOME"
    source .activate_gears || true
    echo "$PATH"

    gear install gdu
    gdu -n ./hostedtoolcache

    gear install nodejs # asdf
    node --version

    cat .condarc | grep auto_update_conda | grep false
    gear -x install redis-server
    redis-server --version

}
main "$@"
