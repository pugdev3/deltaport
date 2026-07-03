#!/usr/bin/env bash
set -euo pipefail

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FFMPEG4_INSTALLED=0
HDIFFPATCH_INSTALLED=0
deps=("hpatchz" "inotifywait" "ffmpeg" "wget")
# Interno / para mostrar na tela
missing_deps=()
missing_deps_list=()

cd "$SCRIPTDIR"

log() { echo -e "\e[1;34m::\e[0m \e[1m$1\e[0m"; }
warn() { echo -e "\e[38;5;172m::\e[0m \e[1m\e[38;5;208m$1\e[0m"; }
error() { echo -e "\e[38;5;203m::\e[0m \e[1m\e[38;5;196m$1\e[0m" && exit 1; }

if [ -d "$SCRIPTDIR/lib" ] || [ -f "/usr/lib64/libavcodec.so.58" ] || [ -f "/usr/lib/x86_64-linux-gnu/libavcodec.so.58" ]; then
    FFMPEG4_INSTALLED=1
fi

if command -v hpatchz 2>&1 >/dev/null;
then
    HDIFFPATCH_INSTALLED=1
fi

install_patcher() {
    if [ "$HDIFFPATCH_INSTALLED" == 1 ]; then
            warn "hdiffpatch já instalado, saindo..."
            return;
    fi
    log "Instalando hdiffpatch..."
    mkdir -p linux64
    wget https://github.com/sisong/HDiffPatch/releases/download/v5.0.1/hdiffpatch_v5.0.1_bin_linux64.zip -O hdiffpatch.zip
    unzip hdiffpatch.zip -d .

    sudo install -Dm 0755 'linux64/hdiffz' "/usr/bin/hdiffz"
    sudo install -Dm 0755 'linux64/hpatchz' "/usr/bin/hpatchz"

    rm hdiffpatch.zip
    rm -r linux64
}

install_ffmpeg4() {
    if [ "$FFMPEG4_INSTALLED" == 1 ]; then
            warn "ffmpeg4 já instalado, saindo..."
            return;
    fi
    touch .ubuntu
    # Baixar bibliotecas do ffmpeg4 no Ubuntu para compatiblidade de vídeo
    log "Baixando bibliotecas do ffmpeg4..."
    wget https://github.com/pugdev3/files/raw/refs/heads/main/ffmpeg4.tar.gz -O ffmpeg4.tar.gz
    tar -xvf ffmpeg4.tar.gz
    rm ffmpeg4.tar.gz
}

function install_deps() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        error "Não foi possível detectar a sua distribuição, arquivo /etc/os-release não encontrado."
    fi

    install_ubuntu() {
        log "Instalando as dependências..."
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y ${missing_deps[*]}
        install_patcher
        install_ffmpeg4
        log "Dependências instaladas com sucesso :)"
        sleep 1
        clear
    }

    install_fedora() {
        log "Instalando as dependências..."
        sudo dnf update
        if ! rpm -q --quiet rpmfusion-free-release; then
            log 'Instalando o repositório de terceiro "rpmfusion" para instalar os pacotes necessários...'
            sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        fi
        sleep 5
        sudo dnf install --allowerasing -y ${missing_deps[*]} compat-ffmpeg4
        install_patcher
        log "Dependências instaladas com sucesso :)"
        sleep 1
        clear
    }

    install_arch() {
        log "Instalando as dependências..."
        if command -v paru 2>&1 >/dev/null
        then
            paru -Sy --noconfirm ${missing_deps[*]} ffmpeg4.4 hdiffpatch-bin
        elif command -v yay 2>&1 >/dev/null
        then
            yay -Sy --noconfirm ${missing_deps[*]} ffmpeg4.4 hdiffpatch-bin
        else
            sudo pacman -Sy --noconfirm ${missing_deps[*]} ffmpeg4.4
            git clone https://aur.archlinux.org/hdiffpatch-bin.git
            cd hdiffpatch-bin
            makepkg -si
            cd .. && rm -r hdiffpatch-bin
        fi
        log "Dependências instaladas com sucesso :)"
        sleep 1
        clear
    }

    case "${DISTRO_ID}" in
        ubuntu|debian)
            log "Ubuntu/Debian detectado."
            install_ubuntu
            ;;
        fedora)
            log "Fedora detectado."
            install_fedora
            ;;
        arch)
            log "Usando Arch btw."
            install_arch
            ;;
        *)
            if [[ "${DISTRO_LIKE}" == *"debian"* || "${DISTRO_LIKE}" == *"ubuntu"* ]]; then
                log "Sua distro parece ser baseada no Debian."
                install_ubuntu
            elif [[ "${DISTRO_LIKE}" == *"fedora"* || "${DISTRO_LIKE}" == *"rhel"* ]]; then
                log "Sua distro parece ser baseada no Fedora."
                install_fedora
            elif [[ "${DISTRO_LIKE}" == *"arch"* ]]; then
                log "Você parece estar usando Arch btw."
                install_arch
            else
                error "Não foi possível detectar sua distribuição. Você provavelmente não está usando a tríplice (Arch, Debian, Fedora), pro seu caso do nichoOS, você está sozinho, boa sorte :D"
            fi
            ;;
    esac
}

function check_deps() {
    for d in "${deps[@]}"
    do
        if ! command -v $d 2>&1 >/dev/null
        then
            if [ "$d" == "inotifywait" ]; then
                missing_deps+=("inotify-tools")
                missing_deps_list+=("$d")
                continue;
            elif [ "$d" == "hpatchz" ]; then
                missing_deps_list+=("hdiffpatch")
                continue;
            fi
            missing_deps+=("$d")
            missing_deps_list+=("$d")
        fi
    done

    if command -v apt 2>&1 >/dev/null; then
        if [[ $FFMPEG4_INSTALLED == 0 ]]; then
            log "Parece que o apt está instalado e o ffmpeg4 está faltando, assumindo Ubuntu/Debian e baixando bibliotecas..."
            install_ffmpeg4
        fi
    fi

    if (( ${#missing_deps[@]} != 0 )); then
        log "As seguintes dependências estão em falta no seu sistema: ${missing_deps_list[*]}"
        while true; do
            read -p "Você quer instalar elas automaticamente? [y/n]: " yn
            case $yn in
                [Yy]* ) install_deps; break;;
                [Nn]* ) break;;
                * ) break;;
            esac
        done
   fi
}

check_deps
