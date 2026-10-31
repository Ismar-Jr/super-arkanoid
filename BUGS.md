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
