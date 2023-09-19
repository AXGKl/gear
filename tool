#!/usr/bin/env bash
d_='# Meta Tool Manager

Manages meta tools

## Examples

---

When account already exists:

    ./tool x3@95.217.11.68 -u bs

- Copies this version of tool over (-u) to ~/.local/bin
- Installs (bs alias for bootstrap) for x3 user on 95... the core tools: binenev asdf micromamba

---

When no user yet existing but we have root login:

    pw=foo ./tool x3@95.217.11.68 -Suc bs -nb

- Requires `ssh root@95...` login! Because:
- Creates (-c) user x3 with password foo ($pw set when running)
- Copies this version of tool over (-u)
- Ensures passwordless sudo during install (-S) (needed for nix (-n) and brew (-b))
- Bootstraps (bs): binenv asdf micromamba nix brew

'
set -eu
export HOME="${HOME:-/root}"
H="$HOME"
ALL_TOOLMGRS="binenv asdf micromamba nix brew" # brew nix"
ALW_TOOLMGRS="binenv micromamba asdf"          # in inst order. asdf req git and curl (from micromamba)
MM_D_BASE="$H/micromamba"
case "$(uname)" in Linux) OS=linux ;; Darwin) OS=darwin ;; *) OS= ;; esac
ARCH="amd64"
case "$(uname -m)" in arm | aarch64) ARCH='' ;; esac
BINENV_URL="https://github.com/devops-works/binenv/releases/download/v0.19.0/binenv_${OS:-}_$ARCH"
ASDF_REPO="https://github.com/asdf-vm/asdf.git"
BREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
NIX_URL="https://nixos.org/nix/install"
NIX_URL_SELINUX="https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/installer-scripts/regular-nix-installer-selinux.sh"
FN_ACT_TOOLS="$H/.activate_tools"
with_nix=false
with_brew=false

# ------------------------------------------------------------------------- UTILS
function title { echo -e "\x1b[1;${2:-32}m$1\x1b[0m"; }
function nfo { echo -e "(ℹ️) $*"; }
function good { echo -e "🟩 $*"; }
function err { echo -e "🟥 $*" >&2; }
function die { set +x && err "$*" && exit 1; }
function shw { echo -e "⚙️ $*" && "$@"; }
function shtit { title "$@" 33 && "$@"; }
function confirm {
    local conf && echo "$* [y/N]? " && read -r conf
    test "$conf" = "y" -o "$conf" = "y" && return 0 || die "Unconfirmed"
}
function silent { "$@" 2>/dev/null 1>/dev/null; }
function try { silent "$@" || true; }
function have { silent type "$1"; }
function add_path { echo "$PATH" | grep -q "$1:" || export PATH="$1:$PATH"; }
function mkexe { chmod +x "$1"; }
function tmpfn { local d="/tmp/$USER.tool" && mkdir -p "$d" && echo "$d/$1"; }
function waitfor { while true; do have "$1" && break || sleep 0.1; done; }
function download {
    silent wget -q "$1" -O "$2" || silent curl -L "$1" >"$2" || die "Download failed: $1 -> $2"
    test -z "${3:-}" && return 0
    "$3" "$2"
}
function source_shell_hooks { test -e "$FN_ACT_TOOLS" && . "$FN_ACT_TOOLS" || true; }
function set_sh_sep {
    local sep && sep="$1"
    SH_SEP1="# >>> $sep initialize >>>" # mamba style, only one which does it
    SH_SEP2="# <<< $sep initialize <<<"
}

function bootstrap_add_shell_hook {
    local fnt act name="$1" what="$2" fn="$FN_ACT_TOOLS"
    touch "$fn"
    nfo "Modifying $fn for $name"
    set_sh_sep "$name"
    act="$SH_SEP1\n$what\n$SH_SEP2\n"

    grep -q "$SH_SEP1" <"$fn" || { echo -e "$act" >>"$fn" && return 0; } # had no hook yet
    fnt="$(tmpfn shhook)"
    grep -B 10000 "$SH_SEP1" <"$fn" | grep -v "$SH_SEP1" >"$fnt"
    echo -e "$act" >>"$fnt"
    grep -A 10000 "$SH_SEP2" <"$fn" | grep -v "$SH_SEP2" >>"$fnt"
    mv "$fnt" "$fn"
}

[ -t 0 ] && interactive=true || interactive=false
silent ls /root/ && have_root=true || have_root=false

# ------------------------------------------------------------------------- CMDS
function activate_all { for k in $ALL_TOOLMGRS; do try "${k}.activate"; done; }

function tool.status {
    for t in $ALL_TOOLMGRS; do
        "$t.bootstrapped" && { good "$t" && "$t.status" || true; } || err "$t"
    done
}

function tool.bootstrap {
    local act mgrs="$ALW_TOOLMGRS"
    while getopts onb opt; do
        case "$opt" in
            o) mgrs="" ;; # must be before n and b
            n) mgrs="$mgrs nix" ;;
            b) mgrs="$mgrs brew" ;;
            ?) die "not supported: $opt" ;;
        esac
    done

    true Boostrapping <<'    📓'
    We consider a tool manager "bootstrapped", when the shell hook was evaled.

    Eval does:

    - for binenv: path added
    - for asdf: asdf.sh sourced
    - for mm: micromamba avail as FUNCTION (not necessarily yet activated)

    I.e. the bootstrapping process does add the shell hook to `.<bash | zsh >rc`.
    User can change that and eval in other places but those should be evaled FROM shellrc as well.
    📓
    test -e "$HOME/.local/bin/tool" || { mkdir -p "$HOME/.local/bin" && cp "$0" "$HOME/.local/bin/tool"; }
    act="source $FN_ACT_TOOLS"
    grep -q "^$act" <"$HOME/.bashrc" || {
        local fn && fn="$(tmpfn brc)" # maybe no sed
        echo -e "$act\n\n" >"$fn"
        cat "$H/.bashrc" >>"$fn"
        mv "$fn" "$H/.bashrc"
    }
    local inst=false
    for t in $mgrs; do
        "$t.bootstrapped" && nfo "Have $t" || { inst=true && shtit "$t.bootstrap"; }
    done
    $inst || { good "Already present: $mgrs" && return 0; }
    source_shell_hooks
    for t in $mgrs; do "$t.bootstrapped" || die "Could not bootstrap $t"; done
    tool.status || true
}

function tool.ensure_runnable {
    test -z "${OS:-}" && die "Only linux or osx. sorry..." || true
}
function tool.help {
    echo -e "$d_"
    test "${1:-}" = false && return || exit 0
}
# ------------------------------------------------------------------------- TOOLS
function binenv.bootstrapped { have binenv; } # -> PATH seems set.
function binenv.status { binenv versions -f; }
function binenv.bootstrap {
    local fn
    fn="$(tmpfn binenv)"
    shw download "$BINENV_URL" "$fn" mkexe
    shw "$fn" update && shw "$fn" install binenv
    bootstrap_add_shell_hook "binenv" 'echo "$PATH" | grep -q binenv || PATH="$HOME/.binenv:$PATH"'
}
function binenv.activate { add_path "$H/.binenv" && have binenv; }

function asdf.get_ { export ASDF_REPO && shw git clone "$ASDF_REPO" "$H/.asdf" --branch v0.12.0; }
function asdf.bootstrapped { have asdf; }
function asdf.status { asdf plugin list; }
function asdf.bootstrap {
    test -e "$H/.asdf" || with_git_curl asdf.get_
    bootstrap_add_shell_hook "asdf" 'source "$HOME/.asdf/asdf.sh"'
}
function with_git_curl {
    # $1 a function
    have git && have curl && {
        "$1" || die "could not run installer"
        return 0
    }
    nfo "installer requires git, curl -> installing via micromamba (up to 1 min...)"
    source_shell_hooks
    micromamba activate base
    shw silent micromamba install -y git curl 1>/dev/null
    "$1" || die "could not run installer"
    shw type git
}
function asdf.activate { silent . "$H/.asdf/asdf.sh"; }

function micromamba.bootstrapped {
    have micromamba && test -e "$MM_D_BASE" && type micromamba | grep -q install
}
function micromamba.status { micromamba info | grep 'base environment'; }
function micromamba.bootstrap {
    export CONDA_FORGE_YES=yes
    export INIT_YES=no
    local fn
    fn="$(tmpfn mamba_installer)"
    download "https://micro.mamba.pm/install.sh" "$fn"
    echo '' | "${SHELL}" <(cat "$fn")
    fn="$H/.condarc"
    grep -q "^auto_activate_base:" <"$fn" || echo -e 'auto_activate_base: true\n' >>"$fn"
    local a="export MAMBA_EXE='$HOME/.local/bin/micromamba'"
    a="$a\nexport MAMBA_ROOT_PREFIX='$HOME/micromamba'"
    a=''$a'\neval "$($MAMBA_EXE shell hook -s bash -r $MAMBA_ROOT_PREFIX)"'
    mkdir -p "$H/micromamba"
    bootstrap_add_shell_hook micromamba "$a"
}
function nix.bootstrapped {
    bash -ic 'nix --version'
}
function nix.bootstrap {
    nix.bootstrapped && return 0
    local url fn && url="$NIX_URL" && fn="$(tmpfn instnix)"
    test "$(getenforce)" = "Enforcing" && {
        hash semanage || die "Require semanage on an selinux system"
        url="$NIX_URL_SELINUX"
    }
    download "$url" "$fn" mkexe
    "$fn" --daemon --yes # asks for sudo if not root
}
function nix.status { nix doctor; }

function brew.bootstrapped { have brew; }
function brew.status { brew list; }
function brewinst { /bin/bash -c "$(curl -fsSL "$BREW_URL")"; }
function brew.bootstrap {
    local d="/home/linuxbrew/.linuxbrew"
    silent touch "$d/tooltest" || {
        test -e "$d" && { have sudo && sudo chown -R $(whoami) "$d"; }
        test -e "$d" && { have sudo || chown -R $(whoami) "$d"; }
        test -e "$d" || with_git_curl brewinst
    }
    try rm -f "$d/tooltest"
    bootstrap_add_shell_hook "brew" 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
}

function usermode {
    local nb='' hu='' user=$1 && shift
    test "$(whoami)" = "$user" && return 0
    test "$(whoami)" = "root" || die "Require root to run usermode for user $user"
    hu="/home/$user"

    su - "$user" -c 'echo ""' || {
        $interactive && confirm "ok to create user $user"
        useradd -md "$hu" -s /bin/bash "$user" || echo "User exists already"
        mkdir -p "$hu/.ssh"
        test -e "$HOME/.ssh/authorized_keys" && {
            cp "$HOME/.ssh/authorized_keys" "$hu/.ssh/" # handy on server installs
            chown -R "$user:$user" "$hu/.ssh"
        }
        su - "$user" -c "mkdir -p $hu/.local/bin"
        chown -R "$user:$user" "$hu/.local"
    }

    test "$1" = bootstrap && {
        $with_nix && nix.bootstrap
        $with_nix && nb="-n"
        $with_brew && {
            nb="-b $nb"
            test -e "/home/linuxbrew/.linuxbrew" || {
                touch /.dockerenv # then brew will not complain about root
                download "$BREW_URL" /tmp/bi mkexe
                have git || {
                    echo "brew requires git - installing..."
                    have yum && silent yum install -y git
                    have apt-get && silent apt-get install -y git
                }
                have git || die "could not install git required for homebrew"
                NONINTERACTIVE=1 CI=1 /tmp/bi
            }
            chown -R "$user:$user" /home/linuxbrew/.linuxbrew
        }
    }
    hu="$hu/.local/bin/tool"
    cp "$0" "$hu"
    chown -R "$user:$user" "$hu"
    su - "$user" -c "eval $hu $* $nb"
    exit $?
}
function main {
    title "$0 $*"
    local cmd user=''
    cmd="${1:-help}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -NB) with_nix=true && with_brew=true ;;
            -N | --with-nix) with_nix=true ;;
            -B | --with-brew) with_brew=true ;;
            -u | --user) user="$2" && shift ;;
            -x | --debug) set -x ;;
            -h | --help) cmd=help && break ;;
            s | status) cmd=status && break ;;
            bs | bootstrap) cmd=bootstrap && break ;;
            *) echo "$1 not supported" && exit 1 ;;
        esac
        shift
    done
    shift
    test -z "$user" || usermode "$user" "$cmd" "$@"
    tool.ensure_runnable && source_shell_hooks
    "tool.$cmd" "$@"
}

main "$@"
