#!/usr/bin/env bash
DELTARUNEDIR="$1"
set -e pipefail
set -E

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CHAPTERS=4
UPDATED_VERSION=""

VERSION_104_CHECKSUM="9d1fea9de81219ea7304f32f1ae7a878"
VERSION_105_CHECKSUM="5d3e158dbe6888fbf24471019fbde3c9"
VERSION_106_CHECKSUM="f3dabe6444829688fd7fbaa68f78794f"
VERSION_107_CHECKSUM="0a448a89c32c802a138621a39ced69db"

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
        error "ERROR: DELTARUNE directory not found somehow? Something went wrong :/"
fi

if [[ ! -f "$DELTARUNEDIR/data.win" ]]; then
        error "ERROR: DELTARUNE game data not found. Something went wrong :/"
fi

log "Detecting updated game version..."

if echo "${VERSION_104_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
    UPDATED_VERSION="1.04"
    CHAPTERS=4
fi

if echo "${VERSION_104_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
    UPDATED_VERSION="1.05"
    CHAPTERS=5
fi

if echo "${VERSION_106_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
    UPDATED_VERSION="1.06"
    CHAPTERS=5
fi

if echo "${VERSION_107_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
    UPDATED_VERSION="1.07"
    CHAPTERS=5
fi

if [[ "$UPDATED_VERSION" == "" ]]; then
        error  "ERROR: Unable to detect updated game version :p"
else
        log "Detected updated version: $UPDATED_VERSION"
fi

if [[ "$UPDATED_VERSION" == "1.05" ]]; then
    mkdir -p temp2
    cd temp2
    wget "https://github.com/pugdev3/deltaport/releases/download/v0.01/deltaport-v0.01.tar.xz" -O deltaport.tar.xz
    tar -Jxvf deltaport.tar.xz files/patches
    mkdir -p "$SCRIPTDIR/files/patches/v1.05"
    cp files/patches/* "$SCRIPTDIR/files/patches/v1.05/"
    cd ..
    rm -r temp2
fi

if [[ ! -d "$DELTARUNEDIR/chapter5_linux" ]]; then
    CHAPTERS=4
fi

if [[ ! -d "$DELTARUNEDIR/chapter5_linux" && $UPDATED_VERSION  != "1.04" && $UPDATED_VERSION != "1.05" ]]; then
    warn "WARNING: Chapter 5 not found. You cannot update from a version below 1.06! (Versions with new chapters require a reinstall) You will most likely encounter issues."
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

