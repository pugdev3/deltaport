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
    echo "game.unx do DELTARUNE não encontrado, os patches funcionaram corretamente?"
    exit 1
fi

# Se a gente está no Ubuntu/Debian, exportar a pasta de bibliotecas de compatibilidade
# Isso vai ser adicionado a váriavel $LD_LIBRARY_PATH exportada pelo script do runtime da Steam.
if [ -f "$DELTARUNEDIR/.ubuntu" ]; then
	export LD_LIBRARY_PATH="$DELTARUNEDIR/lib"
fi

# Checar se arquivos de gatilho estão aqui por algum motivo (???) e deletar eles
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

if [ -f "$DELTARUNEDIR/.saida_lock" ]; then
	rm "$DELTARUNEDIR/.saida_lock"
fi

if [[ -f "$DELTARUNEDIR/.esconder_input" ]]; then
		HIDE_INPUT_DEVICES=1
fi

if [[ $HIDE_INPUT_DEVICES -eq 1 ]]; then
		# o runner do GameMaker constantemente lê a pasta /dev/input para dispositivos de input, isso aqui usa o bubblewrap para esconder essa pasta do runner
		# Em alguns dispositivos, como o meu, isso arruma ele erroneamente detectando o meu Touchpad / outros dispositivos como controle, deixando o jogo injogável
		HIDE_INPUT_COMMAND="bwrap --bind / / --tmpfs /dev/input"
fi

function exit_game {
		# Prevenir que rode duas vezes
		if [[ -f ".saida_lock" ]]; then exit 0; fi
		touch .saida_lock
		echo "Obrigado por jogar, espero que você tenha se divertido :D"
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
	# Setar o locale do sistema pro locale genérico 'C' porque eles usam ponto pra decimais e o GameMaker espera esse formato.
	LC_ALL=C "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/run.sh" $HIDE_INPUT_COMMAND ./deltarune &
	# Depois de rodar o jogo pela primeira vez na seleção de capitulos, a gente quer esperar um poquinho pro próximo processo carregar antes de matar o primeiro
	if [ $FIRST_RUN == 0 ]; then
		sleep 4
	fi
	if [ "$DELTARUNEPID" != "" ]; then
		kill -9 $DELTARUNEPID;
	fi
	DELTARUNEPID=$(sleep 1; pidof deltarune)
	FIRST_RUN=0
	if [[ $GAME_WATCH -eq 0 ]]; then
		watch_game &
	fi
	GAME_WATCH=1
}

# Rodar esse jogaço!!!
cd "$DELTARUNEDIR"
run_game

# =- Toda a lógica para mudar de capitulos / Processar arquivos de gatilho -=
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

# Monitorar pasta de save para arquivos de gatilho
inotifywait -m $SAVEDIR  |
	while read filepath operation file; do
		[[ $operation == *CREATE* ]] && parse_file $file $filepath
	done
