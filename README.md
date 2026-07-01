# deltaport
<img width="160rem" alt="deltaport logo" src=".github/deltaport.png" />[^1]

> [!NOTE]
> This project is NOT affiliated with nor endorsed by Toby Fox, Fangamer, YoYo Games Ltd or Opera Norway AS.

An unofficial (attempt) of porting DELTARUNE[^2] to Linux

This was originally made as a learning project for personal use, the game works perfectly fine under Proton and you should probably be using that instead.

This doesn't include any game data, you will need to own a copy of the game.

Flatpak Steam and immutable distros are not supported.

Only available for Linux x86_64

## Usage
> [!IMPORTANT]
> Check out [Supported versions](https://github.com/pugdev3/deltaport#supported-versions-) for which versions you can use.
 
Download the latest release, and double-click `port.sh` or run in your terminal:

```shell
pug@puter ~>  ./port.sh
```
Follow the instructions on the screen and then launch the game through Steam or run `DELTARUNE.sh` in the game directory.

This project was tested on Ubuntu 26.04 and Arch Linux.

https://github.com/user-attachments/assets/9e50df05-e07f-4e7a-8951-ed42dc3346b4

(small video demo)

## Other versions <img width="30rem" alt="kris doing two" src="https://github.com/user-attachments/assets/973789b5-0c1b-4577-a24f-f7cb7314eb6c" />

If you're reading this in the future, you may find yourself having a different current version than the one supported here, in that case, here's how you can download a specific version of the game to able to use the port.

Open your terminal program, and type `steam -console`, it should look like this:
```shell
pug@puter ~> steam -console
```
After opening, click the Console tab:

<img width="617" height="72" alt="steam with console tab" src="https://github.com/user-attachments/assets/cf77220e-773c-4436-87b3-4e9664665c00" />

Now, go to [here](https://steamdb.info/depot/1671212/manifests/) on SteamDB, you should find a list of manifests (versions) sorted by upload date, choose the one that applies

<img width="378" height="54" alt="steamdb with two copy formats" src="https://github.com/user-attachments/assets/6e3eb9c4-9109-433c-bd57-6489c2ed564b" />

Make sure the copy format is: `Steam console` and click copy.

Back on Steam, go ahead and paste what you copied, it should look like this:

<img width="800em" alt="steam window on console tab with download_depot command" src="https://github.com/user-attachments/assets/09828c1f-e84f-4622-9bf0-0bec4b70c16c" />

After this, hit enter, it should start downloading the depot.

<img width="800em" alt="steam console window with dolphin file manager" src="https://github.com/user-attachments/assets/877b55cf-2a35-41f3-bd35-4b6c89686200" />

You may notice that at the end of the path `\steamapps\content\app_1671210\depot_1671212` Steam puts `\` there for some reason, just change it to `/` and open it in your file browser of choice, you should have a copy of the game, run `port.sh` and select this directory and you're good to go!

If you want to open the game through Steam, just move the directory to `steamapps/common/DELTARUNE` so that Steam uses it.

## Supported versions <img width="35rem" alt="happy cat" src="https://github.com/user-attachments/assets/8dc9e7c9-6ccc-4dd3-bdb9-28a138d09b85" />

Here is a list of the currently supported versions by the port:
| Version  | MD5 Checksum  | Launch date | Release/branch |
| -------- | ------------- | ----------- | -------------- |
| [v1.01C and older](https://steamdb.info/patchnotes/18791270/) <img width="35rem" alt="gerson saying i'm old" src="https://github.com/user-attachments/assets/6839c8c1-1419-4c0e-bcc0-124690ed78de" /> | `bdd3fbeb0f51a7b522ca296092a20853` | < 9 June 2025 | [legacy](https://github.com/pugdev3/deltaport/tree/legacy) (branch)
| [v1.04](https://steamdb.info/patchnotes/19477244/) | `9d1fea9de81219ea7304f32f1ae7a878` | 5 August 2025 | [v0.01](https://github.com/pugdev3/deltaport/releases/download/v0.01/deltaport-v0.01.tar.xz)                                                            
| [v1.05 (deltarune105 beta)](https://bsky.app/profile/undertale.com/post/3lxbfrqodwc2l) | `5d3e158dbe6888fbf24471019fbde3c9` | 26 August 2025 | [v0.01](https://github.com/pugdev3/deltaport/releases/download/v0.01/deltaport-v0.01.tar.xz)        
| [v0.0.240 (Chapter 5 release)](https://steamdb.info/patchnotes/23736632/) | `f3dabe6444829688fd7fbaa68f78794f` | 24 June 2026 | [v0.02](https://github.com/pugdev3/deltaport/releases/download/v0.02/deltaport-v0.02.tar.xz)/[v0.03](https://github.com/pugdev3/deltaport/releases/download/v0.03/deltaport-v0.03.tar.gz)          
| [v0.0.241](https://steamdb.info/patchnotes/23909557/) | `0a448a89c32c802a138621a39ced69db` | 25 June 2026 | [v0.02](https://github.com/pugdev3/deltaport/releases/download/v0.02/deltaport-v0.02.tar.xz)/[v0.03](https://github.com/pugdev3/deltaport/releases/download/v0.03/deltaport-v0.03.tar.gz)     
| [v0.0.242](https://steamdb.info/patchnotes/23942272/) | `cc76c5efeb1b5fefd1822ceb1340ca10` | 27 June 2026 | [v0.03](https://github.com/pugdev3/deltaport/releases/download/v0.03/deltaport-v0.03.tar.gz)     
| [v0.0.243](https://steamdb.info/patchnotes/23962447/) | `359adb2db26d7e902f4c26b40e9b58ae` | 29 June 2026 | [v0.03](https://github.com/pugdev3/deltaport/releases/download/v0.03/deltaport-v0.03.tar.gz)     
| [v0.0.244](https://bsky.app/profile/undertale.com/post/3mpkv5vypm22a) | `ddedbbd10ff129b49c64dbefaa763c6a` | 1 July 2026 | [v0.03](https://github.com/pugdev3/deltaport/releases/download/v0.03/deltaport-v0.03.tar.gz)

Other versions can be upgraded using the update script + Steam update

## How it works <img width="35rem" alt="thinking pug" src="https://github.com/user-attachments/assets/8ce7e9a3-9809-4022-b6bc-95cc2165cab1" />


As GameMaker: Studio exports game code as bytecode instead of native code, we're able to run the game in any platform as long as we have a compatible runner (The GMS runner)

The porting script renames/moves the game assets to the structure that is expected for the Linux platform.

Even though that works, we still have a problem, DELTARUNE is divided in Chapters and each of them have their own game folder and their own game data

Internally, the game switches between them using a special function called `game_change()` that is unsupported on Linux.

As a workaround, the game's code was patched so that when Chapters are switched, an empty file indicating the switch is created on DELTARUNE's save directory

It looks like this: `~/.config/DELTARUNE/deltaport_chapter# <- Chapter number`
This trigger file is then read by the `DELTARUNE.sh` script which launches the chapter, replicating `game_change`

The goal here is for it to work almost exactly like the Windows version.

## Dependencies <img width="35rem" alt="susie turning around" src="https://github.com/user-attachments/assets/7e73bb95-805b-4680-a5b1-f113d98cea34" />

A `deps.sh` file is already included in the repo and is used by the the `port.sh` script.

It should automatically install all the necessary dependencies for you, unless you're on some niche distro

That being said, it is required to have:
* `hpatchz` - From [HDiffPatch](https://github.com/sisong/HDiffPatch), this is used for patching the game (older versions used xdelta3)
* `inotifywait` - Used to listen for trigger files in the save directory, can be found in distros by the name `inotify-tools`
* `ffmpeg4` - Used to play videos on Chapter 3/5, note that GameMaker 2022 LTS requires specifically FFmpeg4 to work.
* `ffmpeg` - Needed to fix video playback in Chapter 5
* `wget` - Should be pre-installed in almost any distro, used to download some files.

## Known issues <img width="35rem" alt="shocked ralsei" src="https://github.com/user-attachments/assets/f081e38a-e5a1-4c24-a34e-de28e8c98eb9" />


* When loading a save file, you may notice that your music/audio is gone, to fix this, go to your save directory: `~/.config/DELTARUNE` and open your save file:
1. `filech#_0` - First save slot
2. `filech#_1` - Second save slot
3. `filech#_2` - Third save slot

Go to line **569/570** (333/334 on Chapter 1) and change the `.` to a `,` or vice-versa.

* Controller input may not work

* An annoying dog may appear during gameplay

[^1]: The DELTARUNE logo and characters are copyright of Toby Fox, being used under fair use.
[^2]: DELTARUNE is a trademark of Royal Sciences LLC
