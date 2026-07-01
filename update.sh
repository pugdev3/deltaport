#!/usr/bin/env bash
DELTARUNEDIR="$1"
set -e pipefail
set -E

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CHAPTERS=5
UPDATED_VERSION=""

VERSION_240_CHECKSUM="f3dabe6444829688fd7fbaa68f78794f"
VERSION_241_CHECKSUM="0a448a89c32c802a138621a39ced69db"
VERSION_242_CHECKSUM="cc76c5efeb1b5fefd1822ceb1340ca10"
VERSION_243_CHECKSUM="359adb2db26d7e902f4c26b40e9b58ae"
VERSION_244_CHECKSUM="ddedbbd10ff129b49c64dbefaa763c6a"

log() { echo -e "\e[1;34m::\e[0m \e[1m$1\e[0m"; }
warn() { echo -e "\n\e[38;5;172m::\e[0m \e[1m\e[38;5;208m$1\e[0m"; }
error() { echo -e "\n\e[38;5;203m::\e[0m \e[1m\e[38;5;196m$1\e[0m" && exit 1; }

cleanup() {
    cd "$DELTARUNEDIR"

    rm -r mus
    rm options.ini
    rm DELTARUNE.exe
    ln -s DELTARUNE.sh DELTARUNE.exe

    rm -r temp
}

trap 'warn "WARNING: Script cancelled by user, port may be incomplete." && exit 1' SIGINT
trap 'error "An error ocurred while running this script :("' ERR

if [[ "$DELTARUNEDIR" == "" ]]; then
        error "ERROR: DELTARUNE directory not found somehow? (Don't run the script directly, use port.sh) Something went wrong :/"
fi

if [[ ! -f "$DELTARUNEDIR/data.win" ]]; then
        error "ERROR: DELTARUNE game data not found. Something went wrong :/"
fi

log "Updating your deltaport version"
log "This only updates the game data, not external files (unlikely for those to change anyway)"

function check_version {
   if echo "${VERSION_240_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        UPDATED_VERSION="0.0.240"
   fi

    if echo "${VERSION_241_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        UPDATED_VERSION="0.0.241"
   fi

    if echo "${VERSION_242_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        UPDATED_VERSION="0.0.242"
   fi

    if echo "${VERSION_243_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        UPDATED_VERSION="0.0.243"
   fi

    if echo "${VERSION_244_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        UPDATED_VERSION="0.0.244"
   fi
}

log "Detecting updated game version..."

check_version

if [[ "$UPDATED_VERSION" == "" ]]; then
        error  "ERROR: Unsupported game version or unable to detect. As of now, versions that include new chapters require you to reinstall the game."
else
        log "Detected updated version: $UPDATED_VERSION"
fi

if [[ ! -d "$DELTARUNEDIR/chapter5_linux" ]]; then
    warn "WARNING: Chapter 5 not found. You cannot update from a version below v0.0.240 (Chapter 5 release version)! (Versions with new chapters require a reinstall) You will most likely encounter issues."
    while true; do
        read -p "Continue anyway? [y/n]: " yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit 1; break;;
			* ) exit 1; break;;
		    esac
    done
fi

log "Using directory: $DELTARUNEDIR"
cd $DELTARUNEDIR

mkdir -p temp

log "Moving files..."

cp "$SCRIPTDIR/DELTARUNE.sh" .
if [[ ! -f ".watch" ]]; then
    cp "$SCRIPTDIR/.watch" .
fi
if [[ -f "$SCRIPTDIR/.ubuntu" && ! -f ".ubuntu" ]]; then
    cp "$SCRIPTDIR/.ubuntu" .
fi
if [[ ! -d "lib" && -f ".ubuntu" ]]; then
    cp "$SCRIPTDIR/lib" .
fi

mv data.win temp/data.win.0
find . -type d -name "chapter*_windows" -print0 | while IFS= read -r -d $'\0' chapter_dir; do
    chapter_number=$(echo "$chapter_dir" | sed 's/[^0-9]//g')
    mv "$chapter_dir/data.win" "temp/data.win.$chapter_number"

    rm -r "$chapter_dir"
done

log "Patching game files..."

cd "$SCRIPTDIR"

hpatchz -f "$DELTARUNEDIR/temp/data.win.0" "files/patches/v$UPDATED_VERSION/00-chapterselect.hpatch" "$DELTARUNEDIR/assets/game.unx"
for ((i = 1 ; i <= CHAPTERS ; i++)); do
    hpatchz -f "$DELTARUNEDIR/temp/data.win.$i" files/patches/v$UPDATED_VERSION/0${i}-*.hpatch "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx"
done

log "Removing leftover files..."

cleanup

echo -e "\e[1;32m SUCCESS! Game data sucessfully updated.\e[0m"
log "Updated to version $UPDATED_VERSION"
log "Thanks for using deltaport, have fun!"
exit 0

