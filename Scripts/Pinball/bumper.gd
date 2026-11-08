## Bumper eletromecânico: rebate, ilumina e conta uma ativação do reator.
extends StaticBody2D

const Burst = preload("res://Scripts/Effects/arcade_burst.gd")
@export var points: int = 100
@export var tint: Color = Color("7aece8")
var _last_hit: int = -1000
var _flash: float = 0.0


func _ready() -> void:
	add_to_group("pinball_bumpers")
	$Sensor.body_entered.connect(on_ball_contact)


func on_ball_contact(ball: Node2D) -> bool:
	if not GameManager.started or not ball is RigidBody2D:
		return false
	var now := Time.get_ticks_msec()
	if now - _last_hit < 140:
		return false
	_last_hit = now
	var direction := (ball.global_position - global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	# Garante uma saída radial sem acumular força enquanto o contato persiste.
	var impulse := maxf(0.0, 460.0 - ball.linear_velocity.dot(direction))
	ball.apply_central_impulse(direction * impulse)
	var awarded := points * GameManager.multiplier
	GameManager.add_score(points)
	GameManager.hit_reactor()
	AudioManager.play_sfx(&"bloco")
	Burst.spawn(get_parent(), ball.global_position, tint, true)
	get_parent().show_points(global_position + Vector2(0, -35), str(awarded))
	_flash = 1.0
	return true


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 4.0)
	queue_redraw()


func _draw() -> void:
	if _flash > 0:
		draw_arc(Vector2.ZERO, 28.0 + (1.0 - _flash) * 10.0, 0, TAU, 32, Color(tint, _flash), 2.0)
