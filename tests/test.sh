#!/usr/bin/env bash
set -xe
fs="$1"
here="$(dirname "$0")"

function into_clean_fs {
    cd "$here"
    cd ../
    rm -rf "$fs"
    podman run "$fs" echo
    img="$(podman ps -a | grep "$fs" | head -n 1 | cut -d ' ' -f1)"
    mkdir "$fs"
    cd "$fs"
    podman export "$img" | tar xf -
    podman rm "$img"
    cp ../gear .
}

function main {
    into_clean_fs
    sudo chroot . ./gear -u user up
}

main "$@"
