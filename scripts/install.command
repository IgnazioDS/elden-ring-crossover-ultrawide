#!/bin/sh

set -eu

SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=common.sh
. "$SCRIPT_DIRECTORY/common.sh"

usage()
{
    printf 'Usage: %s [--bottle "/full/path/to/Elden Ring bottle"]\n' "$0"
}

BOTTLE_PATH=''
while [ "$#" -gt 0 ]
do
    case "$1" in
        --bottle)
            [ "$#" -ge 2 ] || fail '--bottle requires a path.'
            BOTTLE_PATH=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            fail "Unknown argument: $1"
            ;;
    esac
done

ROOT=$(project_root)
BOTTLE_PATH=$(resolve_bottle)
BOTTLE_NAME=$(basename "$BOTTLE_PATH")
WINE=$(find_crossover_wine)
TOOLS="$BOTTLE_PATH/drive_c/EldenRingTools"
WINDOWS_START_MENU="$BOTTLE_PATH/drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Steam/ELDEN RING.url"
WINDOWS_DESKTOP="$BOTTLE_PATH/drive_c/users/crossover/Desktop/ELDEN RING.url"
CXMENU="$BOTTLE_PATH/desktopdata/cxmenu"

case "$BOTTLE_NAME$WINE" in
    *\"*|*\`*) fail 'Bottle and CrossOver paths may not contain quotes or backticks.' ;;
esac

require_supported_game "$BOTTLE_PATH"
ensure_game_closed "$BOTTLE_PATH"

launcher_hash=$(shasum -a 256 "$ROOT/dist/EldenRingUltrawideLauncher.exe" | awk '{print $1}')
expected_launcher_hash='1506f0c7d661915bf859b1694364d56c825775d7c229f8b6b982f38cc3527543'
[ "$launcher_hash" = "$expected_launcher_hash" ] || fail 'Bundled launcher checksum mismatch; obtain a clean repository copy.'

timestamp=$(date '+%Y%m%d-%H%M%S')
backup="$TOOLS/backups/$timestamp"
mkdir -p "$backup/cxmenu" "$TOOLS" "$(dirname "$WINDOWS_START_MENU")" "$(dirname "$WINDOWS_DESKTOP")"

if [ -f "$WINDOWS_START_MENU" ]; then
    cp -p "$WINDOWS_START_MENU" "$backup/windows-start-menu.url"
else
    : > "$backup/windows-start-menu.was-missing"
fi
if [ -f "$WINDOWS_DESKTOP" ]; then
    cp -p "$WINDOWS_DESKTOP" "$backup/windows-desktop.url"
else
    : > "$backup/windows-desktop.was-missing"
fi

if [ -d "$CXMENU" ]; then
    find "$CXMENU" -maxdepth 1 -type f -name '*ELDEN+RING.url' -exec cp -p '{}' "$backup/cxmenu/" ';'
fi

cp "$ROOT/dist/EldenRingUltrawideLauncher.exe" "$TOOLS/EldenRingUltrawideLauncher.exe"
cp "$ROOT/resources/install.reg" "$TOOLS/install.reg"
cp "$ROOT/resources/ELDEN RING.url" "$WINDOWS_START_MENU"
cp "$ROOT/resources/ELDEN RING.url" "$WINDOWS_DESKTOP"

wrapper="$TOOLS/launch-elden-ring-ultrawide.command"
{
    printf '%s\n' '#!/bin/sh' 'set -eu' ''
    printf 'exec "%s" --bottle "%s" --check --wait-children --start "%s"\n' \
        "$WINE" "$BOTTLE_NAME" 'C:/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Steam/ELDEN RING.url'
} > "$wrapper"
chmod 755 "$wrapper"

if [ -d "$CXMENU" ]; then
    find "$CXMENU" -maxdepth 1 -type f -name '*ELDEN+RING.url' -exec cp "$wrapper" '{}' ';'
    find "$CXMENU" -maxdepth 1 -type f -name '*ELDEN+RING.url' -exec chmod 755 '{}' ';'
fi

"$WINE" --bottle "$BOTTLE_NAME" regedit /S 'C:\EldenRingTools\install.reg'
printf '%s\n' "$backup" > "$TOOLS/latest-backup.txt"

printf '\nInstalled successfully.\n'
printf 'Bottle: %s\n' "$BOTTLE_PATH"
printf 'Backup: %s\n' "$backup"
printf 'Launch from the normal CrossOver Elden Ring icon. This fix is offline-only because EAC is bypassed.\n'
