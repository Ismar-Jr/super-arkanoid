# Orbital Reactor — arte vetorial

O conjunto atual usa oito SVGs originais, com curvas suaves, gradientes, cromados e impressão espacial inspirada na composição das mesas clássicas. O gerador usa apenas Python 3:

```sh
python3 Tools/generate_pinball_art.py
```

A arte combina plásticos marfim, borrachas vermelhas, insertos âmbar e turquesa, Saturno e um foguete desenhados no próprio código. Todas as letras presentes nos SVGs usam um alfabeto vetorial próprio, sem dependências de fontes instaladas. Os PNGs anteriores permanecem como recursos históricos e não são a textura da mesa vertical.

| Arquivo | Dimensão | Uso |
| --- | --- | --- |
| `playfield.svg` | 640 × 900 | Mesa vertical; origem (40, 160) na composição 720 × 1120 |
| `menu_background.svg` | 720 × 1120 | Fundo de backglass para o menu |
| `logo.svg` | 560 × 140 | Identidade SUPER PINBALL / ORBITAL REACTOR |
| `ball.svg` | 20 × 20 | Esfera cromada |
| `life.svg` | 20 × 20 | Ícone de bolas restantes |
| `bumper.svg` | 64 × 64 | Pop bumper cromado com cúpula iluminada |
| `flipper.svg` | 100 × 24 | Palheta marfim com borracha vermelha; espelhada à direita |
| `target.svg` | 28 × 18 | Alvo iluminado da bancada lateral |

As coordenadas dos trilhos, divisórias dos rollovers e slingshots correspondem às colisões em `Scripts/Pinball/table_layout.gd`. A ilustração de Saturno, as faixas, setas e a escala de bônus são impressão plana do playfield. A bola mantém destaque sobre a pintura central.

- Bumpers: (240, 245), (380, 245), (310, 345).
- Bancada de alvos: (124, 390), (124, 438), (124, 486), girados 90°.
- Rollovers: (230, 105), (310, 105), (390, 105). A divisória em x=430 começa em y=95 para liberar a trajetória natural do lançador; as demais começam em y=65.
- Pivôs: (208, 825) e (412, 825).
- Slingshots: esquerdo (110, 678), (196, 750), (132, 750); direito espelhado em x=310.
- Canal do lançador: divisória em x=558, base em y=874, bola inicial em (590, 846).

As passagens entre os slingshots e as guias inferiores têm no mínimo 32,8 px livres para a bola de 20 px. A arte acompanha essa folga e mantém o canal aberto.

Referências de composição: a bancada lateral e as lâmpadas de bônus de *Eight Ball Deluxe* (Bally), a composição espacial e as borrachas vermelhas de *Firepower* (Williams), e a leitura vertical de mesas digitais como *Space Cadet*. Nenhuma imagem, marca ou sprite desses jogos foi copiada.
