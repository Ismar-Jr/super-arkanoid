# Áudio original — Super Arkanoid

As duas músicas e os dez efeitos foram compostos e sintetizados para este projeto. Não utilizam samples, músicas, fontes sonoras ou serviços externos. O gerador requer apenas Python 3 e produz os mesmos arquivos em cada execução:

```sh
python3 Tools/generate_audio.py
```

Todos os arquivos são WAV PCM, mono, 16 bits e 22.050 Hz. As trilhas combinam melodia de timbre cristalino, pulsos suaves, baixo triangular e percussão de ruído. Os efeitos usam notas e glissandos distintos. Pequenas rampas nas bordas evitam estalos. A interface recebe efeitos mais discretos; os demais arquivos deixam margem para mixagem sem clipping.

| Caminho a partir de `Audio/` | Duração | Evento |
| --- | ---: | --- |
| `Music/menu.wav` | 16,000 s | Menu, 8 compassos a 120 BPM |
| `Music/partida.wav` | 20,571 s | Partida, 12 compassos a 140 BPM |
| `SFX/rebote.wav` | 0,095 s | Rebote na plataforma ou parede |
| `SFX/bloco.wav` | 0,190 s | Destruição de bloco |
| `SFX/laser.wav` | 0,170 s | Disparo de projéteis |
| `SFX/coleta.wav` | 0,600 s | Coleta de power-up |
| `SFX/vida.wav` | 0,780 s | Perda de vida |
| `SFX/game_over.wav` | 1,650 s | Fim da partida |
| `SFX/iniciar.wav` | 0,950 s | Lançamento da bola |
| `SFX/setor.wav` | 1,120 s | Conclusão de setor |
| `SFX/ui_move.wav` | 0,090 s | Foco ou seleção na interface |
| `SFX/ui_confirm.wav` | 0,240 s | Confirmação de botão |

## Uso no jogo

O Autoload `AudioManager` acompanha os estados do `GameManager`: menu seleciona sua faixa, READY e PLAYING compartilham a música da partida, e GAME_OVER encerra a música e toca a vinheta final. Reemitir READY durante reposição ou troca de setor não reinicia a faixa.

No rodapé do menu, **MÚSICA** e **EFEITOS** controlam os buses `Music` e `SFX` separadamente. Mouse ou Tab + setas ajustam os volumes, e zero silencia o canal. As preferências ficam em `user://audio.cfg`. O bus Master usa um limitador de saída a −1 dB.

Os efeitos usam players temporários no gerenciador, então continuam depois de remover um bloco ou item. Há um limite de 16 vozes simultâneas; cada player é liberado ao terminar. A sequência original de 16 tiros produz um efeito por dupla, sem modificar a cadência.

Para tocar um efeito já cadastrado em outro evento:

```gdscript
AudioManager.play_sfx(&"coleta")
```

As constantes `MENU_MUSIC`, `GAME_MUSIC` e o dicionário `SOUNDS` em `Scripts/audio_manager.gd` mapeiam os arquivos. Para usar outro formato, como OGG, altere o respectivo caminho nesse script e configure o loop no recurso importado.

## Loops e substituição

As músicas incluem metadados WAV `smpl` com loop do início ao fim. Os arquivos de importação versionados selecionam explicitamente **Forward** para as duas músicas e **Disabled** para os efeitos, com compressão **PCM (Uncompressed)**. Caso esses arquivos sejam recriados pelo Godot, a opção padrão **Edit > Loop Mode > Detect From WAV** também lê os metadados das músicas. A documentação oficial descreve a [importação de áudio e detecção de loop](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html).

Para trocar um som, substitua o WAV no mesmo caminho e reimporte no Godot. Mantenha os efeitos sem loop. Para uma música própria sem metadados, selecione seu WAV no painel FileSystem e configure **Edit > Loop Mode > Forward**, início zero e fim no término do arquivo. Preserve os nomes usados pelo gerenciador de áudio.

O gerador sobrescreve apenas seus doze WAVs e `audio_manifest.tsv`. Arquivos personalizados serão substituídos se ocuparem esses mesmos caminhos; faça uma cópia antes de executar o gerador novamente.

## Verificação

`audio_manifest.tsv` registra duração, pico, RMS e SHA-256 de cada arquivo após a geração. Os valores são calculados dos samples exportados; os picos ficam abaixo de 0,8 da escala total. A avaliação numérica verifica formato, ausência de clipping e determinismo, mas não substitui uma avaliação auditiva da mixagem no jogo.

Validação de integração no Godot 4.7.2:

- `Tests/audio_test.gd`: **50 verificações aprovadas**, incluindo captura real da mistura de música e efeitos com `AudioEffectCapture`.
- `Tests/smoke_test.gd`: **59 verificações do jogo aprovadas** após a integração do áudio.
- `Tests/quit_test.gd`: botão SAIR encerra corretamente, sem recursos de áudio pendentes.
- Solicitação de fechamento da janela também validada em processo separado.
- Interface nativa OpenGL: **14 verificações aprovadas**, com mouse, teclado, bloqueio pelo manual e persistência.
- Logs finais sem vazamentos de objetos, recursos ou RIDs; a mensagem de certificados do ambiente macOS não afetou os testes.

O encerramento passa por `AudioManager.quit_game()`: interrompe os players e aguarda 80 ms para o mixer liberar o último buffer. As preferências e recordes dos testes usam arquivos temporários separados dos dados do jogador.
