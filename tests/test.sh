#!/usr/bin/env bash
set -e
fs="$!"
here="$(dirname "$0")"

function clean_fs {
    cd "$here"
    cd ../
    rm -rf "$fs"
    podman run "$fs" echo
    img="$(podman ps -a | grep "$fs" | head -n 1 | cut -d ' ' -f1)"
    mkdir "$fs"
    cd "$fs"
    podman export "$img" | tar xf -
    cp ../gear .
}

function main {
    clean_fs
    sudo chroot . ./gear -u user up
}

main "$@"
