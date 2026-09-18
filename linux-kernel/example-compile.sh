#!/usr/bin/bash
# set -x
set -euo pipefail

SDK=$(cd -- "$(dirname -- "$0")" && cd ../.. && pwd)
readonly SDK

function check_modpost() {
    local logfile="${1:?path}"
    local allowed_prefixes=(
        "cambr_"
        "cnosal_"
        "cn_"
        "dm_"
    )
    if [[ ! -r "$logfile" ]]; then
        echo "check_modpost: cannot read log file: ${logfile}" >&2
        return 1
    fi

    local -a symbols=()
    mapfile -t symbols < <(
        grep -E 'WARNING: modpost: "[^"]+"' "${logfile}" \
            | sed -nE 's/.*WARNING: modpost: "([^"]+)".*/\1/p' \
            | sort -u
    )

    if [[ "${#symbols[@]}" -eq 0 ]]; then
        echo "check_modpost: no undefined-symbol warnings found."
        return 0
    fi

    function _is_allowed_prefix() {
        local name="${1:?name}"
        local p
        for p in "${allowed_prefixes[@]}"; do
            [[ "$name" == "$p"* ]] && return 0
        done
        return 1
    }

    local -a violations=()
    for s in "${symbols[@]}"; do
        if ! _is_allowed_prefix "$s"; then
            violations+=("$s")
        fi
    done
    unset -f _is_allowed_prefix

    if [[ "${#violations[@]}" -gt 0 ]]; then
        echo "check_modpost: ERROR: disallowed undefined symbol(s):" >&2
        for s in "${violations[@]}"; do
            echo "  - $s" >&2
        done
        return 1
    fi

    return 0
}


function rebuild() {
    local SERIAL_B="115"
    local log
    log="$(mktemp -t modpost.XXXXXX.log)"
    pushd "${SDK}/product_build"
        echo "${SERIAL_B}" | ./compile.sh 2>&1 | tee "${log}"
        check_modpost "${log}"
    popd
    rm "${log}"
}

function main() {
    readonly CMDS=("$@")
    for i in "${!CMDS[@]}"; do
        case "${CMDS[$i]}" in
        "rebuild") rebuild ;;
        *)
            echo "${SDK}"
            echo "Undefined command: '${CMDS[$i]}'"
            exit 1
            ;;
        esac
    done
    return 0
}
main "$@"