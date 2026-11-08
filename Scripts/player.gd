
extends CharacterBody2D

# Configurações de movimento e disparos.
@export var speed = 400
@onready var spawn_shoot_timer: Timer = $SpawnShootTimer

var bullet_scene = preload("res://Scenes/bullet.tscn")
var max_bullet: int = 16
var current_bullet: int = 0

# Controla a animação dos propulsores.
var light_time: float = 0.0


func _ready() -> void:
	# Conecta os eventos de power-up e estado da partida.
	GameManager.on_powerup.connect(spawn_bullet)
	GameManager.state_changed.connect(_on_state_changed)


func _physics_process(delta: float) -> void:
	velocity.x = 0

	# Permite movimento apenas durante a partida.
	if GameManager.started:
		if Input.is_action_pressed("left"):
			velocity.x -= speed

		if Input.is_action_pressed("right"):
			velocity.x += speed

		move_and_collide(velocity * delta)

	# Atualiza os efeitos visuais.
	light_time += delta
	queue_redraw()


func _draw() -> void:
	# Desenha propulsores ao movimentar a plataforma.
	if absf(velocity.x) > 0:
		var side := -signf(velocity.x)
		var flicker := 4.0 + floorf(fmod(light_time * 30.0, 3.0)) * 2.0

		draw_rect(
			Rect2(Vector2(side * 49.0 - 2, -3), Vector2(4, 6)),
			Color("9ffff3")
		)

		draw_line(
			Vector2(side * 49.0, 0),
			Vector2(side * (49.0 + flicker), 0),
			Color("38bcd0"),
			4
		)


func spawn_bullet() -> void:
	# Cancela disparos fora do estado PLAYING.
	if not GameManager.started:
		reset_state()
		return

	# Reproduz o som do laser.
	AudioManager.play_sfx(&"laser")

	# Cria o projétil esquerdo.
	var left_shoot_instance = bullet_scene.instantiate()
	get_parent().add_child(left_shoot_instance)
	left_shoot_instance.global_position = global_position + Vector2(-40, -5)

	# Cria o projétil direito.
	var right_shoot_instance = bullet_scene.instantiate()
	get_parent().add_child(right_shoot_instance)
	right_shoot_instance.global_position = global_position + Vector2(40, -40)

	# Atualiza a quantidade de projéteis gerados.
	current_bullet += 2
	GameManager.set_power_up(max_bullet - current_bullet)

	# Continua a sequência até atingir o limite.
	if current_bullet < max_bullet:
		spawn_shoot_timer.start()
	else:
		spawn_shoot_timer.stop()
		current_bullet = 0


func reset_state() -> void:
	# Cancela os disparos e restaura o estado da plataforma.
	spawn_shoot_timer.stop()
	current_bullet = 0
	velocity = Vector2.ZERO
	GameManager.set_power_up(0)


func reset_position() -> void:
	# Reposiciona a plataforma após perder uma vida.
	reset_state()
	position = Vector2(320, 442)


func _on_state_changed(value: int) -> void:
	# Cancela os disparos fora da partida.
	if value != GameManager.State.PLAYING:
		reset_state()


func _on_spawn_shoot_timeout() -> void:
	# Gera a próxima dupla de disparos.
	spawn_bullet()
