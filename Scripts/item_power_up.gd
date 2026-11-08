
extends CharacterBody2D

# Efeito visual da coleta.
const Burst = preload("res://Scripts/Effects/arcade_burst.gd")

# Configurações de movimento.
@export var fall_speed: float = 80.0
@export var rotation_speed: float = 60.0

# Impede que o mesmo item seja coletado duas vezes.
var collected: bool = false


func _ready() -> void:
	# Registra o item no grupo de power-ups.
	add_to_group("powerups")


func _physics_process(delta: float) -> void:
	# Remove o item quando a partida não está ativa.
	if not GameManager.started:
		queue_free()
		return

	# Aplica a queda e a rotação.
	velocity.y = fall_speed
	rotation_degrees += rotation_speed * delta

	# Verifica a colisão durante o movimento.
	var collision := move_and_collide(velocity * delta)

	if collision != null:
		var body := collision.get_collider()

		# Ativa o power-up ao tocar a plataforma.
		if body.name == "Player" and not collected:
			collected = true

			# Exibe o efeito visual da coleta.
			Burst.spawn(get_parent(), global_position, Color("ffd779"), true)

			# Ativa os disparos e remove o item.
			GameManager.on_powerup.emit()
			queue_free()
