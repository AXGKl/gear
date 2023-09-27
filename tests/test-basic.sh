#!/usr/bin/env bash
echo "In $*"
D_HOME="/home/"
test $(whoami) = 'root' && D_HOME='/root/'
set -eu
interactive=false
pdb() {
    # this is run in ephemereal containers, want to remain inside on my laptop in case of errors:
    local parent_lineno="$1"
    local code="$2"
    test "$code" = '0' && exit 0
    local commands="$3"
    echo "error exit status $code, at file $0 on or near line $parent_lineno: $commands"
    $interactive && /bin/bash
    exit "$code"
}

trap 'pdb "${LINENO}/${BASH_LINENO}" "$?" "$BASH_COMMAND"' EXIT

function tests {
    ./gear -h
    ./gear up b a mm
    source "$HOME/.gears"
    ./gear e gdu
    gdu -v
    ./gear i redis-server,lazygit b:rg a:nodejs:node
    type redis-server | grep micromamba/bin/redis-server
    redis-server --version | grep Redis
    type lazygit | grep "$D_HOME"
    lazygit --version
    type rg | grep "$D_HOME"
    rg --version
    type npm
    npm --version
    type npm | grep "$D_HOME"
}
function main:osx {
    D_HOME='/Users/'
    tests

}

function main:linux {
    tests
}

main() {
    test "${1:-}" = "-i" && {
        interactive=true
        shift
    }
    local testset="${1:-linux}"
    "main:$testset"
}

main "$@"
