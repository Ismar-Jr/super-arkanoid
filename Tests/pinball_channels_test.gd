## Regressão dos canais inferiores: a esfera deve passar entre a borracha e a guia.
extends SceneTree

const Layout = preload("res://Scripts/Pinball/table_layout.gd")

var manager: Node
var audio: Node
var table: Node2D
var ball: RigidBody2D
var failures: Array[String] = []
var checks: int = 0
var records_path: String


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)


func _run() -> void:
	manager = root.get_node("GameManager")
	audio = root.get_node("AudioManager")
	records_path = "/private/tmp/pinball-channels-%d.cfg" % OS.get_process_id()
	manager.records_path = records_path
	await _open_table()
	_verify_clearances()
	# Testa entradas diferentes, mantendo o raio e a gravidade reais da partida.
	for mirrored in [false, true]:
		for offset in [0.0, 4.0, 8.0]:
			await _cross_channel(mirrored, offset)
	ball.freeze = true
	if FileAccess.file_exists(records_path):
		DirAccess.remove_absolute(records_path)
	print("CHANNELS RESULT: %d checks, %d failures" % [checks, failures.size()])
	audio.quit_game(0 if failures.is_empty() else 1)


func _open_table() -> void:
	manager.new_game()
	for index in 5:
		await process_frame
	table = current_scene.get_node("Table")
	ball = table.get_node("Ball")
	table.launch_ball(0.5)


func _cross_channel(mirrored: bool, offset: float) -> void:
	# Uma mesa nova isola o caso mesmo se a tentativa anterior terminar em drenagem.
	await _open_table()
	# Espelha só a entrada; a travessia depende das colisões, sem teleporte ou impulso de ajuda.
	var start := Vector2(84 + offset, 750)
	var velocity := Vector2(35, 110)
	if mirrored:
		# A guia direita avança 12 px para dentro; a entrada deve ficar fora dela.
		start.x = 620 - start.x - 12
		velocity.x = -velocity.x
	ball.reset_to(table.to_global(start))
	await physics_frame
	await physics_frame
	ball.launch(velocity)
	var triangle: PackedVector2Array = Layout.SLING_RIGHT if mirrored else Layout.SLING_LEFT
	var bottom := -INF
	for vertex in triangle:
		bottom = maxf(bottom, vertex.y)
	# A esfera inteira deve sair abaixo do triângulo, respeitando as duas trajetórias.
	var exit_y: float = bottom + ball.get_node("CollisionShape2D").shape.radius + 2.0
	var crossed := false
	var max_y := start.y
	var elapsed := 0.0
	while elapsed < 3.0 and manager.started:
		await physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
		max_y = maxf(max_y, ball.position.y)
		var inward_x: float = 620 - ball.position.x if mirrored else ball.position.x
		if ball.position.y > exit_y and inward_x > 130 and inward_x < 218:
			crossed = true
			break
	ball.freeze = true
	var side := "direito" if mirrored else "esquerdo"
	print("CHANNEL TRACE ", side, " offset=", offset, " max_y=", max_y,
		" final=", ball.position, " elapsed=", elapsed)
	check(crossed, "canal %s permite a passagem da bola, entrada %.0f" % [side, offset])


func _verify_clearances() -> void:
	var ball_diameter: float = ball.get_node("CollisionShape2D").shape.radius * 2.0
	var rail_radius: float = table.get_node("Rails").get_child(0).shape.radius
	var minimum_required := ball_diameter + 8.0
	for index in 2:
		var triangle: PackedVector2Array = Layout.SLING_LEFT if index == 0 else Layout.SLING_RIGHT
		var guide: PackedVector2Array = Layout.GUIDES[index + 2]
		var gap := _minimum_distance(triangle, guide) - rail_radius
		var side := "esquerdo" if index == 0 else "direito"
		print("CHANNEL CLEARANCE ", side, " free=", gap, " required=", minimum_required)
		check(gap >= minimum_required, "canal %s tem folga para a esfera e margem de 8 px" % side)


func _minimum_distance(polygon: PackedVector2Array, guide: PackedVector2Array) -> float:
	var result := INF
	for first in polygon.size():
		var a := polygon[first]
		var b := polygon[(first + 1) % polygon.size()]
		for second in range(guide.size() - 1):
			var c := guide[second]
			var d := guide[second + 1]
			if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
				return 0.0
			result = minf(result, a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)))
			result = minf(result, b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d)))
			result = minf(result, c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)))
			result = minf(result, d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b)))
	return result
