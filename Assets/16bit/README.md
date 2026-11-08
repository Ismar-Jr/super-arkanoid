# Orbital — recursos gráficos originais

Todos os PNGs e a fonte bitmap foram desenhados para este projeto por código, sem imagens, fontes ou serviços externos. O gerador utiliza apenas a biblioteca padrão do Python 3:

```sh
python3 Tools/generate_art.py
```

A identidade combina metal azul, luz ciano, âmbar e pequenos acentos magenta. As imagens usam pixels inteiros e filtragem nearest no projeto Godot.

| Recurso | Dimensão | Uso |
| --- | --- | --- |
| `arena.png` | 640 × 480 | Fundo sutil atrás da arena física original |
| `cabinet.png` | 960 × 576 | Carcaça com janela transparente em (24, 64), 640 × 480 |
| `menu_background.png` | 960 × 576 | Planeta com anéis, estação e cabine |
| `logo.png` | 560 × 140 | Logotipo inclinado com extrusão e lâmina cromada |
| `paddle.png` | 100 × 24 | Plataforma metálica com núcleo ciano |
| `ball.png` | 24 × 24 | Esfera com realce branco e halo discreto |
| `block_*.png` | 80 × 24 | Seis variantes de módulos blindados |
| `powerup.png` | 26 × 26 | Cápsula octogonal com raio |
| `bullet.png` | 12 × 24 | Pulso magenta com núcleo claro |
| `life.png` | 24 × 12 | Ícone de plataforma |
| `arcade.fnt` + `arcade_font.png` | fonte nominal 16 px | Alfabeto original 5 × 7, expandido em pixels 2 × 2, acentos portugueses |

O alfabeto usa a mesma aparência maiúscula para letras minúsculas. A fonte inclui dígitos, pontuação, acentos, setas e marcador de lista. O gerador é determinístico.
