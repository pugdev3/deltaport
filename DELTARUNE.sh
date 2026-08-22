#!/usr/bin/env bash

DELTARUNEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DELTARUNEPID=""
SAVEDIR="$HOME/.config/DELTARUNE"
FIRST_RUN=1
HIDE_INPUT_DEVICES=0
HIDE_INPUT_COMMAND=""
GAME_WATCH=0

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
TRIGGER_FILES=("$CHAPTERSELECT_FILE" "$CHAPTER1_FILE" "$CHAPTER2_FILE" "$CHAPTER3_FILE" "$CHAPTER4_FILE" "$CHAPTER5_FILE" "$END_FILE")
for f in "${TRIGGER_FILES[@]}"; do
	[ -n "$f" ] && [ -f "$f" ] && rm "$f"
done

if [ -f "$DELTARUNEDIR/.exit_lock" ]; then
	rm "$DELTARUNEDIR/.exit_lock"
fi

if [[ -f "$DELTARUNEDIR/.hide_input" ]]; then
		HIDE_INPUT_DEVICES=1
fi

if [[ $HIDE_INPUT_DEVICES -eq 1 ]]; then
		# The GMS runner constantly reads the /dev/input for gamepad devices every frame, this uses bubblewrap to hide that directory from the runner
		# On some devices, like mine, this fixes it erroneously detecting my touchpad / other devices that aren't joysticks as a gamepad, making the game unplayable
		HIDE_INPUT_COMMAND="bwrap --bind / / --tmpfs /dev/input"
fi

function exit_game {
		# To prevent it running twice
		if [[ -f ".exit_lock" ]]; then exit 0; fi
		touch .exit_lock
		echo "Thanks for playing, hope you had fun :D"
		if kill -0 $(pidof inotifywait) 2>/dev/null; then
			kill -9 $(pidof inotifywait)
		fi
		if kill -0 $(pidof deltarune) 2>/dev/null; then
			kill -9 $(pidof deltarune)
		fi
		exit 0
}

trap 'exit_game' SIGINT

function watch_game {
	while true; do
		sleep 4
		if [[ "$(pidof deltarune)" == "" ]]; then
				exit_game
		fi
	done
}

function run_game {
	# We need to set the locale to C (standard locale) because it uses a dot for decimals and GMS requires it.
	LC_ALL=C "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/run.sh" $HIDE_INPUT_COMMAND ./deltarune &
	# After the first run during the chapter switch, we want to wait a bit before killing the first one.
	if [ $FIRST_RUN == 0 ]; then
		sleep 4
	fi
	if [ "$DELTARUNEPID" != "" ]; then
		kill -9 $DELTARUNEPID;
	fi
	until DELTARUNEPID=$(pidof deltarune)
	do
		sleep 1
	done
	FIRST_RUN=0
	if [[ $GAME_WATCH -eq 0 ]]; then
		watch_game &
	fi
	GAME_WATCH=1
}

# Run the game!
cd "$DELTARUNEDIR"
run_game

# =- All the logic for changing chapters / parsing trigger files -=
parse_file() {
	cd "$SAVEDIR"
	local chapter=""
	case "$1" in
		"$CHAPTERSELECT_FILE") chapter=0 ;;
		"$CHAPTER1_FILE")      chapter=1 ;;
		"$CHAPTER2_FILE")      chapter=2 ;;
		"$CHAPTER3_FILE")      chapter=3 ;;
		"$CHAPTER4_FILE")      chapter=4 ;;
		"$CHAPTER5_FILE")      chapter=5 ;;
		*) return ;;
	esac
	rm "$1"
	change_chapter "$chapter"
}

change_chapter() {
	local target="$DELTARUNEDIR"
	case "$1" in
		0) target="$DELTARUNEDIR" ;;
		1) target="$DELTARUNEDIR/chapter1_linux" ;;
		2) target="$DELTARUNEDIR/chapter2_linux" ;;
		3) target="$DELTARUNEDIR/chapter3_linux" ;;
		4) target="$DELTARUNEDIR/chapter4_linux" ;;
		5) target="$DELTARUNEDIR/chapter5_linux" ;;
		*) return ;;
	esac
	cd "$target"
	run_game
}

# Watch the game save directory for trigger files
inotifywait -m $SAVEDIR  |
	while read filepath operation file; do
		[[ $operation == *CREATE* ]] && parse_file $file $filepath
	done
