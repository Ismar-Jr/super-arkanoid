## Constrói os trilhos e coordena lançador, drenagem, alvos e novas bolas.
extends Node2D

const Layout = preload("res://Scripts/Pinball/table_layout.gd")
const ScorePopup = preload("res://Scripts/Pinball/score_popup.gd")
const Sling = preload("res://Scripts/Pinball/slingshot.gd")
@onready var ball: RigidBody2D = $Ball
@onready var respawn_timer: Timer = $TimerRespawn
var charging: bool = false
var _launcher_wait: float = 0.0
var _bank_complete: bool = false


func _ready() -> void:
	_build_rails()
	_build_sling(Layout.SLING_LEFT, false)
	_build_sling(Layout.SLING_RIGHT, true)
	$Drain.body_entered.connect(drain_ball)
	respawn_timer.timeout.connect(_on_respawn_timeout)
	$TimerTargets.timeout.connect(_reset_targets)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.sector_cleared.connect(_on_reactor_complete)
	reset_ball()


func _physics_process(delta: float) -> void:
	if GameManager.state == GameManager.State.READY and not GameManager.ready_locked:
		if Input.is_action_just_pressed("Start"):
			charging = true
			GameManager.set_launch_charge(0.1)
		if charging and Input.is_action_pressed("Start"):
			GameManager.set_launch_charge(GameManager.launch_charge + delta / 0.9)
		if charging and Input.is_action_just_released("Start"):
			launch_ball(GameManager.launch_charge)
	elif GameManager.started:
		if ball.position.y > 500 or ball.position.x < -30 or ball.position.x > 670:
			drain_ball(ball)
		# Uma bola que voltou ao canal pode ser relançada sem descontar outra vida.
		if ball.position.x > 572 and ball.position.y > 417 and ball.linear_velocity.length() < 60:
			_launcher_wait += delta
			if _launcher_wait > 0.7:
				GameManager.ready_locked = false
				GameManager._set_state(GameManager.State.READY)
				reset_ball()
		else:
			_launcher_wait = 0.0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and GameManager.state != GameManager.State.GAME_OVER:
		get_viewport().set_input_as_handled()
		GameManager.return_to_menu()


func launch_ball(power: float = 0.65) -> bool:
	if not GameManager.launch_ball():
		return false
	charging = false
	var strength := clampf(power, 0.25, 1.0)
	ball.launch(Vector2(-18, -(820 + 260 * strength)))
	GameManager.set_launch_charge(0.0)
	AudioManager.play_sfx(&"iniciar")
	return true


func reset_ball() -> void:
	charging = false
	_launcher_wait = 0.0
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


func on_target_lit(_id: int) -> void:
	if _bank_complete:
		return
	for target in get_tree().get_nodes_in_group("pinball_targets"):
		if not target.lit:
			return
	_bank_complete = true
	GameManager.add_score(1000)
	AudioManager.play_sfx(&"setor")
	show_points(to_global(Vector2(310, 110)), "BONUS +%d" % (1000 * GameManager.multiplier))
	$TimerTargets.start()


func _reset_targets() -> void:
	for target in get_tree().get_nodes_in_group("pinball_targets"):
		target.reset_target()
	_bank_complete = false


func _on_reactor_complete() -> void:
	show_points(to_global(Vector2(310, 285)), "REATOR %dX" % GameManager.multiplier)


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
	for guide in Layout.GUIDES:
		_add_rail_shapes(rails, guide)


func _add_rail_shapes(parent: Node2D, points: PackedVector2Array) -> void:
	for index in range(points.size() - 1):
		var segment := points[index + 1] - points[index]
		var shape := CapsuleShape2D.new()
		shape.radius = 4.0
		shape.height = segment.length() + 8.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = (points[index] + points[index + 1]) / 2
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
	for points in [Layout.SLING_LEFT, Layout.SLING_RIGHT]:
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, Color("e894bd"), 3)
	# A mola acompanha a carga, mantendo o canal de lançamento legível.
	var spring_top := 439 + GameManager.launch_charge * 8
	for index in range(5):
		draw_line(Vector2(581, spring_top + index * 2), Vector2(599, spring_top + index * 2), Color("daaf76"), 1)
	for pivot in [Vector2(208, 405), Vector2(412, 405)]:
		draw_circle(pivot, 13, Color("52647c"))
		draw_circle(pivot, 7, Color("122439"))


func _draw_rail(points: PackedVector2Array) -> void:
	draw_polyline(points, Color("10182a"), 12)
	draw_polyline(points, Color("60778d"), 8)
	draw_polyline(points, Color("b2d2d5"), 2)
