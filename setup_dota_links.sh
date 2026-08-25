#!/usr/bin/env bash

set -euo pipefail

ADDON_NAME="labyrinth_of_the_ancients"
PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTA_ROOT=${1:-}

if [[ -z $DOTA_ROOT ]]; then
    printf 'Usage: %s "/path/to/dota 2 beta"\n' "$(basename -- "$0")" >&2
    exit 2
fi

DOTA_ROOT=$(realpath -e -- "$DOTA_ROOT")

link_addon_root() {
    local kind=$1
    local target="$PROJECT_ROOT/$kind"
    local addon_parent="$DOTA_ROOT/$kind/dota_addons"
    local link="$addon_parent/$ADDON_NAME"

    if [[ ! -d $target ]]; then
        printf 'Error: project %s directory is missing: %s\n' "$kind" "$target" >&2
        exit 1
    fi

    mkdir -p -- "$addon_parent"

    if [[ -L $link ]]; then
        if [[ $(readlink -f -- "$link") == "$target" ]]; then
            printf '%s link already correct: %s\n' "$kind" "$link"
            return
        fi
        printf 'Error: %s is a symlink to a different target.\n' "$link" >&2
        exit 1
    fi

    if [[ -e $link ]]; then
        printf 'Error: refusing to replace existing path: %s\n' "$link" >&2
        exit 1
    fi

    ln -s -- "$target" "$link"
    printf 'Created %s link: %s -> %s\n' "$kind" "$link" "$target"
}

link_addon_root content
link_addon_root game
