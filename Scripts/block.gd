
extends StaticBody2D

# Efeito visual de destruição.
const Burst = preload("res://Scripts/Effects/arcade_burst.gd")

# Pontuação e controle de destruição.
@export var points: int = 100
var destroyed: bool = false


func _ready() -> void:
	# Registra o bloco para o controle da fase.
	add_to_group("blocks")


func destroy() -> bool:
	# Impede destruição duplicada ou fora da partida.
	if destroyed or not GameManager.started:
		return false

	destroyed = true
	AudioManager.play_sfx(&"bloco")

	# Define a cor dos fragmentos conforme a fileira.
	var tint := Color("72eee0")

	match get_parent().name:
		"Red": tint = Color("ff887b")
		"Purple": tint = Color("de8ff5")
		"Yellow": tint = Color("ffe08b")
		"Blue": tint = Color("77b8fa")
		"Gray": tint = Color("c2cfe2")

	# Gera o efeito visual no centro do bloco.
	Burst.spawn(get_tree().current_scene, global_position + Vector2(40, 12), tint, true)

	# Atualiza a pontuação e remove o bloco.
	GameManager.add_block_score(points)
	queue_free()

	return true
