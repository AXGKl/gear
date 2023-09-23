#!/usr/bin/env bash
set -e
test -e "gear" || exit 1
here="$(pwd)"

function main {
    echo "$PATH"
    ./gear up || true
    cd "$HOME"

    source .activate_gears || true
    echo "$PATH"

    binenv install gdu
    gdu -n

    asdf install nodejs
    node --version

    cat .condarc | grep auto_update_conda | grep false
    micromamba install -y redis-server
    redis-server --version

}
main "$@"
