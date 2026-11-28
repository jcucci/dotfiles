# .NET SDK management via Microsoft's dotnet-install.sh.
# Portable across Linux and macOS (zsh only, no GNU-specific tools).
#
#   dnsdk install <channel|version> [quality]   11.0 | 10.0.1xx | LTS | STS | 10.0.113   (quality: preview, daily, ...)
#   dnsdk runtime <channel> [aspnetcore|dotnet] install a runtime only (default: aspnetcore)
#   dnsdk update                                update every installed SDK band and runtime-only channel, then prune
#   dnsdk prune [-y]                            remove superseded patch versions
#   dnsdk list                                  list installed SDKs and runtimes
#   dnsdk check                                 run 'dotnet sdk check' (outdated / end-of-life report)
#   dnsdk script                                re-download dotnet-install.sh
#
# Overridable: DNSDK_DIR, DNSDK_SCRIPT, DNSDK_SCRIPT_MAX_AGE_DAYS

: ${DNSDK_DIR:=$HOME/.dotnet}
: ${DNSDK_SCRIPT:=${XDG_DATA_HOME:-$HOME/.local/share}/dotnet-install/dotnet-install.sh}
: ${DNSDK_SCRIPT_MAX_AGE_DAYS:=7}

_dnsdk_err() {
    print -u2 -r -- "dnsdk: $*"
}

_dnsdk_usage() {
    print -r -- "Usage: dnsdk <install|runtime|update|prune|list|check|script> [args]"
    print -r -- "  dnsdk install 11.0            latest 11.0 SDK"
    print -r -- "  dnsdk install 11.0 preview    latest 11.0 preview SDK"
    print -r -- "  dnsdk install 10.0.1xx        latest SDK in the 10.0.1xx feature band"
    print -r -- "  dnsdk install 10.0.113        exact SDK version"
    print -r -- "  dnsdk runtime 8.0             ASP.NET Core + .NET runtime 8.0 only"
    print -r -- "  dnsdk update                  update all installed SDKs/runtimes, then prune"
    print -r -- "  dnsdk prune [-y]              delete superseded patch versions"
}

# --- dotnet-install.sh cache -------------------------------------------------

_dnsdk_script_refresh() {
    local tmp="$DNSDK_SCRIPT.$$.tmp"
    mkdir -p -- "${DNSDK_SCRIPT:h}" || return 1

    if ! curl -fsSL --retry 2 -o "$tmp" https://dot.net/v1/dotnet-install.sh; then
        rm -f -- "$tmp"
        _dnsdk_err "failed to download dotnet-install.sh"
        return 1
    fi

    if [[ "$(head -c 2 "$tmp")" != '#!' ]]; then
        rm -f -- "$tmp"
        _dnsdk_err "downloaded dotnet-install.sh does not look like a script"
        return 1
    fi

    chmod +x -- "$tmp" && mv -f -- "$tmp" "$DNSDK_SCRIPT"
}

# Use the cached script if younger than DNSDK_SCRIPT_MAX_AGE_DAYS, otherwise refresh.
# Falls back to a stale copy when offline.
_dnsdk_script_ensure() {
    local -a fresh=( $DNSDK_SCRIPT(N.md-$DNSDK_SCRIPT_MAX_AGE_DAYS) )
    (( $#fresh )) && return 0

    print -r -- "Refreshing dotnet-install.sh..."
    _dnsdk_script_refresh && return 0

    [[ -f $DNSDK_SCRIPT ]] || return 1
    _dnsdk_err "using cached copy of dotnet-install.sh"
}

_dnsdk_run() {
    print -r -- "==> dotnet-install.sh $*"
    bash "$DNSDK_SCRIPT" --install-dir "$DNSDK_DIR" --no-path "$@"
}

# --- version helpers ----------------------------------------------------------

# Print versions oldest -> newest. Prereleases sort before their GA release.
_dnsdk_sort() {
    (( $# )) || return 0
    local v
    local -a keyed
    for v in "$@"; do
        if [[ $v == *-* ]]; then
            keyed+=( "$v" )
        else
            keyed+=( "$v-zzzz" )
        fi
    done
    keyed=( ${(on)keyed} )
    print -rl -- ${keyed%-zzzz}
}

# Version subdirectories of $DNSDK_DIR/$1, sorted oldest -> newest.
_dnsdk_versions() {
    local -a dirs=( $DNSDK_DIR/$1/[0-9]*(N/:t) )
    _dnsdk_sort $dirs
}

_dnsdk_major() {
    print -r -- "${1%%.*}"
}

# 10.0.113 -> 10.0
_dnsdk_minor() {
    local -a p=( ${(s:.:)${1%%-*}} )
    print -r -- "$p[1].$p[2]"
}

# 10.0.113 -> 10.0.1xx, 11.0.100-rc.2.x -> 11.0.1xx
_dnsdk_band() {
    local -a p=( ${(s:.:)${1%%-*}} )
    print -r -- "$p[1].$p[2].${p[3][1]}xx"
}

# Highest major version among installed SDKs and runtimes (0 if none).
_dnsdk_newest_major() {
    local v
    local max=0
    for v in $DNSDK_DIR/{sdk,shared/Microsoft.NETCore.App}/[0-9]*(N/:t); do
        (( ${v%%.*} > max )) && max=${v%%.*}
    done
    print -r -- $max
}

# Installing an older major after a newer one would overwrite the 'dotnet' host
# with an older build; dotnet-install.sh can skip those non-versioned files.
_dnsdk_host_flag() {
    local major=$(_dnsdk_major "$1")
    [[ $major == <-> ]] || return 0
    (( major < $(_dnsdk_newest_major) )) && print -r -- --skip-non-versioned-files
}

_dnsdk_after_install() {
    rehash
    if [[ $DOTNET_ROOT != $DNSDK_DIR ]]; then
        print -r -- "Note: DOTNET_ROOT is '$DOTNET_ROOT'. Open a new shell (or run zsource) to use $DNSDK_DIR."
    fi
}

# --- commands -------------------------------------------------------------------

_dnsdk_install() {
    local target=$1 quality=$2
    if [[ -z $target ]]; then
        _dnsdk_usage
        return 1
    fi
    _dnsdk_script_ensure || return 1

    local -a args
    if [[ $target == <->.<->.<->(|-*) ]]; then
        args=( --version $target )
    else
        args=( --channel $target )
        [[ -n $quality ]] && args+=( --quality $quality )
    fi
    args+=( $(_dnsdk_host_flag $target) )

    _dnsdk_run $args && _dnsdk_after_install
}

_dnsdk_runtime() {
    local channel=$1 kind=${2:-aspnetcore}
    if [[ -z $channel || $kind != (aspnetcore|dotnet) ]]; then
        _dnsdk_usage
        return 1
    fi
    _dnsdk_script_ensure || return 1

    _dnsdk_run --runtime $kind --channel $channel $(_dnsdk_host_flag $channel) && _dnsdk_after_install
}

_dnsdk_prune() {
    local assume_yes=0
    [[ $1 == -y ]] && assume_yes=1

    local v fw
    local -a doomed sdks
    local -A newest

    # SDKs: keep the newest version in each feature band.
    sdks=( ${(f)"$(_dnsdk_versions sdk)"} )
    for v in $sdks; do newest[$(_dnsdk_band $v)]=$v; done
    for v in $sdks; do
        [[ $newest[$(_dnsdk_band $v)] == $v ]] || doomed+=( sdk/$v )
    done

    # Runtimes: keep the newest patch per major.minor, and remove the packs,
    # templates and hostfxr that shipped with each removed runtime.
    local newest_fxr=${${(f)"$(_dnsdk_versions host/fxr)"}[-1]}
    for fw in Microsoft.NETCore.App Microsoft.AspNetCore.App; do
        local -a rts=( ${(f)"$(_dnsdk_versions shared/$fw)"} )
        newest=()
        for v in $rts; do newest[$(_dnsdk_minor $v)]=$v; done
        for v in $rts; do
            [[ $newest[$(_dnsdk_minor $v)] == $v ]] && continue
            doomed+=( shared/$fw/$v )
            if [[ $fw == Microsoft.NETCore.App ]]; then
                doomed+=( $DNSDK_DIR/{packs/Microsoft.NETCore.App.Ref,packs/Microsoft.NETCore.App.Host.*,templates}/$v(N/) )
                [[ $v != $newest_fxr && -d $DNSDK_DIR/host/fxr/$v ]] && doomed+=( host/fxr/$v )
            else
                doomed+=( $DNSDK_DIR/packs/Microsoft.AspNetCore.App.Ref/$v(N/) )
            fi
        done
    done

    # Normalize to paths relative to DNSDK_DIR.
    doomed=( ${doomed#$DNSDK_DIR/} )

    if (( ! $#doomed )); then
        print -r -- "Nothing to prune in $DNSDK_DIR."
        return 0
    fi

    print -r -- "Superseded versions in $DNSDK_DIR:"
    print -rl -- "  "${^doomed}
    if (( ! assume_yes )); then
        if ! read -q "?Delete these? [y/N] "; then
            print
            return 0
        fi
        print
    fi

    local p
    for p in $doomed; do
        [[ -n $p && -d $DNSDK_DIR/$p ]] && rm -rf -- "$DNSDK_DIR/$p"
    done
    print -r -- "Pruned ${#doomed} directories."
}

_dnsdk_update() {
    if [[ ! -x $DNSDK_DIR/dotnet ]]; then
        _dnsdk_err "no .NET install in $DNSDK_DIR; start with 'dnsdk install <channel>'"
        return 1
    fi
    _dnsdk_script_ensure || return 1

    local v band minor failed=0
    local -a sdks bands sdk_minors
    local -A newest

    sdks=( ${(f)"$(_dnsdk_versions sdk)"} )
    for v in $sdks; do
        band=$(_dnsdk_band $v)
        newest[$band]=$v
        bands+=( $band )
        sdk_minors+=( $(_dnsdk_minor $v) )
    done

    # Oldest band first, so the newest one installs last and leaves the newest 'dotnet' host in place.
    for band in ${(u)bands}; do
        v=$newest[$band]
        if [[ $v == *-* ]]; then
            # Prerelease: move to GA if the band has shipped, otherwise latest preview.
            if ! _dnsdk_run --channel $band $(_dnsdk_host_flag $v); then
                print -r -- "No GA release for $band yet; updating to the latest preview."
                _dnsdk_run --channel $(_dnsdk_minor $v) --quality preview $(_dnsdk_host_flag $v) || failed=1
            fi
        else
            _dnsdk_run --channel $band $(_dnsdk_host_flag $v) || failed=1
        fi
    done

    # Runtime-only installs (a runtime minor with no SDK of the same minor).
    local -a rt_minors
    for v in ${(f)"$(_dnsdk_versions shared/Microsoft.NETCore.App)"}; do
        rt_minors+=( $(_dnsdk_minor $v) )
    done
    for minor in ${(u)rt_minors}; do
        (( ${sdk_minors[(Ie)$minor]} )) && continue
        local kind=dotnet
        local -a asp=( $DNSDK_DIR/shared/Microsoft.AspNetCore.App/$minor.*(N/) )
        (( $#asp )) && kind=aspnetcore
        _dnsdk_run --runtime $kind --channel $minor --skip-non-versioned-files || failed=1
    done

    rehash
    print
    _dnsdk_prune

    (( failed )) && _dnsdk_err "one or more updates failed (see output above)"
    return $failed
}

dnsdk() {
    local cmd=$1
    (( $# )) && shift

    case $cmd in
        install) _dnsdk_install "$@" ;;
        runtime) _dnsdk_runtime "$@" ;;
        update)  _dnsdk_update "$@" ;;
        prune)   _dnsdk_prune "$@" ;;
        list)    "$DNSDK_DIR/dotnet" --list-sdks && "$DNSDK_DIR/dotnet" --list-runtimes ;;
        check)   "$DNSDK_DIR/dotnet" sdk check ;;
        script)  _dnsdk_script_refresh && print -r -- "dotnet-install.sh updated: $DNSDK_SCRIPT" ;;
        *)       _dnsdk_usage; [[ -z $cmd || $cmd == (-h|--help|help) ]] ;;
    esac
}

_dnsdk_complete() {
    local -a cmds=(
        'install:install an SDK channel or exact version'
        'runtime:install a runtime only'
        'update:update all installed SDKs and runtimes, then prune'
        'prune:remove superseded patch versions'
        'list:list installed SDKs and runtimes'
        'check:report outdated or end-of-life versions'
        'script:re-download dotnet-install.sh'
    )
    if (( CURRENT == 2 )); then
        _describe 'dnsdk command' cmds
    elif [[ $words[2] == install && CURRENT == 3 ]]; then
        _values 'channel' LTS STS 11.0 10.0 9.0 8.0
    elif [[ $words[2] == install && CURRENT == 4 ]]; then
        _values 'quality' preview daily signed validated GA
    elif [[ $words[2] == runtime && CURRENT == 4 ]]; then
        _values 'runtime' aspnetcore dotnet
    fi
}

(( $+functions[compdef] )) && compdef _dnsdk_complete dnsdk
