
extends SceneTree

# Testa o encerramento do jogo pelo botão SAIR.


func _initialize() -> void:
	# Inicia o teste após a criação da árvore.
	_run.call_deferred()


func _run() -> void:
	# Abre o menu principal na resolução do jogo.
	root.size = Vector2i(720, 1120)
	change_scene_to_file("res://Scenes/UI/main_menu.tscn")

	# Aguarda o carregamento da interface.
	for index in 5:
		await process_frame

	# Localiza o botão SAIR.
	var button: Button = current_scene.get_node("QuitButton")

	# Simula o pressionamento do botão esquerdo do mouse.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = button.get_global_rect().get_center()
	press.pressed = true

	# Envia o clique à interface.
	root.push_input(press, true)

	# Simula a liberação do botão do mouse.
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false

	print("QUIT TEST: clique em SAIR enviado pela interface")
	root.push_input(release, true)

	# Se o jogo não encerrar, registra a falha.
	await create_timer(1.0).timeout
	push_error("QUIT TEST FAILED: aplicativo não encerrou após o clique")
	quit(1)
