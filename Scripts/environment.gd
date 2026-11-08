
extends Node2D

# Solicita o reposicionamento após a perda de uma vida.
signal respawn_requested

@onready var timer_reset: Timer = $TimerReset

# Controla a animação das luzes da arena.
var ambient_time: float = 0.0


func _ready() -> void:
	# Monitora as mudanças de estado da partida.
	GameManager.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	# Atualiza a animação das luzes.
	ambient_time += delta
	queue_redraw()


func _draw() -> void:
	# Desenha luzes pulsantes nas laterais da arena.
	for index in range(8):
		var brightness := 0.15 + 0.15 * sin(ambient_time * 1.4 + index)

		draw_rect(Rect2(3, 208 + index * 28, 2, 8), Color(0.3, 0.9, 0.9, brightness))
		draw_rect(Rect2(635, 208 + index * 28, 2, 8), Color(0.3, 0.9, 0.9, brightness))


func _on_death_zone_body_entered(body: Node2D) -> void:
	if body.name == "Ball":
		# Registra a perda e interrompe a bola.
		if GameManager.lose_life():
			body.velocity = Vector2.ZERO
			body.visible = false

			# Inicia a reposição se ainda houver vidas.
			if GameManager.lives > 0:
				timer_reset.start()
	else:
		# Remove itens que ultrapassaram a arena.
		body.queue_free()


func _on_timer_reset_timeout() -> void:
	if GameManager.state == GameManager.State.READY and GameManager.lives > 0:
		# Reposiciona os atores e libera o próximo lançamento.
		respawn_requested.emit()
		GameManager.ready_locked = false
		GameManager.state_changed.emit(GameManager.state)


func _on_state_changed(value: int) -> void:
	# Cancela a reposição ao sair da partida.
	if value in [GameManager.State.MAIN_MENU, GameManager.State.GAME_OVER]:
		timer_reset.stop()
