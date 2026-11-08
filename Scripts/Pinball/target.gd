## Alvo de uma bancada: cada luz só pontua novamente depois de completar o conjunto.
extends StaticBody2D

@export var target_id: int = 0
var lit: bool = false


func _ready() -> void:
	add_to_group("pinball_targets")
	$Sensor.body_entered.connect(on_ball_contact)


func on_ball_contact(_ball: Node2D) -> bool:
	if lit or not GameManager.started:
		return false
	lit = true
	$Sprite2D.modulate = Color("fff0a1")
	GameManager.add_score(250)
	AudioManager.play_sfx(&"coleta")
	get_parent().show_points(global_position + Vector2(0, 20), str(250 * GameManager.multiplier))
	get_parent().on_target_lit(target_id)
	return true


func reset_target() -> void:
	lit = false
	$Sprite2D.modulate = Color.WHITE
