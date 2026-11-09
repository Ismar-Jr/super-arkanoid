## Esfera física com gravidade, detecção contínua e um rastro apenas visual.
extends RigidBody2D

const Burst = preload("res://Scripts/Effects/arcade_burst.gd")
var trail: Array[Vector2] = []
var _trail_time: float = 0.0


func _ready() -> void:
	add_to_group("pinball_ball")
	body_entered.connect(_on_body_entered)


func reset_to(point: Vector2) -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = point
	visible = true
	trail.clear()
	queue_redraw()


func launch(launch_velocity: Vector2) -> void:
	freeze = false
	sleeping = false
	linear_velocity = launch_velocity


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Mantém impactos rápidos controláveis sem substituir a gravidade do motor.
	if state.linear_velocity.length() > 1600.0:
		state.linear_velocity = state.linear_velocity.normalized() * 1600.0


func _physics_process(delta: float) -> void:
	if freeze or not GameManager.started:
		return
	_trail_time += delta
	if _trail_time >= 0.025:
		_trail_time = 0.0
		trail.push_front(global_position)
		if trail.size() > 7:
			trail.pop_back()
	queue_redraw()


func _draw() -> void:
	if freeze:
		return
	for index in range(trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(index) / 7.0) * 0.22
		draw_circle(to_local(trail[index]), 3.0, Color(0.4, 0.9, 1.0, alpha))


func _on_body_entered(body: Node) -> void:
	if not GameManager.started:
		return
	if body.has_method("on_ball_contact"):
		body.on_ball_contact(self)
	else:
		AudioManager.play_sfx(&"rebote")
		Burst.spawn(get_parent(), global_position, Color("90ecf0"), false)
