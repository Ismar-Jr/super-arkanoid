
extends SceneTree

# Teste de integração executado pelo Godot em modo headless.
# Comando: godot --headless --path . --script Tests/smoke_test.gd

# Gerenciador e resultados dos testes.
var manager: Node
var failures: Array[String] = []
var checks := 0
var emitted_bullets: Array[Node] = []
var record_path := ""


func _initialize() -> void:
	# Inicia os testes após a inicialização da árvore.
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	# Registra o resultado de cada verificação.
	checks += 1

	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)


func frames(count := 3) -> void:
	# Aguarda a quantidade solicitada de frames.
	for index in count:
		await process_frame


func find_button(node: Node, fragment: String) -> Button:
	# Procura botões pelo texto, incluindo nós filhos.
	if node is Button and fragment in node.text:
		return node

	for child in node.get_children():
		var found := find_button(child, fragment)
		if found != null:
			return found

	return null


func find_blocks(node: Node) -> Array[Node]:
	# Localiza recursivamente os blocos destrutíveis.
	var result: Array[Node] = []

	for child in node.get_children():
		if child.has_method("destroy"):
			result.append(child)

		result.append_array(find_blocks(child))

	return result


func track_bullet(node: Node) -> void:
	# Registra projéteis sem permitir colisões durante a contagem.
	if node.scene_file_path == "res://Scenes/bullet.tscn":
		emitted_bullets.append(node)
		node.set_physics_process(false)
		node.set_physics_process.call_deferred(false)
		node.monitoring = false


func click_button(button: Button) -> void:
	# Simula um clique do mouse na interface.
	var down := InputEventMouseButton.new()
	down.position = button.get_global_rect().get_center()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down, true)

	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)


func _run() -> void:
	# Configura o viewport e isola o arquivo de recordes.
	root.size = Vector2i(960, 576)
	manager = root.get_node("GameManager")
	record_path = "/private/tmp/super-arkanoid-smoke-%d.cfg" % OS.get_process_id()
	manager.records_path = record_path
	manager.best_score = 0

	# Carrega e verifica o menu principal.
	change_scene_to_file("res://Scenes/UI/main_menu.tscn")
	await frames()

	check(manager.state == manager.State.MAIN_MENU, "inicialização no menu principal")
	check(not manager.started, "compatibilidade started: menu não inicia a partida")

	var start := find_button(current_scene, "INICIAR JOGO")
	var how_to := find_button(current_scene, "COMO JOGAR")

	check(start != null and how_to != null and find_button(current_scene, "SAIR") != null,
		"menu oferece os três botões obrigatórios")

	if start == null:
		_finish()
		return

	check(start.focus_mode == Control.FOCUS_ALL, "botão inicial aceita foco de teclado")

	# Testa a abertura e o fechamento das instruções.
	if how_to != null:
		click_button(how_to)
		await frames()

		check(manager.state == manager.State.MAIN_MENU, "instruções mantêm o gameplay desativado")
		check(current_scene.get_node("HelpOverlay").visible, "botão COMO JOGAR exibe o manual")

		var back := find_button(current_scene, "VOLTAR")
		check(back != null, "instruções têm uma ação para voltar")

		if back != null:
			click_button(back)
			await frames()

	# Inicia a partida simulando a tecla Enter.
	start.grab_focus()

	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	root.push_input(enter, true)

	var enter_up := enter.duplicate() as InputEventKey
	enter_up.pressed = false
	root.push_input(enter_up, true)

	await frames(5)

	# Valida o estado inicial e as informações do HUD.
	check(current_scene.scene_file_path == "res://Scenes/main.tscn", "botão iniciar abre a cena integrada")
	check(manager.state == manager.State.READY and not manager.ready_locked,
		"partida nova aguarda o lançamento")
	check(manager.score == 0 and manager.lives == 3 and manager.level == 1,
		"partida nova reinicia pontuação, três vidas e fase")

	var hud: Node = current_scene.get_node("HUD")

	check(hud.get_node("Console/Score").text == "00000000"
		and hud.get_node("Console/LifeCount").text == "03",
		"HUD apresenta pontuação e vidas iniciais")

	var world: Node = current_scene.get_node("Level")

	if world.get_script() == null:
		check(false, "script da fase carregado sem erros de compilação")
		_finish()
		return

	var player: CharacterBody2D = world.get_node("Player")
	var ball: CharacterBody2D = world.get_node("Ball")
	var environment: Node = world.get_node("Environment")
	var initial_world_id := world.get_instance_id()

	check(world.position == Vector2(24, 64), "arena inteira recebe somente a translação da composição")
	check(find_blocks(world.get_node("Blocks")).size() == 48 and manager.blocks_remaining == 48,
		"48 blocos registrados no início")

	# Verifica se as mecânicas originais foram preservadas.
	_verify_invariants(world, player, ball)

	ball.play_game()

	# Interrompe a física para evitar colisões aleatórias.
	ball.set_physics_process(false)

	check(manager.state == manager.State.PLAYING and manager.started, "lançamento entra em PLAYING")
	check(ball.velocity.y == -250 and int(ball.velocity.x) in [-200, -250, 250, 300],
		"lançamento preserva as velocidades e a escolha horizontal original")

	# Testa a destruição de um bloco sem pontuação duplicada.
	var block: Node = find_blocks(world.get_node("Blocks"))[0]
	var first_hit: bool = block.destroy()
	var duplicate_hit: bool = block.destroy()

	check(first_hit and not duplicate_hit and manager.score == 100,
		"destruição concede 100 pontos uma única vez")

	await frames()

	check(manager.blocks_remaining == 47 and find_blocks(world.get_node("Blocks")).size() == 47,
		"destruição atualiza blocos restantes")

	check(manager.best_score == 100 and FileAccess.file_exists(record_path),
		"recorde atualizado e persistido em arquivo isolado")

	check(hud.get_node("Console/Score").text == "00000100"
		and hud.get_node("Console/BestScore").text == "00000100",
		"sinais atualizam SCORE e HI-SCORE imediatamente no HUD")

	# Verifica a gravação e recuperação do recorde.
	var saved := ConfigFile.new()

	check(saved.load(record_path) == OK and saved.get_value("arcade", "hi_score", -1) == 100,
		"arquivo de recorde pode ser relido pelo ConfigFile com o valor esperado")

	manager.best_score = 0
	manager.load_record()

	check(manager.best_score == 100, "recorde é restaurado do arquivo local")

	# Testa o power-up e a sequência de disparos.
	await _verify_power_up(world, player, ball)

	# Simula uma queda física na zona de morte.
	ball.position = Vector2(320, 475)
	ball.velocity = Vector2(0, 250)
	ball.set_physics_process(true)

	await create_timer(0.18).timeout

	check(manager.lives == 2 and manager.state == manager.State.READY,
		"queda física na DeathZone desconta uma vida")

	check(hud.get_node("Console/LifeCount").text == "02", "HUD exibe a vida descontada")

	# Verifica a proteção contra perda duplicada.
	environment._on_death_zone_body_entered(ball)

	check(manager.lives == 2 and manager.ready_locked, "mesma queda não desconta outra vida")

	manager.launch_ball()

	check(manager.state == manager.State.READY, "TimerReset bloqueia lançamento durante a reposição")

	check(player.get_node("SpawnShootTimer").is_stopped() and manager.power_up_shots == 0,
		"perda de vida encerra disparos e efeito ativo")

	# Aguarda o reposicionamento dos atores.
	await create_timer(2.1).timeout

	check(not manager.ready_locked and ball.velocity == Vector2.ZERO,
		"TimerReset libera uma nova tentativa com a bola parada")

	check(player.position == Vector2(320, 442) and ball.position.x == 320,
		"plataforma e bola retornam à posição inicial")

	check(world.get_instance_id() == initial_world_id and manager.score == 100
		and manager.blocks_remaining == 47,
		"perda de vida conserva fase, pontuação e blocos (score=%d, blocos=%d)" % [manager.score, manager.blocks_remaining])

	# Simula a perda da segunda vida.
	ball.play_game()
	ball.set_physics_process(false)
	environment._on_death_zone_body_entered(ball)

	check(manager.lives == 1, "segunda queda deixa uma vida")

	await create_timer(2.1).timeout

	# Simula a última perda de vida.
	ball.play_game()
	ball.set_physics_process(false)
	environment._on_death_zone_body_entered(ball)

	await frames()

	check(manager.lives == 0 and manager.state == manager.State.GAME_OVER,
		"terceira queda entra em GAME_OVER com zero vidas")

	# Confere a interrupção dos temporizadores.
	check(not manager.started and environment.get_node("TimerReset").is_stopped()
		and player.get_node("SpawnShootTimer").is_stopped()
		and ball.get_node("TimerItemPowerUp").is_stopped(), "Game Over interrompe os temporizadores")

	check(manager.score == 100 and manager.best_score == 100, "Game Over preserva pontuação final e recorde")

	check(hud.get_node("GameOver/SummaryPanel/FinalScore").text == "00000100"
		and hud.get_node("GameOver/SummaryPanel/BestScore").text == "00000100",
		"Game Over apresenta SCORE FINAL e HI-SCORE")

	# Localiza e testa o botão de nova partida.
	var replay := find_button(current_scene, "JOGAR NOVAMENTE")

	check(replay != null and replay.is_visible_in_tree(), "Game Over apresenta botão de nova partida")

	if replay != null:
		replay.pressed.emit()
		await frames(5)

		check(manager.state == manager.State.READY and manager.lives == 3 and manager.score == 0
			and manager.blocks_remaining == 48 and manager.power_up_shots == 0,
			"jogar novamente reinicia todos os estados da partida")

		check(manager.best_score == 100, "jogar novamente conserva o recorde")

		# Testa o avanço de fase e as colisões reais.
		await _verify_sector()
		await _verify_real_block_collisions()

	# Confirma o retorno ao menu principal.
	manager.return_to_menu()
	await frames(5)

	check(manager.state == manager.State.MAIN_MENU
		and current_scene.scene_file_path == "res://Scenes/UI/main_menu.tscn",
		"retorno ao menu troca a cena e o estado")

	check(not manager.started and manager.power_up_shots == 0, "menu não mantém efeitos da partida anterior")

	_finish()


func _verify_invariants(world: Node, player: CharacterBody2D, ball: CharacterBody2D) -> void:
	# Verifica os parâmetros originais da plataforma.
	check(player.speed == 400 and player.collision_layer == 1 and player.collision_mask == 34
		and player.get_node("CollisionShape2D").shape.size == Vector2(100, 24),
		"velocidade, hitbox e colisões da plataforma preservadas")

	# Verifica movimento e colisões da bola.
	check(ball.y_speed == -250 and ball.angle == [-200, -250, 250, 300]
		and ball.collision_layer == 2 and ball.collision_mask == 101
		and ball.get_node("CollisionShape2D").shape.size == Vector2(24, 24),
		"velocidades, hitbox e colisões da bola preservadas")

	# Confere a geração dos power-ups.
	check(ball.drop_probability == 0.2 and ball.get_node("TimerItemPowerUp").wait_time == 15.0,
		"probabilidade de 20% e intervalo de 15 segundos preservados")

	# Verifica a quantidade e a frequência dos disparos.
	check(player.max_bullet == 16 and player.get_node("SpawnShootTimer").wait_time == 0.2,
		"limite de 16 disparos e cadência de 0,2 segundo preservados")

	# Confere as dimensões e máscaras dos blocos.
	var block: Node = find_blocks(world.get_node("Blocks"))[0]

	check(block.collision_layer == 4 and block.collision_mask == 18
		and block.get_node("CollisionShape2D").shape.size == Vector2(80, 24)
		and block.get_node("CollisionShape2D").position == Vector2(40, 12),
		"tamanho e máscara dos blocos preservados")

	# Verifica as propriedades dos projéteis.
	var bullet: Area2D = load("res://Scenes/bullet.tscn").instantiate()

	check(bullet.speed == 400 and bullet.collision_layer == 16 and bullet.collision_mask == 4
		and bullet.get_node("CollisionShape2D").shape.radius == CircleShape2D.new().radius,
		"velocidade, raio e máscaras dos projéteis preservados")

	bullet.free()

	# Verifica as propriedades dos itens coletáveis.
	var item: CharacterBody2D = load("res://Scenes/item_power_up.tscn").instantiate()

	check(item.fall_speed == 80 and item.rotation_speed == 60
		and item.collision_layer == 8 and item.collision_mask == 65
		and item.get_node("CollisionShape2D").shape.radius == 13,
		"movimento, raio e máscaras do item preservados")

	item.free()


func _verify_power_up(world: Node, player: CharacterBody2D, ball: CharacterBody2D) -> void:
	# Monitora os projéteis criados durante o teste.
	node_added.connect(track_bullet)

	# Força o drop para testar o intervalo entre itens.
	ball.drop_probability = 1.0
	ball.spawn_item(player.global_position + Vector2(0, -26))
	ball.spawn_item(player.global_position + Vector2(0, -26))
	ball.drop_probability = 0.2

	var items: Array[Node] = []

	for child in world.get_children():
		if child.scene_file_path == "res://Scenes/item_power_up.tscn":
			items.append(child)

	check(items.size() == 1, "cooldown impede dois drops consecutivos")

	if items.is_empty():
		return

	# Simula a coleta do item.
	var item: CharacterBody2D = items[0]
	item.set_physics_process(false)

	await physics_frame
	await process_frame

	item._physics_process(0.02)

	check(emitted_bullets.size() == 2, "coleta por colisão inicia a primeira dupla de disparos")

	check(current_scene.get_node("HUD/Console/Power").text == "LASER ONLINE",
		"HUD indica o power-up ativo após a coleta")

	# Confere o posicionamento assimétrico dos lasers.
	if emitted_bullets.size() >= 2:
		check(emitted_bullets[0].global_position == player.global_position + Vector2(-40, -5)
			and emitted_bullets[1].global_position == player.global_position + Vector2(40, -40),
			"offsets assimétricos originais dos projéteis preservados")

	# Aguarda a conclusão da sequência de disparos.
	await create_timer(1.55).timeout

	check(emitted_bullets.size() == 16 and player.get_node("SpawnShootTimer").is_stopped()
		and manager.power_up_shots == 0, "power-up emite exatamente oito duplas e encerra o efeito")

	await create_timer(0.25).timeout

	check(emitted_bullets.size() == 16, "sequência não cria disparos extras")

	node_added.disconnect(track_bullet)


func _verify_sector() -> void:
	# Destrói a formação para testar a transição de setor.
	var world: Node = current_scene.get_node("Level")
	var ball: CharacterBody2D = world.get_node("Ball")

	ball.play_game()
	ball.set_physics_process(false)

	for block in find_blocks(world.get_node("Blocks")):
		block.destroy()

	check(manager.score == 4800 and manager.lives == 3 and manager.blocks_remaining == 0
		and manager.state == manager.State.READY and manager.ready_locked,
		"concluir os 48 blocos preserva vidas e bloqueia o lançamento durante a transição")

	ball.play_game()

	check(manager.state == manager.State.READY, "transição de setor rejeita lançamento antecipado")

	await create_timer(1.45).timeout

	check(manager.level == 2 and manager.blocks_remaining == 48
		and find_blocks(world.get_node("Blocks")).size() == 48,
		"setor seguinte incrementa LEVEL e restaura a formação completa")

	check(manager.lives == 3 and manager.score == 4800 and manager.state == manager.State.READY
		and not manager.ready_locked, "novo setor mantém pontuação e vidas e aguarda o jogador")

	check(current_scene.get_node("HUD/Console/Level").text == "02",
		"HUD acompanha a troca de setor")


func lowest_block(world: Node) -> Node2D:
	# Localiza o bloco mais próximo da parte inferior.
	var selected: Node2D

	for block in find_blocks(world.get_node("Blocks")):
		if selected == null or block.global_position.y > selected.global_position.y:
			selected = block

	return selected


func _verify_real_block_collisions() -> void:
	# Testa a colisão física da bola com um bloco.
	var world: Node = current_scene.get_node("Level")
	var ball: CharacterBody2D = world.get_node("Ball")

	ball.play_game()

	var target := lowest_block(world)
	var previous_score: int = manager.score

	ball.global_position = target.global_position + Vector2(40, 48)
	ball.velocity = Vector2(0, -250)
	ball.set_physics_process(true)

	await create_timer(0.14).timeout

	ball.set_physics_process(false)

	check(manager.score == previous_score + 100 and manager.blocks_remaining == 47
		and ball.velocity.y > 0, "colisão física da bola destrói um bloco, pontua e rebate")

	# Testa a colisão física de um projétil com outro bloco.
	ball.velocity = Vector2.ZERO
	target = lowest_block(world)

	var bullet: Area2D = load("res://Scenes/bullet.tscn").instantiate()
	world.add_child(bullet)

	var radius: float = bullet.get_node("CollisionShape2D").shape.radius
	bullet.global_position = target.global_position + Vector2(40, 24 + radius + 4)

	previous_score = manager.score

	await create_timer(0.14).timeout

	check(manager.score == previous_score + 100 and manager.blocks_remaining == 46
		and not is_instance_valid(bullet), "colisão física do projétil pontua e remove bloco e disparo")


func _finish() -> void:
	# Remove o arquivo de teste e apresenta o resultado.
	if FileAccess.file_exists(record_path):
		DirAccess.remove_absolute(record_path)

	print("SMOKE RESULT: %d checks, %d failures" % [checks, failures.size()])

	# Retorna zero para sucesso e um para falha.
	quit(0 if failures.is_empty() else 1)
