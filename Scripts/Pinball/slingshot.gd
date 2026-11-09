## Borracha triangular que devolve a bola para o centro da mesa.
extends StaticBody2D

@export var right_side: bool = false
var _last_hit: int = -1000
var _flash: float = 0.0


func on_ball_contact(ball: Node2D) -> void:
	if not GameManager.started or not ball is RigidBody2D:
		return
	var now := Time.get_ticks_msec()
	if now - _last_hit < 180:
		return
	_last_hit = now
	_flash = 1.0
	ball.apply_central_impulse(Vector2(-170 if right_side else 170, -180))
	GameManager.add_score(50)
	AudioManager.play_sfx(&"rebote")


func _process(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = maxf(0.0, _flash - delta * 5.0)
	queue_redraw()


func _draw() -> void:
	if _flash > 0.0:
		var points: PackedVector2Array = get_child(0).polygon
		draw_colored_polygon(points, Color(1, 0.64, 0.3, _flash * 0.25))
