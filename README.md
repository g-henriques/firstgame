# Arena Survivor

Jogo de sobrevivência em arena feito em **Godot 4.3**, inspirado no *Vampire Survivors*.
Move-te com **WASD**, as armas atacam sozinhas, apanha gemas para ganhar experiência e escolhe
uma melhoria sempre que sobes de nível. Sobrevive **10 minutos** para ganhar.

## Como correr

1. Instala o [Godot 4.3](https://godotengine.org/download) (versão standard, não .NET).
2. Abre o Godot → *Import* → escolhe `project.godot` nesta pasta.
3. Carrega em **F5** (ou ▶). A cena inicial é o ecrã de título.

Pela linha de comandos: `godot --path .`

## Controlos

| Tecla | Ação |
| --- | --- |
| WASD / setas / analógico | Mover |
| ESC / P | Pausa |
| 1, 2, 3 / setas + Enter / rato | Escolher melhoria |

## Conteúdo (MVP)

**3 armas** (até nível 5)
- **Magic Wand** — projéteis mágicos contra o inimigo mais próximo (arma inicial).
- **Throwing Knife** — facas perfurantes na direção em que andas.
- **Holy Aura** — área à volta do jogador que causa dano e empurra.

**5 inimigos**
- **Bat** (rápido e fraco), **Slime** (lento), **Skeleton** (a partir de 1:00),
  **Ghost** (atravessa outros inimigos, a partir de 2:30), **Ogre** (tanque, a partir de 4:00).
- Hordas em círculo a cada minuto; o **Ogre King** (boss) aparece aos 5:00 e 8:00 e deixa um baú
  que dá um nível extra.

**10 melhorias passivas** (até nível 5; Duplicator até 3)
Might (+20% dano), Swiftness (+10% velocidade), Vitality (+20 vida máx.), Recovery (+0.4 vida/s),
Armor (−1 dano recebido), Magnet (+40% raio de recolha), Haste (−8% cooldown),
Duplicator (+1 projétil), Reach (+15% área), Wisdom (+15% XP).

**Ecrãs / GUI**: ecrã de título (Play, How to Play, Quit, recordes), HUD (barra de XP, nível,
vida, tempo, mortes, armas e passivas), menu de subir de nível, pausa, derrota e vitória.
Recordes guardados em `user://save.cfg`.

## Arte (Aseprite)

Toda a arte — personagens, inimigos, animações, mapa (tileset), ícones, GUI, logótipo e a fonte
pixel — tem o ficheiro editável em `art/*.aseprite` e é exportada para `assets/`:

- `assets/sprites/<nome>.png` + `.json` — spritesheet horizontal e dados no formato do CLI do Aseprite
  (`--format json-array --list-tags`). O jogo lê as **tags** (`idle`, `walk`, `move`…) e as
  **durações** de cada frame a partir do JSON, e o tamanho dos frames também — por isso podes
  redesenhar sprites (ex.: em 32×32), mudar o número de frames ou os tempos sem tocar no código.
- `assets/ui/*.png` — painéis, botões, barras, slots e logótipo (9-slice no tema).
- `assets/fonts/pixel_font.png` + `.fnt` — fonte bitmap (BMFont) com acentos.

Fluxo de edição:

```bash
# 1. editar art/<nome>.aseprite no Aseprite (manter as tags)
# 2. re-exportar
tools/export_aseprite.sh <nome>
# 3. se mudaste arte da GUI, regenerar o tema
godot --headless --path . --script res://scripts/editor/build_theme.gd
```

O `.claude/settings.json` do repositório ativa automaticamente o plugin `aseprite@g-henriques`
(skill `aseprite-pixel-art`, de `g-henriques/claude-skills`) no Claude Code. A skill precisa do
servidor MCP do Aseprite, que só existe onde o Aseprite está instalado (o teu computador).

`tools/art/build_art.py` é o gerador que criou a primeira versão da arte (escreve `.aseprite`
nativos com camadas, tags e durações). Correr de novo **sobrescreve** `art/` e `assets/`.

## Estrutura

```
scenes/            title, world, player, enemy, projectile, pickup, ui/*
scripts/           player, enemy, world (spawner/eventos), arena_map, weapons/, ui/
scripts/data/db.gd todos os dados: inimigos, armas, melhorias
scripts/autoload/  Assets (carrega sheets do Aseprite), Game (recordes, cenas)
tests/             smoke_test.gd (corre uma partida com um bot), screenshots.gd
```

## Testes

```bash
# partida completa simulada (10 min de jogo), verifica que chega à vitória
SMOKE_FRAMES=40000 godot --headless --fixed-fps 60 --path . --script res://tests/smoke_test.gd
```
