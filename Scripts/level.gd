
extends Node2D

# Referências aos elementos principais da fase.
@onready var player: CharacterBody2D = $Player
@onready var ball: CharacterBody2D = $Ball
@onready var environment: Node2D = $Environment

# Impede transições simultâneas entre setores.
var wave_pending: bool = false


func _ready() -> void:
	# Configura os blocos e conecta os eventos da partida.
	GameManager.configure_blocks(get_tree().get_nodes_in_group("blocks").size())
	environment.respawn_requested.connect(_reset_attempt)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.sector_cleared.connect(_on_sector_cleared)

	# Permite iniciar a fase diretamente pelo editor.
	if GameManager.state == GameManager.State.MAIN_MENU:
		GameManager.score = 0
		GameManager.lives = GameManager.INITIAL_LIVES
		GameManager.level = 1
		GameManager.ready_locked = false
		GameManager._set_state(GameManager.State.READY)


func _unhandled_input(event: InputEvent) -> void:
	# Retorna ao menu ao pressionar a tecla de cancelar.
	if event.is_action_pressed("ui_cancel") and GameManager.state != GameManager.State.GAME_OVER:
		get_viewport().set_input_as_handled()
		GameManager.return_to_menu()


func _reset_attempt() -> void:
	# Reposiciona os atores sem reiniciar a fase.
	player.reset_position()
	ball.reset_position()


func _on_state_changed(value: int) -> void:
	# Remove projéteis e power-ups fora do estado PLAYING.
	if value != GameManager.State.PLAYING:
		for group in ["projectiles", "powerups"]:
			for node in get_tree().get_nodes_in_group(group):
				node.queue_free()


func _on_sector_cleared() -> void:
	# Evita iniciar mais de uma transição.
	if wave_pending:
		return

	wave_pending = true

	# Aguarda o fim do processamento de colisões.
	_start_next_sector.call_deferred()


func _start_next_sector() -> void:
	# Oculta a bola durante a transição.
	ball.visible = false
	await get_tree().create_timer(1.3).timeout

	if not is_inside_tree() or GameManager.state != GameManager.State.READY:
		return

	# Remove a formação anterior de blocos.
	var old_blocks := get_node("Blocks")
	remove_child(old_blocks)
	old_blocks.queue_free()

	# Carrega uma nova formação a partir da cena original.
	var source: Node = load("res://Scenes/level_1.tscn").instantiate()
	var new_blocks: Node2D = source.get_node("Blocks")
	source.remove_child(new_blocks)
	source.free()
	add_child(new_blocks)

	# Atualiza os blocos e prepara a próxima tentativa.
	GameManager.configure_blocks(get_tree().get_nodes_in_group("blocks").size())
	ball.timer_item_power_up.stop()
	_reset_attempt()
	GameManager.advance_level()

	# Atualiza o HUD e libera futuras transições.
	GameManager.state_changed.emit(GameManager.state)
	wave_pending = false
