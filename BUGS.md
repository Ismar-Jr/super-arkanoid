# Registro de Bugs — Super Arkanoid

Documento destinado ao registro e acompanhamento de bugs.

## Bugs em aberto

### BUG-001 — Bola presa na parede lateral

- **Data:** 30/10/2026
- **Status:** Aberto
- **Prioridade:** Baixa
- **Script:** ball.gd

#### Descrição
A bola pode ficar presa entre a plataforma e a parede lateral esquerda.

#### Comportamento esperado
A bola deve continuar sua trajetória normalmente após as colisões.

#### Comportamento observado
A bola fica aprisionada na lateral do cenário.

#### Possível causa
Interação entre move_and_collide() e velocity.bounce().
Causa ainda não confirmada.

#### Decisão
Correção adiada para não interromper o desenvolvimento.

---

## Bugs resolvidos

Nenhum até o momento.

---

### BUG-002 — Power-up continua ativo durante reinicialização

- **Status:** Aberto
- **Prioridade:** Baixa
- **Scripts:** item_power_up.gd, player.gd, GameManager
- **Correção:** Adiada

#### Descrição
Após a bola entrar na DeathZone, o TimerReset inicia
a contagem para reiniciar a partida.

Durante esse intervalo, os power-ups continuam caindo
e podem ser coletados pela plataforma do jogador.

#### Comportamento esperado
Os objetos não deveriam continuar interagindo normalmente
com o jogador durante a fase de reinicialização.

#### Comportamento observado
O power-up continua caindo e pode ser coletado antes
do término do TimerReset.

#### Causa provável
GameManager.started só recebe false no timeout do Timer.
Além disso, o power-up não verifica o estado da partida
antes de executar sua movimentação e suas colisões.

#### Decisão
Não corrigir agora. Continuar o desenvolvimento normal.
Reavaliar durante a etapa de depuração.

