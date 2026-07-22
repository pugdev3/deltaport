#!/usr/bin/env bash
ARGS=$1
set -e pipefail
set -E

DELTARUNEDIR=""
SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION=""
LATEST_VERSION="0.0.250"
CHAPTERS=5
STEAMCLOUD=0
NXRUNE_MOD=0

VERSION_247_CHECKSUM="908643b7593b000f5b6c61bb484d086a"
VERSION_250_CHECKSUM="1f00145d681f830f1249d9493ba8f579"

log() { echo -e "\e[1;34m::\e[0m \e[1m$1\e[0m"; }
warn() { echo -e "\n\e[38;5;172m::\e[0m \e[1m\e[38;5;208m$1\e[0m"; }
error() { echo -e "\n\e[38;5;203m::\e[0m \e[1m\e[38;5;196m$1\e[0m" && exit 1; }

trap 'warn "AVISO: O script foi cancelado pelo usuário, o port pode estar incompleto." && exit 1' SIGINT
trap 'error "Um erro ocorreu durante a execução do script :("' ERR

# Fazer o check das dependências
if [ ! -d "$HOME/.local/share/Steam" ]; then
    error "ERRO: Você precisa da Steam instalada no seu sistema pra rodar esse script."
fi
"$SCRIPTDIR/deps.sh"

function steam_cloud_support {
     if [[ "$STEAMCLOUD" == 1 ]]; then
            log "Adicionando suporte ao Steam Cloud..."
            # Necessário para ligação simbólica funcionar
            mkdir -p "$HOME/.config/DELTARUNE"

            # NOTA: Pelo o que eu vi, a Steam Cloud parece criar esse diretório automaticamente ao sincronizar saves, mas só pra ter certeza
            mkdir -p "$HOME/.local/share/Steam/steamapps/compatdata/1671210/pfx/drive_c/users/steamuser/Local Settings/Application Data"

            # NOTA 2: Outro diretório onde a Steam parece ler saves
            mkdir -p "$HOME/.local/share/Steam/steamapps/compatdata/1671210/pfx/drive_c/users/steamuser/AppData/Local/"

            cd "$HOME/.local/share/Steam/steamapps/compatdata/1671210/pfx/drive_c/users/steamuser/Local Settings/Application Data"
            if [[ -d "DELTARUNE" ]]; then
                rm -r "DELTARUNE"
            fi
            ln -s "$HOME/.config/DELTARUNE" "DELTARUNE"

            cd "$HOME/.local/share/Steam/steamapps/compatdata/1671210/pfx/drive_c/users/steamuser/AppData/Local"
            if [[ -d "DELTARUNE" ]]; then
                rm -r "DELTARUNE"
            fi
            ln -s "$HOME/.config/DELTARUNE" "DELTARUNE"

            log "Suporte a Steam Cloud adicionado! Por favor não apague a pasta '~/.config/DELTARUNE' antes de rodar o jogo porque isso pode quebrar coisas"
     fi
}

function nxrune_mod_support {
    if [[ $ARGS == "nxrune" && $NXRUNE_MOD -eq 0 ]]; then
        NXRUNE_MOD=1
        find_deltarune_dir
    fi
    if [[ $NXRUNE_MOD -eq 1 ]]; then
            log "Aplicando as patches do mod 'nxrune'"
            hpatchz -f "$DELTARUNEDIR/assets/game.unx" "$SCRIPTDIR/files/patches/nxrune/00-telainicial-bordas.hpatch" "$DELTARUNEDIR/assets/game.unx"
            for ((i = 1 ; i <= CHAPTERS - 1 ; i++)); do
                hpatchz -f "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx" $SCRIPTDIR/files/patches/nxrune/0${i}-*.hpatch "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx"
            done
            hpatchz -f "$DELTARUNEDIR/chapter5_linux/assets/game.unx" "$SCRIPTDIR/files/patches/nxrune/05-capitulo_05-bordas.hpatch" "$DELTARUNEDIR/chapter5_linux/assets/game.unx"
            # Atualizar o hash MD5 (valor númerico que o jogo usa pra checar se está atualizado) pra versão com bordas
            hpatchz -f "$DELTARUNEDIR/assets/game.unx" "$SCRIPTDIR/files/patches/nxrune/06-atualizar_md5.hpatch" "$DELTARUNEDIR/assets/game.unx"
            log "Patches do mod aplicados com sucesso :D"
    fi
}

if [[ $ARGS == "steamcloud" ]]; then STEAMCLOUD=1; steam_cloud_support && exit 0; fi

function check_version {
   if echo "${VERSION_247_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        VERSION="0.0.247"
   fi

   if echo "${VERSION_250_CHECKSUM}" $DELTARUNEDIR/data.win | md5sum -c; then
        VERSION="0.0.250"
   fi
}

function port_game() {
   if [[ $ARGS == "nxrune" ]]; then nxrune_mod_support && exit 0; fi
   echo ""

   while true; do
        read -p "$(log 'Começar a portar o jogo? [S/n]: ')" sn
        case $sn in
            [Ss]* ) break;;
            [Nn]* ) exit 1; break;;
            * ) exit 1; break;;
            esac
        done

    if [[ -f "$DELTARUNEDIR/DELTARUNE.sh" ]]; then
        warn "AVISO: Parece que o jogo já foi portado pra Linux (Arquivo DELTARUNE.sh encontrado). Tentar portar denovo pode causar problemas."
        while true; do
            read -p "Continuar mesmo assim? [S/n]: " sn
            case $sn in
                [Ss]* ) break;;
                [Nn]* ) exit 1; break;;
                * ) exit 1; break;;
            esac
        done
    fi

   log "Detectando versão do jogo..."

   check_version

   if [[ "$VERSION" == "" ]]; then
        warn "AVISO: Não foi possivel identificar a versão. Tenta verificar a integridade dos arquivos na Steam. Lembrando que você precisa da versão $LATEST_VERSION"
        while true; do
            read -p "Continuar mesmo assim? [S/n]: " sn
            case $sn in
                [Ss]* ) log "Usando a última versão disponível" && VERSION="$LATEST_VERSION"; break;;
                [Nn]* ) exit 1; break;;
                * ) exit 1; break;;
		    esac
        done
    else
        log "Foi detectado a versão: $VERSION"
    fi

   log "Usando o diretório: $DELTARUNEDIR"
   cd "$DELTARUNEDIR"

   log "Renomeando arquivos..."

   for chapter in *; do
        linux_name=$(echo "$chapter" | sed s/windows/linux/)
        if [[ "$chapter" != "$linux_name" ]]; then
                mv "$chapter" "$linux_name";
        fi
   done

   find "mus/" -exec bash -c 'if [[ "$0" != "${0,,}" ]]; then mv --update=none "$0" "${0,,}"; fi' {} \;
   find "chapter3_linux/vid/" -exec bash -c 'if [[ "$0" != "${0,,}" ]]; then mv --update=none "$0" "${0,,}"; fi' {} \;
   echo ""

   log "Movendo arquivos..."
   rm "DELTARUNE.exe"
   ln -s DELTARUNE.sh DELTARUNE.exe
   mv data.win game.unx

   cp "$SCRIPTDIR/deltarune" .
   cp "$SCRIPTDIR/DELTARUNE.sh" .
   cp "$SCRIPTDIR/files/options.ini" .
   cp "$SCRIPTDIR/icon.png" .
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
        if [[ -f "$SCRIPTDIR/files/lang/lang_en_$chapter_number.json" ]]; then
                mkdir -p "$chapter_dir/assets/lang"
                cp "$SCRIPTDIR/files/lang/lang_en_$chapter_number.json" "$chapter_dir/assets/lang/lang_en.json"
        fi
        ln -sf "../../assets/mus" "$chapter_dir/assets/mus"
   done

   mkdir -p "assets"
   mv options.ini game.unx mus icon.png -t "assets/"

   log "Substituindo alguns arquivos de música pelas versões traduzidas..."
   cp $SCRIPTDIR/files/mus/* "assets/mus/"

   log "Substituindo o vídeo do Capítulo 3 pela versão traduzida..."

   cd "chapter3_linux/assets/vid"
   cp "$SCRIPTDIR/files/vid/tennaIntroF1_compressed_28.mp4" "tennaintrof1_compressed_28.mp4"

   log "Criando ligações símbolicas para o vídeo do Capítulo 3..."

   ln -s "tennaintrof1_compressed_28.mp4" "tennaIntroF1_compressed_28.mp4"
   ln -s "tennaintrojpf1_compressed_28.mp4" "tennaIntroJPf1_compressed_28.mp4"

   if [[ "$CHAPTERS" -ge 5 ]]; then
        log "Arrumando um bug nos vídeos do Capítulo 5..."

        cd "$SCRIPTDIR"
        cd "$DELTARUNEDIR"

        cd "chapter5_linux/assets/vid"
        cp ch5_intro_en.mp4 ch5_intro_en.mp4.temp
        cp ch5_intro_jp.mp4 ch5_intro_jp.mp4.temp

        # No Capítulo 5, o áudio é separado do vídeo
        # Isso causa um erro no Linux, já que os vídeos não tem uma stream de áudio. Erro: 'video_open: Cannot find audio stream'
        # Aqui, a gente cria uma stream de áudio nula (sem som), permitindo que o áudio carregue corretamente.
        ffmpeg -y -i ch5_intro_en.mp4.temp -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -c:v copy -shortest ch5_intro_en.mp4
        ffmpeg -y -i ch5_intro_jp.mp4.temp -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -c:v copy -shortest ch5_intro_jp.mp4

        rm ch5_intro_en.mp4.temp
        rm ch5_intro_jp.mp4.temp
   fi
   cd "$SCRIPTDIR"

   log "Aplicando o patch (modificação) dos arquivos do jogo..."

   hpatchz -f "$DELTARUNEDIR/assets/game.unx" "$SCRIPTDIR/files/patches/v$VERSION/pt_br/00-telainicial-pt_br.hpatch" "$DELTARUNEDIR/assets/game.unx"
   hpatchz -f "$DELTARUNEDIR/assets/game.unx" "$SCRIPTDIR/files/patches/v$VERSION/deltaport/00-telainicial.hpatch" "$DELTARUNEDIR/assets/game.unx"
   for ((i = 1 ; i <= CHAPTERS - 1 ; i++)); do
         hpatchz -f "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx" $SCRIPTDIR/files/patches/v$VERSION/pt_br/0${i}-*.hpatch "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx"
         hpatchz -f "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx" $SCRIPTDIR/files/patches/v$VERSION/deltaport/0${i}-*.hpatch "$DELTARUNEDIR/chapter${i}_linux/assets/game.unx"
   done

   # deltaport suporta os 5 capítulos, pt-br apenas 4
   hpatchz -f "$DELTARUNEDIR/chapter5_linux/assets/game.unx" "$SCRIPTDIR/files/patches/v$VERSION/deltaport/05-capitulo_05.hpatch" "$DELTARUNEDIR/chapter5_linux/assets/game.unx"

   # Atualizar o hash MD5 (valor númerico que o jogo usa pra checar se está atualizado) pras versões de Linux
   hpatchz -f "$DELTARUNEDIR/assets/game.unx" "$SCRIPTDIR/files/patches/v$VERSION/pt_br/05-atualizar_md5.hpatch" "$DELTARUNEDIR/assets/game.unx"

    if [[ "$VERSION" == $LATEST_VERSION ]]; then
        while true; do
            read -p "$(log 'Adicionar opcionalmente o mod de bordas de Console? (NXRUNE) [S/n]: ')" sn
            case $sn in
                [Ss]* ) NXRUNE_MOD=1; break;;
                [Nn]* ) log "Se você mudar de ideia, só rodar './port.sh nxrune' para adicionar o mod!"; break;;
                *) break;;
            esac
        done
   fi

    while true; do
        read -p "$(log 'Adicionar suporte opcional aos saves na Steam Cloud? [S/n]: ')" sn
        case $sn in
            [Ss]* ) STEAMCLOUD=1; break;;
            [Nn]* ) break;;
            *) break;;
            esac
   done

   nxrune_mod_support
   steam_cloud_support

   echo -e "\e[1;32m SUCESSO! O script do port terminou. \e[0m"
   log "Antes de mais nada, mova o diretório para a localização correta (instruções no Github)"
   log 'E agora, para jogar DELTARUNE, vá para Steam -> DELTARUNE -> Propriedades -> Opções de inicialização  -> Coloque isso: "./DELTARUNE.sh" -- %command%'
   log "Ou você pode rodar ./DELTARUNE.sh dentro da pasta do jogo (Se você tiver problemas com a Steam, rode o jogo desta forma)"
   log "Atualmente essa versão não tem suporte para atualizações"
   log "Muito obrigado por usar esse projeto e se divirta!"
   exit 0
}

function select_dir() {
   echo ""
   log "Então por favor digite o caminho para sua instalação do DELTARUNE abaixo (ex: /home/pug/.local/share/Steam/steamapps/common/DELTARUNE):"
   read path

   if [ "$path" = "" ]; then
      select_dir
   fi

   if [ ! -d "$path" ]; then
        warn "O diretório inserido não existe, por favor tente novamente."
        select_dir
   fi

   if [ ! -f "$path/data.win" ] && [ ! -f "$path/assets/game.unx" ]; then
        warn "Não foi possivel encontrar os dados do jogo (data.win) no diretório escolhido, tente novamente..."
        select_dir
   fi

   DELTARUNEDIR=${path%/}
   port_game
}

find_deltarune_dir() {
        if [ -d "$HOME/.local/share/Steam/steamapps/common/DELTARUNE" ]; then
        DELTARUNEDIR="$HOME/.local/share/Steam/steamapps/common/DELTARUNE"
        log "Foi detectado uma instalação do DELTARUNE em: $DELTARUNEDIR."
        while true; do
            read -p "Isso está correto? [S/n]: " sn
            case $sn in
                [Ss]* ) port_game; break;;
                [Nn]* ) select_dir; break;;
                * ) select_dir; break;;
                esac
            done
    else
        select_dir
    fi
}

if [[ $ARGS == "nxrune" ]]; then nxrune_mod_support; fi

log "Bem-vindo ao port não oficial do DELTARUNE para Linux :D (versão PT-BR)"
log "Para portar o jogo, você vai precisar da versão $LATEST_VERSION em específico, dê uma olhada no Github para saber como conseguir essa versão."
log "Além disso, você vai precisar ter uma cópia do jogo pra isso funcionar, já que nada é incluído aqui por design."
echo ""

find_deltarune_dir
