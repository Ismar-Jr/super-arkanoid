# Super Pinball — Orbital Reactor

Pinball 16-bit em Godot 4.7, na branch experimental `codex/pinball`, derivada de `codex/redesign-16bit`.

## Jogar

1. Abra `project.godot` no Godot 4.7 ou versão compatível.
2. Aguarde a importação dos recursos e pressione **F5**.
3. Escolha **INICIAR JOGO**. Segure **Espaço** para carregar o lançador e solte para jogar a bola.

| Controle | Ação |
| --- | --- |
| A / seta esquerda | Acionar o flipper esquerdo |
| D / seta direita | Acionar o flipper direito |
| Segurar e soltar Espaço | Carregar e liberar o lançador |
| Esc | Retornar ao menu; fechar o manual |
| Mouse, setas, Tab e Enter | Navegar pelas telas |

## A mesa

Três bumpers alimentam o reator, três alvos superiores formam uma bancada de bônus e duas borrachas triangulares devolvem a esfera para o centro. Trilhos cromados, saídas laterais e uma abertura entre os flippers permitem perder a bola. Cada partida tem **três bolas**.

| Evento | Pontos base |
| --- | ---: |
| Bumper | 100 |
| Alvo superior, uma vez até reiniciar a bancada | 250 |
| Borracha triangular | 50 |
| Acender os três alvos | 1.000 de bônus |
| Cinco ativações de bumpers | 500 de bônus e próximo multiplicador |

O multiplicador começa em **1x** e chega a **5x**. Pontuação, luzes e multiplicador permanecem entre bolas. A reposição leva 1,2 segundo e reutiliza a mesma esfera. Se ela retornar ao canal de lançamento, poderá ser relançada sem perder outra bola.

O recorde é salvo em `user://pinball_records.cfg`, separado do Arkanoid. O menu inclui volumes independentes de música e efeitos, persistidos em `user://audio.cfg`. As faixas e efeitos escolhidos na versão anterior foram mantidos.

## Estrutura

- `Scenes/Pinball/pinball.tscn`: mesa principal e HUD.
- `Scenes/Pinball/{ball,flipper,bumper,target}.tscn`: peças reutilizáveis.
- `Scripts/Pinball/`: física, regras da mesa, geometria e efeitos de pontuação.
- `Scripts/game_manager.gd`: estados, três bolas, multiplicador, reator e recorde.
- `Scripts/UI/`: menu, manual, console e Game Over.
- `Assets/Pinball/`: sete PNGs originais e mapeamento visual da mesa.
- `Tools/generate_pinball_art.py`: gerador local, usando apenas Python padrão.
- `Tests/pinball_test.gd`: regressão de integração do pinball.
- `Docs/PINBALL.md`: decisões de física, inventário e validação.

Os recursos e cenas anteriores continuam disponíveis como referência. O projeto inicia no pinball nesta branch; o Arkanoid permanece na branch `codex/redesign-16bit`.

## Recriar a arte

```sh
python3 Tools/generate_pinball_art.py
```

Esse gerador escreve somente em `Assets/Pinball/`, reaproveitando as primitivas de desenho do gerador anterior.

## Validar

```sh
godot --headless --path . --script Tests/pinball_test.gd
godot --headless --path . --script Tests/quit_test.gd
```

Use o caminho completo do Godot se ele não estiver no PATH. Os testes do pinball usam arquivos temporários para recorde e áudio. Os testes antigos de Arkanoid permanecem como referência da versão anterior e não representam as novas regras da mesa.

Validação no Godot 4.7.2: **48 verificações do pinball aprovadas**, saída por mouse validada e telas inspecionadas em execução nativa OpenGL.

![Mesa em jogo](Docs/preview_pinball.png)
