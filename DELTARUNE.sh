#!/usr/bin/env bash

ARG=$1
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
TRIGGER_FILES=("$CHAPTERSELECT_FILE" "$CHAPTER1_FILE" "$CHAPTER2_FILE" "$CHAPTER3_FILE" "$CHAPTER4_FILE" "$CHAPTER5_FILE")
for f in "${TRIGGER_FILES[@]}"; do
	[ -n "$f" ] && [ -f "$f" ] && rm "$f"
done

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
	LC_ALL=C "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/run.sh" $HIDE_INPUT_COMMAND gamemoderun ./deltarune &
	# Depois de rodar o jogo pela primeira vez na seleção de capitulos, a gente quer esperar um poquinho pro próximo processo carregar antes de matar o primeiro
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

# =- Toda a lógica para mudar de capitulos / Processar arquivos de gatilho -=
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

# Rodar esse jogaço!!!
cd "$DELTARUNEDIR"
if [[ "$ARG" != "" ]]; then
	change_chapter $1
else
	run_game
fi

# Monitorar pasta de save para arquivos de gatilho
inotifywait -m $SAVEDIR  |
	while read filepath operation file; do
		[[ $operation == *CREATE* ]] && parse_file $file $filepath
	done
