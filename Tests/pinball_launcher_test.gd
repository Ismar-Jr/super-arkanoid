## Regressão do formato vertical e do lançador reutilizável, usando entrada real de teclado.
extends SceneTree

var manager: Node
var audio: Node
var table: Node2D
var ball: RigidBody2D
var failures: Array[String] = []
var checks := 0
var records_path: String
var audio_path: String


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)


func key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = pressed
	Input.parse_input_event(event)


func _open_table() -> void:
	manager.new_game()
	for index in 6:
		await process_frame
	table = current_scene.get_node("Table")
	ball = table.get_node("Ball")


func _place_ball(point: Vector2, velocity: Vector2) -> void:
	ball.reset_to(table.to_global(point))
	await physics_frame
	await physics_frame
	ball.launch(velocity)


func _run() -> void:
	root.size = Vector2i(720, 1120)
	manager = root.get_node("GameManager")
	audio = root.get_node("AudioManager")
	records_path = "/private/tmp/pinball-launcher-record-%d.cfg" % OS.get_process_id()
	audio_path = "/private/tmp/pinball-launcher-audio-%d.cfg" % OS.get_process_id()
	manager.records_path = records_path
	audio.settings_path = audio_path
	check(ProjectSettings.get_setting("display/window/size/viewport_height") >
		ProjectSettings.get_setting("display/window/size/viewport_width"), "viewport configurado na vertical")
	for charge_time in [0.01, 1.05]:
		await _open_table()
		if charge_time == 0.01:
			check(table.get_node("Rails").get_children().all(func(collision: CollisionShape2D):
				return collision.shape is CapsuleShape2D and collision.shape.height <= 128.0),
				"trilhos usam segmentos curtos para evitar colisões falsas do CCD")
		check(table.position == Vector2(40, 160) and ball.position == Vector2(590, 846),
			"mesa vertical e bola no lançador, carga %.2f s" % charge_time)
		key(true)
		await physics_frame
		await physics_frame
		await create_timer(charge_time).timeout
		key(false)
		await physics_frame
		await physics_frame
		var entered_field := false
		var top_y := ball.position.y
		var elapsed := 0.0
		while elapsed < 2.6 and manager.started:
			await physics_frame
			elapsed += 1.0 / Engine.physics_ticks_per_second
			top_y = minf(top_y, ball.position.y)
			if ball.position.x < 544 and ball.position.y > 170 and ball.position.y < 450:
				entered_field = true
				break
		print("LAUNCH TRACE charge=", charge_time, " top_y=", top_y, " final=", ball.position)
		check(entered_field, "lançamento com carga %.2f s alcança a curva e entra na mesa" % charge_time)
	await _open_table()
	table.launch_ball()
	manager.add_score(350)
	manager.multiplier = 2
	manager.reactor_hits = 3
	var saved_score: int = manager.score
	var ball_id := ball.get_instance_id()
	for attempt in 2:
		# Simula o retorno pelo canal; o piso físico deve guardar a bola sem descontar vida.
		await _place_ball(Vector2(590, 774), Vector2(0, 160))
		await create_timer(1.4).timeout
		check(manager.started and manager.lives == 3 and ball.position.x > 572 and ball.position.y > 800,
			"retorno %d permanece no canal sem perder uma bola" % (attempt + 1))
		check(table.can_launch(), "lançador continua disponível no retorno %d" % (attempt + 1))
		key(true)
		await create_timer(0.35).timeout
		check(manager.launch_charge > 0.3 and manager.started,
			"Espaço carrega o relançamento %d durante a partida" % (attempt + 1))
		key(false)
		await physics_frame
		await physics_frame
		check(ball.linear_velocity.y < -1000 and not ball.freeze,
			"soltar Espaço relança a bola que voltou, tentativa %d" % (attempt + 1))
		check(manager.score == saved_score and manager.multiplier == 2 and manager.reactor_hits == 3
			and manager.lives == 3 and ball.get_instance_id() == ball_id,
			"relançamento %d preserva bola, pontos e progresso" % (attempt + 1))
	# Segurar a tecla antes da chegada também arma a mola quando a bola alcança a base.
	await _place_ball(Vector2(590, 774), Vector2(0, 160))
	key(true)
	await create_timer(0.85).timeout
	check(manager.started and table.can_launch() and manager.launch_charge > 0.3,
		"Espaço já pressionado carrega assim que a bola retorna à base")
	key(false)
	await physics_frame
	await physics_frame
	check(ball.linear_velocity.y < -1000 and manager.lives == 3,
		"tecla segurada antes do retorno também permite relançar sem perder vida")
	await _place_ball(Vector2(310, 570), Vector2.ZERO)
	check(not table.can_launch(), "lançador ignora uma bola fora do canal")
	key(true)
	await create_timer(0.2).timeout
	key(false)
	await physics_frame
	check(is_zero_approx(manager.launch_charge) and ball.position.x < 558 and ball.position.y < 750,
		"Espaço no campo não teleporta a bola para o lançador")
	table.drain_ball(ball)
	check(manager.ready_locked and not table.can_launch() and not table.launch_ball(),
		"reposição após drenagem bloqueia lançamento antecipado")
	ball.freeze = true
	key(false)
	for path in [records_path, audio_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("LAUNCHER RESULT: %d checks, %d failures" % [checks, failures.size()])
	audio.quit_game(0 if failures.is_empty() else 1)
