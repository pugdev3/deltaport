#!/usr/bin/env bash
set -e pipefail
set -E

DELTARUNEDIR=""
SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION=""
CHAPTERS=4

VERSION_104_CHECKSUM="9d1fea9de81219ea7304f32f1ae7a878"
VERSION_105_CHECKSUM="5d3e158dbe6888fbf24471019fbde3c9"
VERSION_106_CHECKSUM="f3dabe6444829688fd7fbaa68f78794f"

log() { echo -e "\e[1;34m::\e[0m \e[1m$1\e[0m"; }
warn() { echo -e "\n\e[38;5;172m::\e[0m \e[1m\e[38;5;208m$1\e[0m"; }
error() { echo -e "\n\e[38;5;203m::\e[0m \e[1m\e[38;5;196m$1\e[0m" && exit 1; }

trap 'warn "WARNING: Script cancelled by user, port may be incomplete." && exit 1' SIGINT
trap 'error "An error ocurred while running this script :("' ERR

# Check for dependencies
if [ ! -d "$HOME/.local/share/Steam" ]; then
    error "ERROR: You need to have Steam installed in order to run this script."
fi
"$SCRIPTDIR/deps.sh"

function port_game() {
   echo ""

   log "Detecting game version..."

   if echo "${VERSION_104_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        VERSION="1.04"
        CHAPTERS=4
   fi

   if echo "${VERSION_105_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        VERSION="1.05"
        CHAPTERS=4
   fi

    if echo "${VERSION_106_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        VERSION="1.06"
        CHAPTERS=5
   fi

   if [[ "$VERSION" == "" ]]; then
        warn "WARNING: data.win checksum does not match with any version. Please check supported versions or you may have corrupt game files. A reminder this is for version 1.04/1.05/1.06"
        while true; do
            read -p "Continue anyway? [y/n]: " yn
            case $yn in
                [Yy]* ) log "Using version 1.05" && VERSION="1.05"; break;;
                [Nn]* ) exit 1; break;;
                * ) exit 1; break;;
		    esac
        done
    else
        log "Detected version $VERSION"
    fi

   log "Using directory: $DELTARUNEDIR"
   cd "$DELTARUNEDIR"

   log "Renaming files..."

   for chapter in *; do
        linux_name=$(echo "$chapter" | sed s/windows/linux/)
        if [[ "$chapter" != "$linux_name" ]]; then
                mv "$chapter" "$linux_name";
        fi
   done

   find "mus/" -exec bash -c 'if [[ "$0" != "${0,,}" ]]; then mv --update=none "$0" "${0,,}"; fi' {} \;
   find "chapter3_linux/vid/" -exec bash -c 'if [[ "$0" != "${0,,}" ]]; then mv --update=none "$0" "${0,,}"; fi' {} \;
   echo ""

   log "Moving files..."
   rm "DELTARUNE.exe"
   ln -s DELTARUNE.sh DELTARUNE.exe
   mv data.win game.unx
    
   cp "$SCRIPTDIR/deltarune" .
   cp "$SCRIPTDIR/DELTARUNE.sh" .
   cp "$SCRIPTDIR/files/options.ini" .
   cp "$SCRIPTDIR/icon.png" .
   cp "$SCRIPTDIR/.watch" .
    if [ -f "$SCRIPTDIR/.ubuntu" ]; then
        cp "$SCRIPTDIR/.ubuntu" .
        cp -r "$SCRIPTDIR/lib" .
   fi

   find . -type d -name "chapter*_linux" -print0 | while IFS= read -r -d $'\0' chapter_dir; do
        chapter_number=$(echo "$chapter_dir" | sed 's/[^0-9]//g')
        mv "$chapter_dir/AUDIO_INTRONOISE.ogg" "$chapter_dir/audio_intronoise.ogg"
        mv "$chapter_dir/data.win" "$chapter_dir/game.unx"
        
        mkdir -p "$chapter_dir/assets"
        find "$chapter_dir" -maxdepth 1 -not -name "assets" -exec mv --update=none {} "$chapter_dir/assets" \;

        cp "$SCRIPTDIR/files/options_${chapter_number}.ini" "$chapter_dir/assets/options.ini"
        cp "$SCRIPTDIR/icon.png" "$chapter_dir/assets"
        cp "$SCRIPTDIR/deltarune" "$chapter_dir"
        ln -sf "../../assets/mus" "$chapter_dir/assets/mus"
   done

   mkdir -p "assets"
   mv options.ini game.unx mus icon.png -t "assets/"

   log "Symlinking videos..."
   cd "chapter3_linux/assets/vid"
   ln -s "tennaintrof1_compressed_28.mp4" "tennaIntroF1_compressed_28.mp4"
   ln -s "tennaintrojpf1_compressed_28.mp4" "tennaIntroJPf1_compressed_28.mp4"

   cd "$SCRIPTDIR"

   log "Patching game data..."
    hpatchz -f "$DELTARUNEDIR/assets/game.unx" "$SCRIPTDIR/files/patches/v$VERSION/00-chapterselect.hpatch" "$DELTARUNEDIR/assets/game.unx"
    for ((i = 1 ; i <= CHAPTERS ; i++)); do
         hpatchz -f "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx" $SCRIPTDIR/files/patches/v$VERSION/0${i}-*.hpatch "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx"
    done

   echo -e "\e[1;32m SUCCESS! The port script finished. \e[0m"
   log 'To play DELTARUNE, go to Steam -> DELTARUNE -> Properties -> Launch Options -> Put this: "./DELTARUNE.sh" -- %command%'
   log "Or, you can run ./DELTARUNE.sh in the game folder. (If you have issues with Steam, run the game this way)"
   log "Thanks for using this project and have fun!"
}

function select_dir() {
   echo ""
   log "Please type the path of DELTARUNE below (eg. /home/pug/.local/share/Steam/steamapps/common/DELTARUNE):"
   read path

   if [ "$path" = "" ]; then
      select_dir
   fi

   if [ ! -d "$path" ]; then
        warn "Directory doesn't exist, please try again"
        select_dir
   fi

   if [ ! -f "$path/data.win" ]; then
        warn "Unable to find game data (data.win) at directory, please try again."
        select_dir
   fi

   DELTARUNEDIR=${path%/}
   port_game
}

log "Welcome to the unofficial DELTARUNE Linux port."
log "This is the port for v1.04/1.05/1.06"
log "You will need to bring your own game files, as none of them are included here."
echo ""

if [ -d "$HOME/.local/share/Steam/steamapps/common/DELTARUNE" ]; then
	DELTARUNEDIR="$HOME/.local/share/Steam/steamapps/common/DELTARUNE"
	log "Detected deltarune directory at $DELTARUNEDIR."
	while true; do
		read -p "Is this correct? [y/n]: " yn
		case $yn in
			[Yy]* ) port_game; break;;
			[Nn]* ) select_dir; break;;
			* ) select_dir; break;;
		    esac
		done
else
	select_dir
fi
