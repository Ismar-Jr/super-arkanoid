
extends Node2D

# Referência ao temporizador responsável por reiniciar a partida.
@onready var timer_reset = $TimerReset


# Chamada quando um corpo entra na zona de morte.
func _on_death_zone_body_entered(body: Node2D) -> void:

	# Se for a bola, inicia a contagem para reiniciar o jogo.
	if body.name == "Ball":
		timer_reset.start()

	# Outros objetos, como itens não coletados, são removidos.
	else:
		body.queue_free()


# Chamada quando o temporizador termina sua contagem.
func _on_timer_reset_timeout() -> void:

	# Marca a partida como não iniciada no GameManager (Autoload).
	GameManager.started = false

	# Recarrega a cena atual, restaurando o cenário inicial.
	get_tree().reload_current_scene()
