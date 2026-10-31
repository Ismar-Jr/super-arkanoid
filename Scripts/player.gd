
extends CharacterBody2D

# Velocidade de movimentação horizontal da plataforma.
@export var speed = 400


func _physics_process(delta):

	# Zera a velocidade horizontal para parar quando nenhuma tecla estiver pressionada.
	velocity.x = 0

	# Movimenta para a esquerda somente durante a partida.
	if Input.is_action_pressed("left") and GameManager.started:
		velocity.x -= speed

	# Movimenta para a direita somente durante a partida.
	if Input.is_action_pressed("right") and GameManager.started:
		velocity.x += speed

	# Aplica o deslocamento considerando o tempo e as colisões.
	move_and_collide(velocity * delta)
