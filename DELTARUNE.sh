#!/usr/bin/env bash

DELTARUNEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DELTARUNEPID=""
SAVEDIR="$HOME/.config/DELTARUNE"
FIRST_RUN=1
HIDE_INPUT_DEVICES=0
HIDE_INPUT_COMMAND=""

CHAPTERSELECT_FILE="deltaport_chapterselect"
CHAPTER1_FILE="deltaport_chapter1"
CHAPTER2_FILE="deltaport_chapter2"
CHAPTER3_FILE="deltaport_chapter3"
CHAPTER4_FILE="deltaport_chapter4"
CHAPTER5_FILE="deltaport_chapter5"

# Just in case
mkdir -p $SAVEDIR
cd "$SAVEDIR"

if [ ! -f "$DELTARUNEDIR/assets/game.unx" ]; then
    echo "DELTARUNE game data not found. Make sure this is run on the folder with the games files, and the patching worked correctly"
    exit 1
fi

# If we are in Ubuntu/Debian, export the specific compatibility libraries folder
# This will get appended to the $LD_LIBRARY_PATH variable exported by steam-runtime's script.
if [ -f "$DELTARUNEDIR/.ubuntu" ]; then
	export LD_LIBRARY_PATH="$DELTARUNEDIR/lib"
fi

# Check if trigger files are somehow there and delete them
if [ -f "$CHAPTERSELECT_FILE" ]; then
	rm $CHAPTERSELECT_FILE
fi

if [ -f "$CHAPTER1_FILE" ]; then
	rm $CHAPTER1_FILE
fi

if [ -f "$CHAPTER2_FILE" ]; then
	rm $CHAPTER2_FILE
fi

if [ -f "$CHAPTER3_FILE" ]; then
	rm $CHAPTER3_FILE
fi

if [ -f "$CHAPTER4_FILE" ]; then
	rm $CHAPTER4_FILE
fi

if [ -f "$CHAPTER5_FILE" ]; then
	rm $CHAPTER5_FILE
fi

if [ -f "$END_FILE" ]; then
	rm $END_FILE
fi

if [[ -f "$DELTARUNEDIR/.hide_input" ]]; then
		HIDE_INPUT_DEVICES=1
fi

if [[ $HIDE_INPUT_DEVICES -eq 1 ]]; then
		# The GMS runner constantly reads the /dev/input for gamepad devices every frame, this uses bubblewrap to hide that directory from the runner
		# On some devices, like mine, this fixes it erroneously detecting my touchpad / other devices that aren't joysticks as a gamepad, making the game unplayable
		HIDE_INPUT_COMMAND="bwrap --bind / / --tmpfs /dev/input"
fi

"$DELTARUNEDIR/.watch" $$ $(sleep 5; pidof inotifywait) &

function run_game {
	# We need to set the numeric locale to en_US because it uses a dot for decimals and GMS requires it.
	LC_NUMERIC=en_US.UTF-8 "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/run.sh" $HIDE_INPUT_COMMAND ./deltarune &
	# After the first run during the chapter switch, we want to wait a bit so the next process loads before killing the first one.
	if [ $FIRST_RUN == 0 ]; then
		sleep 4
	fi
	if [ "$DELTARUNEPID" != "" ]; then
		kill -9 $DELTARUNEPID;
	fi
	DELTARUNEPID=$(sleep 1; pidof deltarune)
	FIRST_RUN=0
}

# Run the game!
cd "$DELTARUNEDIR"
run_game

# =- All the logic for changing chapters / parsing trigger files -=
parse_file() {
	cd "$SAVEDIR"
    if [ "$1" == "$CHAPTERSELECT_FILE" ]; then
		rm $1
		change_chapter 0
	elif [ "$1" == "$CHAPTER1_FILE" ]; then
		rm $1
		change_chapter 1
	elif [ "$1" == "$CHAPTER2_FILE" ]; then
		rm $1
		change_chapter 2
    	elif [ "$1" == "$CHAPTER3_FILE" ]; then
		rm $1
		change_chapter 3
	elif [ "$1" == "$CHAPTER4_FILE" ]; then
		rm $1
		change_chapter 4
	elif [ "$1" == "$CHAPTER5_FILE" ]; then
		rm $1
		change_chapter 5
	else
		return
	fi
}

change_chapter() {
	if [ "$1" == "0" ]; then
		cd "$DELTARUNEDIR"
		run_game
	elif [ "$1" == "1" ]; then
		cd "$DELTARUNEDIR/chapter1_linux"
		run_game
	elif [ "$1" == "2" ]; then
		cd "$DELTARUNEDIR/chapter2_linux"
		run_game
	elif [ "$1" == "3" ]; then
		cd "$DELTARUNEDIR/chapter3_linux"
		run_game
	elif [ "$1" == "4" ]; then
		cd "$DELTARUNEDIR/chapter4_linux"
		run_game
	elif [ "$1" == "5" ]; then
		cd "$DELTARUNEDIR/chapter5_linux"
		run_game
	fi
}

# Watch the game save directory for trigger files
inotifywait -m $SAVEDIR  |
	while read filepath operation file; do
		[[ $operation == *CREATE* ]] && parse_file $file $filepath
	done
