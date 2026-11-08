## Borracha triangular que devolve a bola para o centro da mesa.
extends StaticBody2D

@export var right_side: bool = false
var _last_hit: int = -1000


func on_ball_contact(ball: Node2D) -> void:
	if not GameManager.started or not ball is RigidBody2D:
		return
	var now := Time.get_ticks_msec()
	if now - _last_hit < 180:
		return
	_last_hit = now
	ball.apply_central_impulse(Vector2(-170 if right_side else 170, -180))
	GameManager.add_score(50)
	AudioManager.play_sfx(&"rebote")
