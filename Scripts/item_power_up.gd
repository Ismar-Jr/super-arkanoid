
extends CharacterBody2D

# Velocidade vertical de queda do item, em pixels por segundo.
@export var fall_speed: float = 80.0

# Velocidade de rotação do item, em graus por segundo.
@export var rotation_speed: float = 60.0


# Atualiza a movimentação e a rotação a cada passo de física.
func _physics_process(delta: float) -> void:

	# Define a velocidade de queda constante.
	velocity.y = fall_speed

	# Aplica rotação contínua, ajustada pelo delta.
	rotation_degrees += rotation_speed * delta

	# Movimenta o item e verifica possíveis colisões.
	var collision = move_and_collide(velocity * delta)

	# Executa o tratamento somente se houver colisão.
	if collision != null:

		# Obtém uma referência ao objeto atingido.
		var collision_object = collision.get_collider()

		# Verifica se o nome do objeto contém "Player".
		if collision_object.name == "Player":

			# Agenda a remoção do item após a coleta.
			queue_free()

			# Exibe uma mensagem de teste no console do Godot.
			print("ativado")
