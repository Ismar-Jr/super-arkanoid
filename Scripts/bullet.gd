
extends Area2D

# Velocidade e controle do projétil.
@export var speed = 400
var spent: bool = false


func _ready() -> void:
	# Identifica o projétil no grupo global.
	add_to_group("projectiles")


func _physics_process(delta: float) -> void:
	# Remove o projétil quando a partida não está ativa.
	if not GameManager.started:
		queue_free()
		return

	# Movimenta o laser para cima.
	global_position.y -= speed * delta

	# Remove o projétil ao ultrapassar o limite superior.
	if position.y < -32:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Impede colisões duplicadas ou fora da partida.
	if spent or not GameManager.started:
		return

	# Destrói o bloco atingido e consome o projétil.
	if body.has_method("destroy"):
		spent = true
		body.destroy()
		queue_free()
