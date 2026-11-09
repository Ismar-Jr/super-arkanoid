## Constrói os trilhos e coordena lançador, drenagem, alvos e novas bolas.
extends Node2D

const Layout = preload("res://Scripts/Pinball/table_layout.gd")
const ScorePopup = preload("res://Scripts/Pinball/score_popup.gd")
const Sling = preload("res://Scripts/Pinball/slingshot.gd")
@onready var ball: RigidBody2D = $Ball
@onready var respawn_timer: Timer = $TimerRespawn
var charging: bool = false
var _bank_complete: bool = false
var _lane_lights: Array[bool] = [false, false, false]
var _lane_bank_complete: bool = false
var _lane_timer: Timer


func _ready() -> void:
	_build_rails()
	_build_sling(Layout.SLING_LEFT, false)
	_build_sling(Layout.SLING_RIGHT, true)
	_build_rollovers()
	$Drain.body_entered.connect(drain_ball)
	respawn_timer.timeout.connect(_on_respawn_timeout)
	$TimerTargets.timeout.connect(_reset_targets)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.sector_cleared.connect(_on_reactor_complete)
	reset_ball()


func _physics_process(delta: float) -> void:
	# O lançador depende da posição da bola, inclusive durante uma partida em andamento.
	if can_launch():
		if Input.is_action_pressed("Start") and not charging:
			charging = true
			GameManager.set_launch_charge(0.1)
		if charging and Input.is_action_pressed("Start"):
			GameManager.set_launch_charge(GameManager.launch_charge + delta / 0.9)
		if charging and Input.is_action_just_released("Start"):
			launch_ball(GameManager.launch_charge)
	elif charging:
		charging = false
		GameManager.set_launch_charge(0.0)
	if GameManager.started:
		if ball.position.y > Layout.SIZE.y + 20 or ball.position.x < -30 or ball.position.x > 670:
			drain_ball(ball)
	queue_redraw()


func can_launch() -> bool:
	if GameManager.ready_locked or not ball.visible:
		return false
	if GameManager.state == GameManager.State.READY:
		return true
	return GameManager.started and ball.position.x > 572 and ball.position.x < 604 \
		and ball.position.y > 800 and ball.position.y < 865


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and GameManager.state != GameManager.State.GAME_OVER:
		get_viewport().set_input_as_handled()
		GameManager.return_to_menu()


func launch_ball(power: float = 0.65) -> bool:
	if not can_launch():
		return false
	if GameManager.state == GameManager.State.READY and not GameManager.launch_ball():
		return false
	charging = false
	var strength := clampf(power, 0.25, 1.0)
	# A mesa alta precisa de energia suficiente para alcançar o arco superior.
	ball.launch(Vector2(-18, -(1180 + 360 * strength)))
	GameManager.set_launch_charge(0.0)
	AudioManager.play_sfx(&"iniciar")
	return true


func reset_ball() -> void:
	charging = false
	GameManager.set_launch_charge(0.0)
	ball.reset_to(to_global(Layout.SPAWN))


func drain_ball(body: Node2D) -> void:
	if body != ball or not GameManager.lose_life():
		return
	# A Area2D pode emitir durante a física; a mudança de freeze é adiada.
	ball.set_deferred("freeze", true)
	ball.set_deferred("linear_velocity", Vector2.ZERO)
	ball.visible = false
	charging = false
	GameManager.set_launch_charge(0.0)
	if GameManager.lives > 0:
		respawn_timer.start()


func _on_respawn_timeout() -> void:
	if GameManager.state != GameManager.State.READY or GameManager.lives <= 0:
		return
	reset_ball()
	GameManager.ready_locked = false
	GameManager.state_changed.emit(GameManager.state)


func _on_state_changed(value: int) -> void:
	if value != GameManager.State.PLAYING:
		charging = false
		GameManager.set_launch_charge(0.0)
		ball.set_deferred("freeze", true)
	if value in [GameManager.State.MAIN_MENU, GameManager.State.GAME_OVER]:
		respawn_timer.stop()
		$TimerTargets.stop()
		_lane_timer.stop()


func on_target_lit(_id: int) -> void:
	if _bank_complete:
		return
	for target in get_tree().get_nodes_in_group("pinball_targets"):
		if not target.lit:
			return
	_bank_complete = true
	GameManager.add_score(1000)
	AudioManager.play_sfx(&"setor")
	show_points(to_global(Vector2(250, 438)), "BONUS +%d" % (1000 * GameManager.multiplier))
	$TimerTargets.start()


func _reset_targets() -> void:
	for target in get_tree().get_nodes_in_group("pinball_targets"):
		target.reset_target()
	_bank_complete = false


func _on_reactor_complete() -> void:
	show_points(to_global(Vector2(310, 570)), "REATOR %dX" % GameManager.multiplier)


func _build_rollovers() -> void:
	_lane_timer = Timer.new()
	_lane_timer.name = "TimerLanes"
	_lane_timer.wait_time = 1.4
	_lane_timer.one_shot = true
	_lane_timer.timeout.connect(func():
		_lane_lights.assign([false, false, false])
		_lane_bank_complete = false)
	add_child(_lane_timer)
	for index in Layout.ROLLOVERS.size():
		var lane := Area2D.new()
		lane.name = "Rollover%d" % index
		lane.position = Layout.ROLLOVERS[index]
		lane.collision_layer = 0
		lane.collision_mask = 128
		var shape := RectangleShape2D.new()
		shape.size = Vector2(58, 18)
		var collision := CollisionShape2D.new()
		collision.shape = shape
		lane.add_child(collision)
		lane.body_entered.connect(_on_rollover.bind(index))
		add_child(lane)


func _on_rollover(body: Node2D, index: int) -> void:
	if body != ball or not GameManager.started or _lane_lights[index] or _lane_bank_complete:
		return
	_lane_lights[index] = true
	GameManager.add_score(150)
	AudioManager.play_sfx(&"coleta")
	if _lane_lights.all(func(lit: bool): return lit):
		_lane_bank_complete = true
		GameManager.add_score(750)
		GameManager.hit_reactor()
		show_points(to_global(Vector2(310, 160)), "ORBITA COMPLETA")
		_lane_timer.start()


func show_points(point: Vector2, value: String) -> void:
	var popup := Node2D.new()
	popup.set_script(ScorePopup)
	popup.text = value
	popup.z_index = 8
	add_child(popup)
	popup.global_position = point


func _build_rails() -> void:
	var rails := StaticBody2D.new()
	rails.name = "Rails"
	rails.collision_layer = 256
	rails.collision_mask = 128
	var material := PhysicsMaterial.new()
	material.bounce = 0.75
	material.friction = 0.08
	rails.physics_material_override = material
	add_child(rails)
	_add_rail_shapes(rails, Layout.OUTER)
	for index in Layout.GUIDES.size():
		if index != 1:
			_add_rail_shapes(rails, Layout.GUIDES[index])
	# A base da mola absorve o rebote para a bola repousar e aceitar outra carga.
	var floor_body := StaticBody2D.new()
	floor_body.name = "LauncherFloor"
	floor_body.collision_layer = 256
	floor_body.collision_mask = 128
	var cushion := PhysicsMaterial.new()
	cushion.bounce = 1.0
	cushion.absorbent = true
	cushion.friction = 0.8
	floor_body.physics_material_override = cushion
	add_child(floor_body)
	_add_rail_shapes(floor_body, Layout.GUIDES[1])
	for divider in Layout.TOP_DIVIDERS:
		_add_rail_shapes(rails, divider)


func _add_rail_shapes(parent: Node2D, points: PackedVector2Array) -> void:
	for index in range(points.size() - 1):
		var segment := points[index + 1] - points[index]
		# Cápsulas curtas evitam falsos contatos do CCD nos trilhos verticais longos.
		var pieces := maxi(1, ceili(segment.length() / 120.0))
		for piece in pieces:
			var start := points[index] + segment * float(piece) / pieces
			var end := points[index] + segment * float(piece + 1) / pieces
			var shape := CapsuleShape2D.new()
			shape.radius = 4.0
			shape.height = start.distance_to(end) + 8.0
			var collision := CollisionShape2D.new()
			collision.shape = shape
			collision.position = (start + end) / 2
			collision.rotation = segment.angle() - PI / 2
			parent.add_child(collision)


func _build_sling(points: PackedVector2Array, right_side: bool) -> void:
	var body := StaticBody2D.new()
	body.set_script(Sling)
	body.right_side = right_side
	body.name = "RightSlingshot" if right_side else "LeftSlingshot"
	body.collision_layer = 256
	body.collision_mask = 128
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	_draw_rail(Layout.OUTER)
	for guide in Layout.GUIDES:
		_draw_rail(guide)
	for divider in Layout.TOP_DIVIDERS:
		_draw_rail(divider)
	for points in [Layout.SLING_LEFT, Layout.SLING_RIGHT]:
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, Color("e84b4e"), 4, true)
	# A mola acompanha a carga, mantendo o canal de lançamento legível.
	var spring_top := 859 + GameManager.launch_charge * 8
	for index in range(5):
		draw_line(Vector2(581, spring_top + index * 2), Vector2(599, spring_top + index * 2), Color("ced7d8"), 1, true)
	for pivot in Layout.FLIPPERS:
		draw_circle(pivot, 13, Color("c1a77b"), true, -1, true)
		draw_circle(pivot, 7, Color("1c2630"), true, -1, true)
	for index in Layout.ROLLOVERS.size():
		var point: Vector2 = Layout.ROLLOVERS[index] + Vector2(0, 18)
		var color := Color("ffe09a") if _lane_lights[index] else Color("42666c")
		draw_circle(point, 7, Color("101b25"), true, -1, true)
		draw_circle(point, 4.5, color, true, -1, true)
		if _lane_lights[index]:
			draw_circle(point, 11, Color(color, 0.15), true, -1, true)
	var targets := [$TargetLeft, $TargetCenter, $TargetRight]
	for index in targets.size():
		var point := Vector2(166, 390 + index * 48)
		var color := Color("ffd68a") if targets[index].lit else Color("344c51")
		draw_circle(point, 8, color, true, -1, true)
	# Insertos acesos representam o bônus real e a bola atualmente em jogo.
	for index in 5:
		var point := Vector2(250 + index * 30, 666)
		var lit := index < GameManager.multiplier
		var color := Color("ffc774") if lit else Color("234149")
		draw_circle(point, 8.5, color, true, -1, true)
		if lit:
			draw_circle(point, 15, Color(color, 0.12), true, -1, true)
		draw_string(ThemeDB.fallback_font, point + Vector2(-3, 3.5), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("13222b") if lit else Color("96a7a2"))
	var play_light := Color("ffe7a2") if GameManager.started else Color("3a4146")
	draw_circle(Vector2(310, 751), 8.5, play_light, true, -1, true)


func _draw_rail(points: PackedVector2Array) -> void:
	draw_polyline(points, Color("0b111c"), 12, true)
	draw_polyline(points, Color("52636b"), 8, true)
	draw_polyline(points, Color("b6c8c8"), 5, true)
	draw_polyline(points, Color("f0efdc"), 1.4, true)
