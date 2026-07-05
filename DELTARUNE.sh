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

if [[ -f "$DELTARUNEDIR/.esconder_input" ]]; then
		HIDE_INPUT_DEVICES=1
fi

if [[ $HIDE_INPUT_DEVICES -eq 1 ]]; then
		# o runner do GameMaker constantemente lê a pasta /dev/input para dispositivos de input, isso aqui usa o bubblewrap para esconder essa pasta do runner
		# Em alguns dispositivos, como o meu, isso arruma ele erroneamente detectando o meu Touchpad / outros dispositivos como controle, deixando o jogo injogável
		HIDE_INPUT_COMMAND="bwrap --bind / / --tmpfs /dev/input"
fi

"$DELTARUNEDIR/.watch" $$ $(sleep 5; pidof inotifywait) &

function run_game {
	# A gente precisa setar o 'locale' dos números do sistema pro sistema americano porque eles usam ponto pra decimais por algum motivo??? e o GameMaker espera esse formato.
	LC_NUMERIC=en_US.UTF-8 "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/run.sh" $HIDE_INPUT_COMMAND ./deltarune &
	# Depois de rodar o jogo pela primeira vez na seleção de capitulos, a gente quer esperar um poquinho pro próximo processo carregar antes de matar o primeiro
	if [ $FIRST_RUN == 0 ]; then
		sleep 4
	fi
	if [ "$DELTARUNEPID" != "" ]; then
		kill -9 $DELTARUNEPID;
	fi
	DELTARUNEPID=$(sleep 1; pidof deltarune)
	FIRST_RUN=0
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
