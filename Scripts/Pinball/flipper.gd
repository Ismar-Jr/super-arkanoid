## Pá articulada: o corpo animável transfere sua rotação à esfera física.
extends AnimatableBody2D

@export var right_side: bool = false
var pressed: bool = false
var _stroke_hits: Array[int] = []
@onready var sensor: Area2D = $StrikeZone


func _ready() -> void:
	add_to_group("pinball_flippers")
	rotation = deg_to_rad(-22.0 if right_side else 22.0)
	if right_side:
		$CollisionShape2D.position.x = -40
		$Sprite2D.position.x = -40
		$Sprite2D.flip_h = true
		$StrikeZone/CollisionShape2D.position.x = -40


func _physics_process(delta: float) -> void:
	var next_pressed := GameManager.started and Input.is_action_pressed("right" if right_side else "left")
	if next_pressed and not pressed:
		_stroke_hits.clear()
		AudioManager.play_sfx(&"laser")
	pressed = next_pressed
	var resting := deg_to_rad(-22.0 if right_side else 22.0)
	var raised := deg_to_rad(28.0 if right_side else -28.0)
	var target := raised if pressed else resting
	var swinging := pressed and absf(target - rotation) > 0.005
	rotation = move_toward(rotation, target, deg_to_rad(900.0) * delta)
	# Um impulso por golpe evita lançar a bola repetidamente ao segurar a tecla.
	if swinging:
		for ball in sensor.get_overlapping_bodies():
			on_ball_contact(ball)


func on_ball_contact(ball: Node2D) -> void:
	if not pressed or not GameManager.started or not ball is RigidBody2D:
		return
	if _stroke_hits.has(ball.get_instance_id()):
		return
	var raised := deg_to_rad(28.0 if right_side else -28.0)
	if absf(rotation - raised) < 0.004:
		return
	var point := to_local(ball.global_position)
	var direction := -1.0 if right_side else 1.0
	if absf(point.y) > 23 or point.x * direction < -16 or point.x * direction > 98:
		return
	_stroke_hits.append(ball.get_instance_id())
	var leverage := clampf(point.x * direction / 80.0, 0.15, 1.0)
	var desired := Vector2(direction * (120 + 200 * leverage), -(850 + 300 * leverage))
	ball.apply_central_impulse(desired - ball.linear_velocity)
