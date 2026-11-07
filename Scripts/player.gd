
extends CharacterBody2D

# Velocidade horizontal da plataforma, em pixels por segundo.
@export var speed = 400

# Referência ao Timer que controla o intervalo entre disparos.
@onready var spawn_shoot_timer = $SpawnShootTimer

# Carrega antecipadamente a cena dos projéteis.
var bullet_scene = preload("res://Scenes/bullet.tscn")

# Limite de projéteis gerados por ativação do power-up.
var max_bullet: int = 16

# Contador de projéteis gerados na sequência atual.
var current_bullet: int = 0


# Executada quando o nó está pronto na árvore de cenas.
func _ready():

	# Conecta o sinal global de power-up à função de disparo.
	GameManager.on_powerup.connect(spawn_bullet)


# Atualiza a movimentação a cada passo de física.
func _physics_process(delta):
	print("Você tem: ", GameManager.lives, " Vidas")
	# Zera a velocidade horizontal quando não há movimento.
	velocity.x = 0

	# Movimenta para a esquerda somente durante a partida.
	if Input.is_action_pressed("left") and GameManager.started:
		velocity.x -= speed

	# Movimenta para a direita somente durante a partida.
	if Input.is_action_pressed("right") and GameManager.started:
		velocity.x += speed

	# Aplica o deslocamento considerando o tempo e as colisões.
	move_and_collide(velocity * delta)


# Cria dois projéteis e controla a sequência de disparos.
func spawn_bullet():

	# Instancia o projétil esquerdo e adiciona à cena.
	var left_shoot_instance = bullet_scene.instantiate()
	get_parent().add_child(left_shoot_instance)

	# Posiciona o projétil à esquerda da plataforma.
	left_shoot_instance.global_position.x = global_position.x - 40
	left_shoot_instance.global_position.y = global_position.y - 05

	# Instancia o projétil direito e adiciona à cena.
	var right_shoot_instance = bullet_scene.instantiate()
	get_parent().add_child(right_shoot_instance)

	# Posiciona o projétil à direita da plataforma.
	right_shoot_instance.global_position.x = global_position.x + 40
	right_shoot_instance.global_position.y = global_position.y - 40

	# Soma os dois projéteis criados ao contador.
	current_bullet += 2

	# Continua disparando enquanto não atingir o limite.
	if (current_bullet < max_bullet):

		# Reinicia a contagem usando o Wait Time do Timer.
		spawn_shoot_timer.start()

	else:

		# Encerra os disparos e zera o contador.
		spawn_shoot_timer.stop()
		current_bullet = 0


# Executada quando o Timer emite o sinal timeout.
func _on_spawn_shoot_timeout():

	# Cria a próxima dupla de projéteis.
	spawn_bullet()
