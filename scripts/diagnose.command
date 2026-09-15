#!/bin/sh

set -eu

SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=common.sh
. "$SCRIPT_DIRECTORY/common.sh"

BOTTLE_PATH=''
if [ "${1:-}" = '--bottle' ]; then
    [ "$#" -eq 2 ] || fail 'Usage: diagnose.command [--bottle "/full/path/to/bottle"]'
    BOTTLE_PATH=$2
elif [ "$#" -ne 0 ]; then
    fail 'Usage: diagnose.command [--bottle "/full/path/to/bottle"]'
fi

BOTTLE_PATH=$(resolve_bottle)
TOOLS="$BOTTLE_PATH/drive_c/EldenRingTools"
GAME="$BOTTLE_PATH/$GAME_RELATIVE"
WINDOWS_START_MENU="$BOTTLE_PATH/drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Steam/ELDEN RING.url"

printf 'Bottle: %s\n' "$BOTTLE_PATH"
printf 'CrossOver Wine: %s\n' "$(find_crossover_wine)"
printf 'eldenring.exe SHA-256: '
shasum -a 256 "$GAME/eldenring.exe" | awk '{print $1}'

for item in "$TOOLS/EldenRingUltrawideLauncher.exe" "$WINDOWS_START_MENU"
do
    if [ -f "$item" ]; then
        printf 'OK: %s\n' "$item"
    else
        printf 'MISSING: %s\n' "$item"
    fi
done

if [ -f "$GAME/eldenring_ultrawide_tmp.exe" ]; then
    printf 'RUNNING/STALE: temporary executable exists.\n'
else
    printf 'CLEAN: no temporary executable is present.\n'
fi

if [ -f "$TOOLS/elden-ring-ultrawide.log" ]; then
    printf '\nRecent launcher log:\n'
    tail -20 "$TOOLS/elden-ring-ultrawide.log"
fi
