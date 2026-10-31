
extends CharacterBody2D

# Velocidade vertical inicial da bola (negativo = para cima).
@export var y_speed = -250

# Velocidades horizontais possíveis para o lançamento.
@export var angle = [-200, -250, 250, 300]

# Chance de 20% de gerar um item ao destruir um bloco.
@export var drop_probability = 0.2

# Carrega antecipadamente a cena do item coletável.
@export var item_scene = preload("res://Scenes/item_power_up.tscn")


# Executada a cada atualização de física.
func _physics_process(delta):

	# Inicia o jogo quando Start é pressionado.
	if Input.is_action_pressed("Start") and !GameManager.started:
		play_game()

	# A bola só se movimenta depois que o jogo começa.
	if GameManager.started:

		# Move a bola e retorna os dados da colisão, se houver.
		# delta ajusta o deslocamento ao tempo do passo de física.
		var collision = move_and_collide(velocity * delta)

		if collision != null:

			# Reflete a velocidade usando a normal da superfície atingida.
			velocity = velocity.bounce(collision.get_normal())

			# Identifica o objeto atingido pela bola.
			var collided_object = collision.get_collider()

			# Verifica se o objeto é um bloco destrutível.
			if "Block" in collided_object.name:

				# Agenda a remoção do bloco ao final do frame.
				collided_object.queue_free()

				# Tenta gerar um item na posição da colisão.
				spawn_item(collision.get_position())


# Inicia a partida e define a velocidade inicial da bola.
func play_game():

	# Atualiza o estado global da partida (Autoload).
	GameManager.started = true

	# Sorteia a velocidade horizontal e aplica a vertical.
	velocity = Vector2(angle.pick_random(), y_speed)


# Tenta criar um item coletável na posição informada.
func spawn_item(position_item: Vector2):

	# randf() sorteia um número entre 0 e 1.
	if randf() < drop_probability:

		# Cria uma instância da cena do coletável.
		var item = item_scene.instantiate()

		# Define a posição inicial do item.
		item.position = position_item

		# Adiciona o coletável à cena, como irmão da bola.
		get_parent().add_child(item)
