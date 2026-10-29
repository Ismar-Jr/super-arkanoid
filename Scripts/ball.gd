
# Herda CharacterBody2D, que permite movimentar
# objetos 2D e detectar colisões físicas.
extends CharacterBody2D


# Define a velocidade vertical inicial.
# Valores negativos movimentam o objeto para cima.
# @export permite alterar o valor pelo Inspector do Godot.
@export var y_speed = -250


# Lista de velocidades horizontais possíveis.
# Valores negativos representam movimento para a esquerda.
# Valores positivos representam movimento para a direita.
# Uma das velocidades será escolhida aleatoriamente.
@export var angle = [-200, -250, 250, 300]
@export var drop_probability = 0.2 # probabilidade de 20% de gerar um item
@export var item_scene = preload("res://Scenes/item_power_up.tscn")

# Executada automaticamente em intervalos fixos de física.
# delta representa o tempo decorrido entre atualizações.
func _physics_process(delta):

	# Verifica se a ação "Start" está pressionada
	# e se o jogo ainda não foi iniciado.
	#
	# GameManager é um script global (Autoload)
	# que armazena o estado de início do jogo.
	if Input.is_action_pressed("Start") and !GameManager.started:
		play_game()

	# Permite movimentar o objeto somente
	# depois que o jogo tiver sido iniciado.
	if GameManager.started:

		# Movimenta o objeto conforme sua velocidade.
		# Multiplicar por delta ajusta o deslocamento
		# ao tempo decorrido entre atualizações.
		#
		# move_and_collide() retorna informações
		# sobre a colisão, caso alguma aconteça.
		# Se não houver colisão, retorna null.
		var collision = move_and_collide(velocity * delta)

		# Verifica se aconteceu alguma colisão.
		if collision != null:

			# Calcula a nova direção após a colisão.
			#
			# get_normal() retorna o vetor normal
			# da superfície atingida.
			#
			# bounce() reflete a velocidade atual
			# em relação a essa normal, produzindo
			# o efeito de quicar.
			velocity = velocity.bounce(collision.get_normal())

			# Obtém a referência ao objeto
			# com o qual ocorreu a colisão.
			var collided_object = collision.get_collider()

			# Verifica se o nome do objeto atingido
			# contém a palavra "Block".
			#
			# Isso permite identificar os blocos
			# que podem ser destruídos pela bola.
			if "Block" in collided_object.name:

				# Agenda a remoção do bloco da cena.
				#
				# queue_free() não remove imediatamente:
				# o objeto é liberado ao final do frame.
				collided_object.queue_free()
				spawn_item(collision.get_position())
				


# Função responsável por iniciar o jogo
# e definir a velocidade inicial do objeto.
func play_game():

	# Atualiza o estado global do jogo.
	#
	# Como started pertence ao GameManager,
	# outros scripts também podem consultar
	# se o jogo já foi iniciado.
	GameManager.started = true

	# Define a velocidade inicial em dois eixos:
	#
	# X: escolhe aleatoriamente um valor de angle.
	# Y: utiliza o valor definido em y_speed.
	#
	# O resultado é um movimento inicial para cima,
	# com direção horizontal variável.
	velocity = Vector2(angle.pick_random(), y_speed)
	
func spawn_item(position_item : Vector2):
	#sorteara se havera a geracao de um item coletavel
	if randf() < drop_probability:
		#criar o item coletável
		var item = item_scene.instantiate() #instancia o item coletavel
		item.position = position_item #define a posicao do item coletavel
		get_parent().add_child(item) #adicione o item a cena
		
