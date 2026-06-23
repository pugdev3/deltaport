#!/usr/bin/env bash
set -euo pipefail

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FFMPEG4_INSTALLED=0
HDIFFPATCH_INSTALLED=0
deps=("hpatchz" "inotifywait" "ffmpeg" "wget")
# Internal / to display on screen.
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
            warn "hdiffpatch already installed, exiting..."
            return;
    fi
    log "Installing hdiffpatch..."
    mkdir -p linux64
    wget https://github.com/sisong/HDiffPatch/releases/download/v4.12.2/hdiffpatch_v4.12.2_bin_linux64.zip -O hdiffpatch.zip
    unzip hdiffpatch.zip -d .

    sudo install -Dm 0755 'linux64/hdiffz' "/usr/bin/hdiffz"
    sudo install -Dm 0755 'linux64/hpatchz' "/usr/bin/hpatchz"

    rm hdiffpatch.zip
    rm -r linux64
}

install_ffmpeg4() {
    if [ "$FFMPEG4_INSTALLED" == 1 ]; then
            warn "ffmpeg4 already installed, exiting..."
            return;
    fi
    touch .ubuntu
    # Download ffmpeg4 libs on Ubuntu for video playback compatibility
    log "Downloading ffmpeg4 libraries..."
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
        error "Unable to detect distribution, /etc/os-release not found."
    fi

    install_ubuntu() {
        log "Installing dependencies..."
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y ${missing_deps[*]}
        install_patcher
        install_ffmpeg4
        log "Dependencies sucessfully installed :)"
        sleep 1
        clear
    }

    install_fedora() {
        log "Installing dependencies..."
        sudo dnf update
        if ! rpm -q --quiet rpmfusion-free-release; then
            log "Installing rpmfusion for necessary packages"
            sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        fi
        sleep 5
        sudo dnf install --allowerasing -y ${missing_deps[*]} compat-ffmpeg4
        install_patcher
        log "Dependencies sucessfully installed :)"
        sleep 1
        clear
    }

    install_arch() {
        log "Installing dependencies..."
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
        log "Dependencies sucessfully installed :)"
        sleep 1
        clear
    }

    case "${DISTRO_ID}" in
        ubuntu|debian)
            log "Ubuntu/Debian detected."
            install_ubuntu
            ;;
        fedora)
            log "Fedora detected."
            install_fedora
            ;;
        arch)
            log "Detected Arch btw."
            install_arch
            ;;
        *)
            if [[ "${DISTRO_LIKE}" == *"debian"* || "${DISTRO_LIKE}" == *"ubuntu"* ]]; then
                log "Your distro seems to be Debian-based."
                install_ubuntu
            elif [[ "${DISTRO_LIKE}" == *"fedora"* || "${DISTRO_LIKE}" == *"rhel"* ]]; then
                log "Your distro seems to be Fedora-based."
                install_fedora
            elif [[ "${DISTRO_LIKE}" == *"arch"* ]]; then
                log "It looks like you are using Arch btw"
                install_arch
            else
                error "Unable to detect distribution. You're probably not on the big three (Arch, Debian, Fedora), in that case, you are in your own, good luck :D"
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
            log "FFmpeg4 missing and apt installed, assuming Ubuntu/Debian and downloading libs..."
            install_ffmpeg4
        fi
    fi

    if (( ${#missing_deps[@]} != 0 )); then
        log "You're missing the following dependencies: ${missing_deps_list[*]}"
        while true; do
            read -p "Do you want to automatically install them? [y/n]: " yn
            case $yn in
                [Yy]* ) install_deps; break;;
                [Nn]* ) break;;
                * ) break;;
            esac
        done
   fi
}

check_deps
