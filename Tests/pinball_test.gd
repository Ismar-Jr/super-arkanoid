## Regressão do pinball com recorde e preferências isolados em arquivos temporários.
extends SceneTree

var manager: Node
var audio: Node
var failures: Array[String] = []
var checks: int = 0
var records_path: String
var audio_path: String


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)


func frames(count: int = 4) -> void:
	for index in count:
		await process_frame


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func click(button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)


func _run() -> void:
	root.size = Vector2i(960, 576)
	manager = root.get_node("GameManager")
	audio = root.get_node("AudioManager")
	check(manager.records_path == "user://pinball_records.cfg", "recorde separado do Arkanoid")
	records_path = "/private/tmp/pinball-record-%d.cfg" % OS.get_process_id()
	audio_path = "/private/tmp/pinball-audio-%d.cfg" % OS.get_process_id()
	manager.records_path = records_path
	audio.settings_path = audio_path
	manager.best_score = 0
	change_scene_to_file("res://Scenes/UI/main_menu.tscn")
	await frames()
	check(manager.state == manager.State.MAIN_MENU, "inicialização no menu")
	check(current_scene.get_node("MusicVolume") is HSlider and current_scene.get_node("SFXVolume") is HSlider,
		"controles independentes de áudio preservados")
	click(current_scene.get_node("HelpButton"))
	await frames()
	check(current_scene.get_node("HelpOverlay").visible and not manager.started, "manual abre sem iniciar a física")
	click(current_scene.get_node("HelpOverlay/BackButton"))
	await frames()
	current_scene.get_node("StartButton").grab_focus()
	key(KEY_ENTER, true)
	key(KEY_ENTER, false)
	await frames(6)
	check(current_scene.scene_file_path == "res://Scenes/Pinball/pinball.tscn", "Enter inicia a mesa de pinball")
	var table: Node2D = current_scene.get_node("Table")
	if table.get_script() == null:
		check(false, "script da mesa compilado")
		_finish()
		return
	var ball: RigidBody2D = table.get_node("Ball")
	var left: AnimatableBody2D = table.get_node("LeftFlipper")
	var right: AnimatableBody2D = table.get_node("RightFlipper")
	var ball_id := ball.get_instance_id()
	check(ball.freeze and manager.state == manager.State.READY and manager.lives == 3,
		"três bolas e esfera parada aguardando o lançador")
	check(ball.position.distance_to(Vector2(590, 426)) < 0.1 and table.position == Vector2(24, 64),
		"lançador e mesa nas posições previstas")
	check(ball.continuous_cd == RigidBody2D.CCD_MODE_CAST_SHAPE and ball.contact_monitor,
		"esfera usa detecção contínua e contatos físicos")
	check(ball.collision_layer == 128 and ball.collision_mask == 768, "camadas isoladas para a mesa nova")
	check(get_nodes_in_group("pinball_bumpers").size() == 3 and get_nodes_in_group("pinball_targets").size() == 3,
		"três bumpers e três alvos físicos")
	check(current_scene.get_node("HUD/Console/BallCount").text == "03"
		and current_scene.get_node("HUD/Console/Multiplier").text == "01X", "HUD inicial mostra bolas e multiplicador")
	# Segura e solta uma tecla real para exercitar o lançador, sem chamar seu método.
	key(KEY_SPACE, true)
	await create_timer(0.25).timeout
	check(manager.launch_charge > 0.2 and ball.freeze and not manager.started, "Espaço carrega sem lançar antecipadamente")
	await create_timer(0.9).timeout
	check(is_equal_approx(manager.launch_charge, 1.0), "força do lançador limitada a 100%")
	key(KEY_SPACE, false)
	await frames(2)
	check(manager.started and not ball.freeze and ball.linear_velocity.y < -600,
		"soltar Espaço lança a esfera com impulso vertical")
	check(is_zero_approx(manager.launch_charge), "lançamento zera a barra de força")
	await create_timer(0.8).timeout
	check(ball.position.x < 558, "arco superior conduz a bola do canal para a mesa")
	ball.reset_to(table.to_global(Vector2(310, 320)))
	ball.launch(Vector2.ZERO)
	await create_timer(0.1).timeout
	check(ball.linear_velocity.y > 40 and ball.position.y > 320, "gravidade acelera a bola para baixo")
	var before_score: int = manager.score
	ball.reset_to(table.to_global(Vector2(310, 278)))
	ball.launch(Vector2(0, -350))
	await create_timer(0.09).timeout
	check(manager.score > before_score and ball.linear_velocity.y > 100,
		"contato real com bumper pontua e rebate a esfera")
	ball.reset_to(table.to_global(Vector2(48, 200)))
	ball.launch(Vector2(-400, 0))
	await create_timer(0.065).timeout
	check(ball.linear_velocity.x > 0 and ball.position.x > 44, "trilho esquerdo rebate sem atravessamento")
	ball.reset_to(table.to_global(Vector2(255, 398)))
	ball.launch(Vector2(0, 40))
	await frames(3)
	key(KEY_A, true)
	await create_timer(0.075).timeout
	check(left.rotation_degrees < -20 and right.rotation_degrees < -20,
		"A aciona somente a palheta esquerda")
	check(ball.linear_velocity.y < -200, "palheta esquerda devolve fisicamente a bola para cima")
	key(KEY_A, false)
	await create_timer(0.1).timeout
	check(absf(left.rotation_degrees - 22) < 1, "soltar A recolhe a palheta esquerda")
	ball.reset_to(table.to_global(Vector2(365, 398)))
	ball.launch(Vector2(0, 40))
	await frames(3)
	key(KEY_D, true)
	await create_timer(0.075).timeout
	check(right.rotation_degrees > 20, "D aciona a palheta direita")
	check(ball.linear_velocity.y < -200, "palheta direita devolve fisicamente a bola para cima")
	key(KEY_D, false)
	await create_timer(0.1).timeout
	check(absf(right.rotation_degrees + 22) < 1, "soltar D recolhe a palheta direita")
	ball.freeze = true
	# Um alvo só pontua uma vez até a bancada completar e apagar suas luzes.
	var targets := get_nodes_in_group("pinball_targets")
	for target in targets:
		target.reset_target()
	var before_targets: int = manager.score
	var first: bool = targets[0].on_ball_contact(ball)
	var duplicate: bool = targets[0].on_ball_contact(ball)
	check(first and not duplicate, "alvo iluminado ignora outro impacto na mesma bancada")
	targets[1].on_ball_contact(ball)
	targets[2].on_ball_contact(ball)
	check(manager.score == before_targets + 1750 * manager.multiplier,
		"três alvos concedem pontos e bônus da bancada")
	await create_timer(1.5).timeout
	check(targets.all(func(target: Node): return not target.lit), "bancada volta a aceitar impactos após o bônus")
	manager.reactor_hits = 0
	manager.multiplier = 1
	var before_reactor: int = manager.score
	for index in 5:
		manager.hit_reactor()
	check(manager.reactor_hits == 0 and manager.multiplier == 2 and manager.score == before_reactor + 500,
		"cinco ativações completam reator, bônus e multiplicador")
	check(current_scene.get_node("HUD/Console/Multiplier").text == "02X",
		"HUD acompanha o multiplicador")
	var before_multiplier: int = manager.score
	manager.add_score(100)
	check(manager.score == before_multiplier + 200, "multiplicador aplicado à pontuação")
	for index in 25:
		manager.hit_reactor()
	check(manager.multiplier == 5, "multiplicador limitado a 5x")
	var record := ConfigFile.new()
	check(record.load(records_path) == OK and int(record.get_value("arcade", "hi_score", 0)) == manager.score,
		"recorde do pinball persistido no arquivo isolado")
	var saved_score: int = manager.score
	var music_id: int = audio.music.get_instance_id()
	var track: AudioStream = audio.music.stream
	ball.reset_to(table.to_global(Vector2(310, 463)))
	ball.launch(Vector2(0, 300))
	await create_timer(0.12).timeout
	check(manager.lives == 2 and manager.state == manager.State.READY and manager.ready_locked,
		"drenagem real desconta uma bola e bloqueia o lançador")
	table.drain_ball(ball)
	check(manager.lives == 2 and not table.launch_ball(), "mesma queda não desconta duas bolas nem permite relançamento")
	await create_timer(1.3).timeout
	check(ball.get_instance_id() == ball_id and ball.freeze and ball.visible
		and ball.position.distance_to(Vector2(590, 426)) < 0.1,
		"reposição reutiliza a mesma esfera no lançador")
	check(manager.score == saved_score and manager.multiplier == 5 and not manager.ready_locked,
		"nova bola preserva pontuação e multiplicador")
	check(audio.music.get_instance_id() == music_id and audio.music.stream == track and audio.music.playing,
		"música e player permanecem entre tentativas")
	check(current_scene.get_node("HUD/Console/BallCount").text == "02", "HUD mostra a bola perdida")
	table.launch_ball()
	table.drain_ball(ball)
	await create_timer(1.3).timeout
	check(manager.lives == 1, "segunda drenagem deixa uma bola")
	table.launch_ball()
	table.drain_ball(ball)
	await frames(5)
	check(manager.lives == 0 and manager.state == manager.State.GAME_OVER and ball.freeze,
		"terceira drenagem encerra a partida")
	check(table.get_node("TimerRespawn").is_stopped() and table.get_node("TimerTargets").is_stopped(),
		"Game Over interrompe temporizadores da mesa")
	check(not audio.music.playing and current_scene.get_node("HUD/GameOver").visible,
		"Game Over mostra resultado e encerra a música")
	var summary: Control = current_scene.get_node("HUD/GameOver/SummaryPanel")
	check(summary.get_node("FinalScore").text == "%08d" % saved_score, "tela final exibe a pontuação correta")
	click(summary.get_node("RetryButton"))
	await frames(6)
	check(manager.state == manager.State.READY and manager.lives == 3 and manager.score == 0
		and manager.multiplier == 1 and manager.reactor_hits == 0, "jogar novamente reinicia a partida inteira")
	check(manager.best_score == saved_score, "nova partida mantém o recorde")
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	await frames(6)
	check(manager.state == manager.State.MAIN_MENU and current_scene.scene_file_path.ends_with("main_menu.tscn"),
		"Esc retorna ao menu e descarrega a mesa")
	check(get_nodes_in_group("pinball_ball").is_empty(), "retorno ao menu remove a esfera física")
	_finish()


func _finish() -> void:
	for path in [records_path, audio_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("PINBALL RESULT: %d checks, %d failures" % [checks, failures.size()])
	audio.quit_game(0 if failures.is_empty() else 1)
