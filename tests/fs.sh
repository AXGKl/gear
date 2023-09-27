#!/usr/bin/env bash
set -eu

test -e "gear" || exit 1
here="$(pwd)"

function get_clean_fs {
    local fs="$1" d="$2"

    podman run "$fs" echo || exit 1
    img="$(podman ps -a | grep "$fs" | head -n 1 | cut -d ' ' -f1)"
    mkdir -p "$d"
    (
        cd "$d"
        podman export "$img" | tar xf -
        podman rm "$img"
    )
}

function in_fs { sudo systemd-nspawn -D "$d_test" "$@"; }

function main {
    fs="$1"
    shift
    d_test="$here/build/$fs"
    test -e "$d_test" || get_clean_fs "$fs" "$d_test"
    sudo systemd-nspawn --ephemeral -D "$d_test" \
        --bind "$(pwd)/gear:/gear" \
        --bind "$(pwd)/tests:/tests" \
        --chdir / \
        "$@"
}

main "$@"
