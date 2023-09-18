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
NAME="tool"
FNTOOL="~/.local/bin/$NAME"                    # keep tilde
ALL_TOOLMGRS="binenv asdf micromamba nix brew" # brew nix"
ALW_TOOLMGRS="binenv micromamba asdf"          # in inst order. asdf req git and curl (from micromamba)
H="$HOME"
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

# internal
remote_host=

# ------------------------------------------------------------------------- UTILS
function title { echo -e "\x1b[1;${2:-32}m$1\x1b[0m"; }
function nfo { echo -e "(ℹ️) $*"; }
function good { echo -e "🟩 $*"; }
function err { echo -e "🟥 $*" >&2; }
function die { set +x && err "$*" && exit 1; }
function shw { echo -e "⚙️ $*" && "$@"; }
function shtit { title "$@" 33 && "$@"; }

function silent { "$@" 2>/dev/null 1>/dev/null; }
function try { silent "$@" || true; }
function have { silent type "$1"; }
function add_path { echo "$PATH" | grep -q "$1:" || export PATH="$1:$PATH"; }
function mkexe { chmod +x "$1"; }
function tmpfn { local d="/tmp/$USER.tool" && mkdir -p "$d" && echo "$d/$1"; }
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

function get_root {
    silent ls /root/ && return
    # interactive? then pw is not set:
    [[ $- == *i* ]] && { sudo echo '' || die "sry..."; }
    [[ $- == *i* ]] && return 0
    # need sudo password?
    sudo -n true && return 0 # no pw req
    die "Require pw less sudo for non-interactive remote installation"
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

function remote_create_user {
    local user="$1" host="$2"
    function addu {
        local pw && pw="${pw:-}"
        pw="${TOOL_REMOTE_PW:-$pw}"
        echo -e '
        user="'$user'"; pw="'$pw'"
        set -e
        useradd -md "/home/$user" -s /bin/bash "$user" || echo "User exists already"
        mkdir -p "/home/$user/.ssh"
        cp .ssh/authorized_keys "/home/$user/.ssh/"
        chown -R "$user:$user" "/home/$user/.ssh"
        su - "$user" -c "mkdir -p .local/bin"
        test -z "$pw" && exit
        echo "Setting password"
        echo -e "$pw\n$pw\n" | passwd "$user"
        '
    }
    addu "$user" | ssh "root@$host" || die "Have no root access to $host"
    shw scp -q "$0" "$user@$host:$FNTOOL"
}
sudo_no_pw_ensured=false
function remote_ensure_sudo {
    local pw user="$1" host="$2"
    silent ssh "$user@$host" ls /root/ && {
        nfo "user has root perms, no sudo required"
        return 0
    }
    function ensure_sudo {
        echo -e '
        user="'$user'"
        function have { hash "${1:-sudo}" 2>/dev/null; }
        have || { have yum && yum install -y sudo; }
        have || { have apt-get && apt-get install -y sudo; }
        have || { echo "could not install sudo"; exit 1; }
        cp /etc/sudoers /etc/sudoers.tool.bckup
        l="$user    ALL=(ALL)  NOPASSWD: ALL"
        echo -e "$l\n" >> /etc/sudoers
        echo -e "🟥 \""$l"\" added to /etc/sudoers!!" 
        '
    }
    ensure_sudo "$user" | ssh "root@$host" || die "Have no root access to $host"
    sudo_no_pw_ensured=true
}
function remote_reset_sudo {
    local host="$1"
    echo -e 'mv /etc/sudoers.tool.bckup /etc/sudoers' | ssh "root@$host" || die "could not reset sudo"
}
function tool.remote {
    test -z "${1:-}" && {
        ssh "$remote_host"
        return $?
    }
    local ret remote_create=false remote_ensure_sudo=false remote_update_tool=false
    while getopts cSu opt; do
        case "$opt" in
            c) remote_create=true ;;
            S) remote_ensure_sudo=true ;;
            u) remote_update_tool=true ;;
            ?) break ;;
        esac
    done
    shift $((OPTIND - 1))

    local user host t && t="$remote_host"
    test -z "$t" && die "Require ssh host"
    function ssharg { /usr/bin/ssh -G "$1" | grep "^$2 " | head -n1 | cut -d ' ' -f 2- | xargs; }
    host="$(ssharg "$t" hostname)"
    user="$(ssharg "$t" user)"
    $remote_create && { silent ssh -oBatchMode=yes "$user@$host" echo || shw remote_create_user "$user" "$host"; }
    $remote_update_tool && shw scp -q "$0" "$user@$host:$FNTOOL"
    "$remote_ensure_sudo" && shw remote_ensure_sudo "$user" "$host"
    ssh "$user@$host" "$FNTOOL" "$@"
    ret=$?
    $sudo_no_pw_ensured && shw remote_reset_sudo "$host"
    return $ret
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
    nfo "installer requires git, curl -> installing via micromamba..."
    source_shell_hooks
    micromamba activate base
    shw micromamba install -y git curl
    "$1" || die "could not run installer"
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
    local url fn && url="$NIX_URL" && fn="$(tmpfn instnix)"
    test "$(getenforce)" = "Enforcing" && {
        hash semanage || die "Require semanage on an selinux system"
        url="$NIX_URL_SELINUX"
    }
    download "$url" "$fn" mkexe
    shw get_root || die 'Require sudo root to install nix'
    "$fn" --daemon
}
function nix.status { nix doctor; }

function brew.bootstrapped { have brew; }
function brew.status { brew list; }
function brew.bootstrap {
    shw get_root || die 'Require sudo root to install linuxbrew'
    function brewinst {
        export NONINTERACTIVE=1
        /bin/bash -c "$(curl -fsSL "$BREW_URL")"
    }
    local d="/home/linuxbrew/.linuxbrew"
    test -e "$d" && { have sudo && sudo chown -R $(whoami) "$d"; }
    test -e "$d" && { have sudo || chown -R $(whoami) "$d"; }
    test -e "$d" || with_git_curl brewinst
    bootstrap_add_shell_hook "brew" 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
}
function if_not_bootstrapped_do_it {
    test -e "$FNTOOL" && return
    "$0" bootstrap
    exit $?
}
function main {
    title "$0 called with params $*"
    local cmd
    cmd="${1:-help}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -x | --debug) set -x ;;
            -h | --help) cmd=help ;;
            bs | bootstrap) cmd=bootstrap ;;
            s | status) cmd=status ;;
            *@*)
                cmd=remote && remote_host="$1"
                shift
                break
                ;;
            *) break ;;
        esac
        shift
    done

    test "$cmd" = remote || { tool.ensure_runnable && source_shell_hooks; }
    "tool.$cmd" "$@"
}

[ -z "${PS1:-}" ] && if_not_bootstrapped_do_it

main "$@"
