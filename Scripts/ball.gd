
extends CharacterBody2D

# Configurações de movimento da bola.
@export var y_speed = -250
@export var angle = [-200, -250, 250, 300]

# Configurações dos power-ups.
@export var drop_probability = 0.2
@export var item_scene = preload("res://Scenes/item_power_up.tscn")

@onready var timer_item_power_up = $TimerItemPowerUp


func _physics_process(delta):
	# Inicia a partida.
	if Input.is_action_pressed("Start") and !GameManager.started:
		play_game()

	if GameManager.started:
		var collision = move_and_collide(velocity * delta)

		if collision != null:
			# Reflete a bola após a colisão.
			velocity = velocity.bounce(collision.get_normal())
			var collided_object = collision.get_collider()

			if "Block" in collided_object.name:
				# Destrói o bloco e tenta gerar um power-up.
				collided_object.queue_free()
				spawn_item(collision.get_position())


func play_game():
	# Inicia a partida com direção horizontal aleatória.
	GameManager.started = true
	velocity = Vector2(angle.pick_random(), y_speed)


func spawn_item(position_item: Vector2):
	# Sorteia o drop com 20% de probabilidade.
	if randf() < drop_probability:

		# Impede novos drops durante a contagem do Timer.
		if timer_item_power_up.is_stopped():
			var item = item_scene.instantiate()
			item.position = position_item
			get_parent().add_child(item)

			# Inicia o intervalo entre power-ups.
			timer_item_power_up.start()

	# Exibe o estado e o tempo restante para depuração.
	print("Timer parado: ", timer_item_power_up.is_stopped(),
		" | Tempo restante: ", timer_item_power_up.time_left)
