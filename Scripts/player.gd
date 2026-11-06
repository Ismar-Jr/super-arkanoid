
extends CharacterBody2D

# Velocidade horizontal da plataforma, em pixels por segundo.
@export var speed = 400

# Referência ao nó responsável pelo temporizador dos disparos.
@onready var spawn_shoot = $SpawnShoot

#pre-carregamento da cena bullet
var bullet_scene = preload("res://Scenes/bullet.tscn")

# Executada quando o nó está pronto na árvore de cenas.
func _ready():

	# Conecta o sinal global de power-up à função de disparo.
	GameManager.on_powerup.connect(spawn_bullet)


# Atualiza a movimentação a cada passo de física.
func _physics_process(delta):

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


# Inicia o temporizador responsável pelo ciclo de disparos.
func spawn_bullet():
	#tiro da esquerda
	var left_shoot_instance = bullet_scene.instantiate()
	get_parent().add_child(left_shoot_instance)
	left_shoot_instance.global_position.x = global_position.x - 40
	left_shoot_instance.global_position.y = global_position.y - 05
	
	#criando o tiro da direita
	var right_shoot_instance = bullet_scene.instantiate()
	get_parent().add_child(right_shoot_instance)
	right_shoot_instance.global_position.x = global_position.x + 40
	right_shoot_instance.global_position.y = global_position.y - 40
	
	# Inicia ou reinicia a contagem do temporizador.
	spawn_shoot.start()


# Chamada pelo sinal "again", caso esteja conectado.
func _on_spawn_shoot_again():

	# Reinicia o ciclo de disparos.
	spawn_bullet()
