# Super Arkanoid — Orbital Defense

Laboratório visual de arcade 16-bit em Godot 4.7, na branch `codex/redesign-16bit`.

## Executar

1. Importe `project.godot` no Godot 4.7 ou versão compatível.
2. Aguarde a importação dos recursos e pressione **F5**.
3. Escolha **INICIAR JOGO** e pressione **Espaço** para lançar a bola.

A apresentação usa 960 × 576, com a arena física original de 640 × 480 e um console lateral. A janela preserva a proporção, com filtragem nearest para pixel art.

## Controles

| Ação | Controle |
| --- | --- |
| Mover plataforma | A / D ou setas esquerda / direita |
| Lançar bola / nova tentativa | Espaço |
| Navegar nos menus | Setas ou Tab, Enter / Espaço, mouse |
| Retornar ao menu | Esc durante a partida |
| Fechar o manual | Esc ou VOLTAR |

Cada bloco vale **100 pontos**. A partida começa com **3 vidas**; uma queda preserva os blocos restantes e o placar, com 2 segundos de reposição. Ao limpar os 48 blocos, o próximo setor repete a formação, preservando vidas e pontuação. O recorde é salvo em `user://records.cfg`.

O módulo laser mantém a regra original: 20% de chance por bloco destruído pela bola, intervalo mínimo de 15 segundos, 16 tiros automáticos em 8 duplas, a cada 0,2 segundo.

## Estrutura

- `Scenes/main.tscn`: composição da arena e do HUD.
- `Scenes/level_1.tscn`: formação original, atores e colisões.
- `Scenes/UI/`: menu, HUD e Game Over reutilizáveis.
- `Scripts/game_manager.gd`: estados, pontuação, vidas e recorde.
- `Scripts/level.gd`: tentativas, limpeza de efeitos e setores.
- `Scripts/UI/`, `Scripts/Effects/`: interface e efeitos.
- `Assets/16bit/`: PNGs e fonte bitmap originais.
- `Tools/generate_art.py`: gerador determinístico, somente Python padrão.
- `Tests/smoke_test.gd`: regressão de integração executada no Godot.
- `Docs/REDESIGN_16BIT.md`: decisões, inventário e validação.

Os sprites anteriores continuam em `Sprites/`. O cache `.godot/` é recriado pelo editor.

## Música e efeitos

O jogo inclui duas músicas originais em loop (menu e partida) e dez efeitos retrô para interface, lançamento, rebotes, blocos, laser, coleta, perda de vida, conclusão de setor e Game Over.

Os controles **MÚSICA** e **EFEITOS** ficam no rodapé do menu e aceitam mouse ou Tab + setas. Arraste até zero para silenciar um canal. Os volumes são salvos em `user://audio.cfg`, separados do recorde.

- `Scenes/audio_manager.tscn` e `Scripts/audio_manager.gd`: Autoload de reprodução e preferências.
- `default_bus_layout.tres`: canais Master, Music e SFX, com limite de saída.
- `Audio/Music/` e `Audio/SFX/`: arquivos WAV originais, prontos para substituir.
- `Tools/generate_audio.py`: composição e síntese reproduzíveis, somente Python padrão.
- `Audio/README.md`: inventário, importação, loops e substituição dos arquivos.

A música da partida continua entre tentativas e setores. O Game Over interrompe a faixa e toca sua vinheta. Os efeitos de blocos e itens terminam mesmo após esses objetos serem removidos.

Para regenerar os áudios originais:

```sh
python3 Tools/generate_audio.py
```

## Recriar a arte

```sh
python3 Tools/generate_art.py
```

## Validar a integração

```sh
godot --headless --path . --script Tests/smoke_test.gd
godot --headless --path . --script Tests/quit_test.gd
godot --headless --path . --script Tests/audio_test.gd
```

Validado no Godot 4.7.2: **59 verificações do jogo e 50 de áudio aprovadas**, mais saída por mouse e 14 verificações nativas dos controles de volume.

Use o caminho do executável instalado se `godot` não estiver no PATH. O teste usa um arquivo temporário de recorde e não substitui o recorde do jogador.
