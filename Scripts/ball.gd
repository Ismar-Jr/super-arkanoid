
extends CharacterBody2D

# Efeito visual de impacto.
const Burst = preload("res://Scripts/Effects/arcade_burst.gd")

# Configurações de movimento e power-ups.
@export var y_speed = -250
@export var angle = [-200, -250, 250, 300]
@export var drop_probability = 0.2
@export var item_scene = preload("res://Scenes/item_power_up.tscn")

@onready var timer_item_power_up: Timer = $TimerItemPowerUp

# Histórico de posições para o rastro luminoso.
var trail: Array[Vector2] = []
var trail_tick: float = 0.0


func _ready() -> void:
	# Monitora as mudanças de estado da partida.
	GameManager.state_changed.connect(_on_state_changed)


func _physics_process(delta: float) -> void:
	# Aguarda o comando para lançar a bola.
	if GameManager.state == GameManager.State.READY:
		if not GameManager.ready_locked and Input.is_action_just_pressed("Start"):
			play_game()
		return

	if not GameManager.started:
		return

	# Movimenta a bola e verifica colisões.
	var collision := move_and_collide(velocity * delta)

	if collision != null:
		velocity = velocity.bounce(collision.get_normal())

		# Cria o efeito visual no ponto de impacto.
		Burst.spawn(get_parent(), collision.get_position(), Color("8cf5f4"), false)

		var body := collision.get_collider()

		# Reproduz o som de rebote em superfícies comuns.
		if not body.has_method("destroy"):
			AudioManager.play_sfx(&"rebote")

		# Destrói o bloco e tenta gerar um power-up.
		if body.has_method("destroy") and body.destroy():
			spawn_item(collision.get_position())

	# Atualiza o rastro a cada 0,025 segundo.
	trail_tick += delta

	if trail_tick >= 0.025:
		trail_tick = 0.0
		trail.push_front(global_position)

		# Mantém apenas as seis posições mais recentes.
		if trail.size() > 6:
			trail.pop_back()

	queue_redraw()


func _draw() -> void:
	# Desenha o rastro com transparência progressiva.
	for index in range(trail.size() - 1, -1, -1):
		var strength := 1.0 - float(index) / 6.0

		draw_circle(
			to_local(trail[index]),
			2.0 + strength * 4.0,
			Color(0.3, 0.9, 1.0, strength * 0.22)
		)


func play_game() -> void:
	# Inicia a bola com direção horizontal aleatória.
	if GameManager.launch_ball():
		velocity = Vector2(angle.pick_random(), y_speed)
		AudioManager.play_sfx(&"iniciar")


func spawn_item(position_item: Vector2) -> void:
	# Respeita a probabilidade e o intervalo entre power-ups.
	if randf() < drop_probability and timer_item_power_up.is_stopped() and GameManager.started:
		var item = item_scene.instantiate()
		get_parent().add_child(item)

		# Posiciona o item no ponto de impacto.
		item.global_position = position_item
		timer_item_power_up.start()


func reset_position() -> void:
	# Reposiciona a bola e limpa seu rastro.
	velocity = Vector2.ZERO
	position = Vector2(320, 413)
	visible = true
	trail.clear()
	queue_redraw()


func _on_state_changed(value: int) -> void:
	# Interrompe a bola fora do estado PLAYING.
	if value != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		trail.clear()
		queue_redraw()

	# Preserva o Timer entre vidas e o cancela ao encerrar a partida.
	if value in [GameManager.State.MAIN_MENU, GameManager.State.GAME_OVER]:
		timer_item_power_up.stop()
