# deltaport
<img width="160rem" alt="logo do deltaport" src=".github/deltaport.png" />

> Esse projeto **NÃO** é afiliado com o Toby Fox ou TEIARRUMA.

Uma tentativa (não oficial) de portar DELTARUNE para sistemas Linux 64-bit (x86_64).

Eu criei esse projeto com o objetivo de aprendizagem e uso pessoal, o jogo funciona perfeitamente com Proton e você provavelmente deveria usar ele.

Esse port é para a versão **[paga da Steam](https://store.steampowered.com/app/1671210/DELTARUNE/)**, não havendo suporte para a DEMO atualmente. Nenhum arquivo do jogo é incluído aqui e você vai precisar trazer sua própria cópia.

A versão Flatpak/Snap da Steam e distros imutáveis como SteamOS e Bazzite não são suportados por esse port.

Essa é a versão **PT-BR** 🇧🇷 do deltaport, if you speak **English** 🇬🇧 , please go to the **[main branch](https://github.com/pugdev3/deltaport/tree/main)**

Digo novamente que este projeto **NÃO** está envolvido ou é afiliado de nenhuma forma com o **[TEIARRUMA](https://twitter.com/teiarruma)**, eles não dão suporte para ports não oficiais como esse e qualquer problema com a instalação deve ser reportado aqui.

O port utiliza a [tradução feita por eles](https://github.com/teiarruma/deltarune-ptbr) e todos os scripts foram traduzidos para português.

## Como usar
> Você **precisa** da versão **1.40** para usar esse port, veja um pouco abaixo como conseguir essa versão.
 
Baixe o último [lançamento no Github](https://github.com/pugdev3/deltaport/releases/latest), extraia o arquivo, e dentro da pasta, clique duas vezes no `port.sh` ou rode no seu terminal:

```shell
pug@computaria ~>  ./port.sh
```
Certifique-se que você baixou a versão com `_pt_br` no nome ou se não você está usando a versão em inglês. E também que o jogo está no diretório correto: `~/.local/share/Steam/steamapps/common/DELTARUNE`

Depois disso siga as instruções na tela e então rode o jogo pela Steam ou execute  `DELTARUNE.sh` na pasta do jogo.

Esse projeto foi testado no Arch Linux com KDE Plasma.

https://github.com/user-attachments/assets/c1b5f803-d715-421c-aa3a-bee917fc5265

(pequeno vídeo de demonstração do port rodando no Arch)

## Baixando a versão correta <img width="30rem" alt="kris fazendo dois" src="https://github.com/user-attachments/assets/973789b5-0c1b-4577-a24f-f7cb7314eb6c" />

A maioria dos mods / traduções requerem uma versão específica do jogo para funcionar, e com o tempo, os devs atualizam o jogo, isso na Steam acaba dificultando acessar as versões antigas para download (a Steam só baixa a mais recente), por isso escrevi esse guia para você conseguir as versão correta.

Lembrando que isso não é uma forma de pirataria, sua conta precisa possuir o DELTARUNE na Steam para os comandos funcionarem.

Abra seu programa de terminal, digite `steam -console`, deve ser algo como isso:
```shell
pug@computaria ~> steam -console
```
Pressione enter e depois de abrir, abra a aba de Console

<img width="615" height="67" alt="steam com aba de console" src="https://github.com/user-attachments/assets/30de7990-1fea-4d2e-a155-09acbd6ff430" />

Agora acesse **[este link do SteamDB](https://steamdb.info/depot/1671212/manifests/)**, a página está na inglês mas não se preocupe, vou dizer o que você precisa fazer

<img width="800em" alt="página do SteamDB com as versões de DELTARUNE" src="https://github.com/user-attachments/assets/5186754f-04b9-4d92-8921-fc3a97b84f53" />

A onde está escrito `Copy format` (Formato de cópia) selecione `Steam console` e depois clique no botão de copiar do lado da setinha (logo abaixo de `deltarune105`)

Essa é a versão **1.04**, agora, volte para Steam e cole o que você copiou na caixinha de texto, deve ficar assim:

<img width="800em" alt="aba de console da Steam com o comando download_depot colocado" src="https://github.com/user-attachments/assets/9b1bbbea-658d-44e6-b5c9-eca1a12d0b82" />

Depois disso, pressione enter, e deve começar a baixar o jogo.

<img width="800em" alt="Steam com aba de console e gerenciador de arquivos Dolphin" src="https://github.com/user-attachments/assets/368d92f0-fff8-434f-807e-1fc175a87959" />


Na captura de tela você deve ter percebido que no caminho do jogo: `\steamapps\content\app_1671210\depot_1671212` a Steam coloca `\` no meio por algum motivo (virou Windows agora steam??), só mudar para `/` e abrir no seu explorador de arquivos de escolha, você deve ter a versão 1.04 baixada no seu PC!

Agora, se você quer abrir o jogo pela Steam, primeiro você tem que instalar o jogo pela Steam, depois abra `~/.local/share/Steam/steamapps/common` e apague a pasta do DELTARUNE e substitua pela pastinha `depot_1671212` que a gente baixou usando o comando

Você pode fazer isso antes ou depois de portar o jogo, só tenha certeza de escolher a pasta correta.

## Como esse trem funciona? <img width="35rem" alt="pug pensante" src="https://github.com/user-attachments/assets/8ce7e9a3-9809-4022-b6bc-95cc2165cab1" />

O GameMaker: Studio, a ferramenta que o tobias raposo usa pra fazer o DELTARUNE, exporta os jogos como bytecode (código não específico a uma plataforma) ao invés de código nativo compilado, esse código então é interpretado pelo runner (o .exe, executável específico da plataforma) que roda o jogo no seu PC numa espécie de máquina virtual, similar a como o Java funciona.

A gente pode tirar vantagem disso pra portar o jogo pra quase qualquer plataforma :D 

Existem alguns projetos que tentam modificar ou recriar o runner como **[Butterscotch](https://github.com/ButterscotchRunner/Butterscotch/)** ou **[OpenGM](https://github.com/misternebula/OpenGM)**, 

Não é o caso desse projeto, esses runners acabam sendo incompletos e tendo vários bugs, por isso, é usado o runner original, apenas modificando o código do jogo para funcionar.

O script do port modifica a estrutura do jogo para a estrutura que o GameMaker espera de um jogo de Linux e utiliza o runner específico do sistema, isso funciona, porém, ainda temos alguns problemas.

o DELTARUNE tem vários capítulos, e cada um deles tem sua propria pastinha com o código e arquivos do capítulo

Internamente, o jogo muda entre capítulos usando uma função especial chamada `game_change()` que não tem suporte pra Linux

Pra resolver isso, foi implementada uma gambiarra no código do jogo, criando um arquivo especial na pasta de saves do jogo ao invés de chamar essa função

Fica mais ou menos assim: `~/.config/DELTARUNE/deltaport_chapter# <- Número do capítulo`
Esse arquivo então é lido pelo `DELTARUNE.sh` que faz a troca, replicando o `game_change()`

O objetivo aqui é funcionar quase igual a versão de Windows.

Para a gente conseguir modificar o código do jogo, são usados patches binários, eles estão separados em duas pastas dentro do repositório, a pasta `files/patches/[VERSÃO]/deltaport` essas são as do deltaport, e as patches da pasta `files/patches/[VERSÃO]/pt_br` esse é o código do TEIARRUMA para traduzir o jogo em PT-BR

Esses patches apenas contém a diferença entre os dois arquivos, então você precisa ter um `data.win` (arquivo do jogo) que seja compátivel com o patch pra funcionar.

## Dependências <img width="35rem" alt="susie virada" src="https://github.com/user-attachments/assets/7e73bb95-805b-4680-a5b1-f113d98cea34" />

O arquivo `deps.sh` é incluído no repositório e é usado pelo script principal: `port.sh`

Ele deve instalar automaticamente todas as dependências para você, a menos que você esteja no nichoOS

Dito isso, é preciso ter:
* `hpatchz` - De [HDiffPatch](https://github.com/sisong/HDiffPatch), isso é usado para aplicar as patches no jogo (antigamente era usado o xdelta3)
* `inotifywait` - Usado para observar a pasta de saves por arquivos de gatilho, na maioria das distros o nome do pacote é `inotify-tools`
* `ffmpeg4` - Usado para reproduzir vídeos nos capítulo 3, nota que o GameMaker 2022 LTS precisa especificamente do FFmpeg4 para funcionar.
* `wget` - Deve vir instalado em quase qualquer distro, usado pra baixar uns arquivos

## Problemas conhecidos <img width="35rem" alt="ralsei chocada" src="https://github.com/user-attachments/assets/f081e38a-e5a1-4c24-a34e-de28e8c98eb9" />

* Ao carregar um save, você deve notar que seu áudio/música sumiram (cadê meu som???) calma que não é seu PC, pra arrumar isso, vá para sua pastinha de saves: `~/.config/DELTARUNE` e abra seu arquivo de save:
1. `filech#_0` - Primeiro slot de save no menu
2. `filech#_1` - Segundo slot de save no menu
3. `filech#_2` - Terceiro slot de save no menu

Vá para a linha **569/570** (333/334 no Capítulo 1) e mude o `.` para `,` ou vice-versa.

* Controles podem não funcionar

* Um cachorro irritante pode aparecer durante a gameplay
