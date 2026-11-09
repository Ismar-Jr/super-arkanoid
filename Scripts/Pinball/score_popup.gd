## Número de pontos breve, sem interferir na física da mesa.
extends Node2D

var _font: Font = ThemeDB.fallback_font
var text: String = ""
var age: float = 0.0


func _process(delta: float) -> void:
	age += delta
	position.y -= delta * 25
	modulate.a = clampf(1.0 - age / 0.8, 0.0, 1.0)
	if age > 0.8:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string_outline(_font, Vector2(-width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color("101725"))
	draw_string(_font, Vector2(-width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe29a"))
