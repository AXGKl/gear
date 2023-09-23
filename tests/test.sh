#!/usr/bin/env bash
set -e
test -e "gear" || exit 1
here="$(pwd)"
fs="$1"
d_test="$here/build/$fs"
test -z "$fs" && exit 1

function get_clean_fs {
    podman run "$fs" echo || exit 1
    img="$(podman ps -a | grep "$fs" | head -n 1 | cut -d ' ' -f1)"
    test -d "$d_test" && sudo rm -rf "$d_test"
    mkdir -p "$d_test"
    (
        cd "$d_test"
        podman export "$img" | tar xf -
        podman rm "$img"
    )
    cp "gear" "$d_test/"
}

function main {
    get_clean_fs
    #sudo systemd-nspawn -D "$d_test" /gear -x -y -u user up
    sudo systemd-nspawn -D "$d_test" /gear -y -u user up
}

main "$@"
