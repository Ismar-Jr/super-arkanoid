
extends Node2D

# Configurações visuais do efeito.
var tint: Color = Color.WHITE
var large: bool = false
var age: float = 0.0
var directions: Array[Vector2] = []


# Cria o efeito na posição do impacto.
static func spawn(parent: Node, point: Vector2, color: Color, big: bool) -> void:
	var effect = load("res://Scripts/Effects/arcade_burst.gd").new()
	effect.tint = color
	effect.large = big
	parent.add_child(effect)
	effect.global_position = point


func _ready() -> void:
	z_index = 5

	# Distribui 4 ou 8 fragmentos em direções circulares.
	for index in range(8 if large else 4):
		directions.append(Vector2.from_angle(index * TAU / (8 if large else 4) + 0.3))


func _process(delta: float) -> void:
	age += delta

	# Remove o efeito após 0,35 segundo.
	if age > 0.35:
		queue_free()

	queue_redraw()


func _draw() -> void:
	# Calcula o deslocamento e a transparência dos fragmentos.
	var fade := clampf(1.0 - age / 0.35, 0.0, 1.0)

	for direction in directions:
		var point := direction * age * (95.0 if large else 50.0)

		# Simula a queda dos fragmentos.
		point.y += age * age * 45.0

		draw_rect(Rect2(point.round(), Vector2(4, 2) if large else Vector2(2, 2)), Color(tint, fade))

	# Desenha um brilho breve no centro do impacto.
	if age < 0.09:
		draw_line(Vector2(-6, 0), Vector2(6, 0), Color(tint, fade), 2)
		draw_line(Vector2(0, -6), Vector2(0, 6), Color(tint, fade), 2)
