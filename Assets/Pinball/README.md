# Super Pinball — Orbital Reactor

Sete PNGs originais em pixel art, gerados apenas com Python 3. O script reutiliza as primitivas de rasterização do gerador do Arkanoid e grava exclusivamente em `Assets/Pinball/`:

```sh
python3 Tools/generate_pinball_art.py
```

O playfield combina trilhos cromados, circuito impresso azul, cápsulas ciano, alvos magenta e palhetas âmbar. A impressão central e as órbitas têm contraste reduzido para preservar a leitura da esfera.

| Arquivo | Dimensão | Coordenadas/uso |
| --- | --- | --- |
| `playfield.png` | 640 × 480 | Mesa local, posicionada em (24, 64) na composição 960 × 576 |
| `logo.png` | 560 × 140 | Novo logotipo SUPER PINBALL |
| `ball.png` | 20 × 20 | Esfera cromada centralizada |
| `bumper.png` | 64 × 64 | Peça circular com raio visível de aproximadamente 26 px |
| `flipper.png` | 100 × 24 | Arte da palheta esquerda, pivô aproximado (10, 12); espelhar para a direita |
| `target.png` | 28 × 18 | Alvo frontal iluminado magenta |
| `life.png` | 20 × 20 | Ícone de esfera para bolas restantes |

## Mapeamento da mesa

Todas as coordenadas abaixo são locais ao playfield e seguem a geometria da implementação física:

- Bumpers: (235, 146), (385, 146), (310, 227).
- Alvos superiores: (235, 70), (310, 70), (385, 70).
- Pivôs das palhetas: esquerda (208, 405), direita (412, 405); eixo físico de 80 px e raio de 9 px. A abertura central em repouso permite a drenagem de uma esfera de 20 px.
- Slingshot esquerdo: triângulo (94, 298), (180, 370), (116, 370).
- Slingshot direito: triângulo (526, 298), (440, 370), (504, 370).
- Guia inferior esquerda: (58, 320), (78, 354), (150, 380), (196, 398).
- Guia inferior direita: (550, 320), (530, 354), (458, 380), (424, 398).
- Canal de lançamento: x568–610, com mola inferior em y420–458.
- Divisória do canal: x558 de y118 a y460.
- Trilho externo: (58, 466), (34, 430), (30, 345), (30, 100), (42, 56), (68, 28), (104, 14), (538, 14), (574, 24), (598, 46), (612, 74), (616, 120), (616, 454).
- Saída superior do canal: o arco externo curva a trajetória para a esquerda, sem mecanismo de teleporte.
- Base do lançador: (568, 454) até (616, 454).
- Região inferior de drenagem: centro entre as duas palhetas; as setas das saídas laterais são apenas marcações visuais.

Não há fontes, sprites ou texturas de terceiros. A fonte bitmap compartilhada, o gabinete e o fundo de menu continuam nos recursos existentes de `Assets/16bit/`.
