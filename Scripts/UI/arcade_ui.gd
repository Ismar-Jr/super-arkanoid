
extends RefCounted
class_name ArcadeUI

# Fonte e paleta de cores da interface.
const FONT = preload("res://Assets/16bit/arcade.fnt")
const INK = Color("090f22")
const PANEL = Color("111b35")
const CYAN = Color("72e8df")
const AMBER = Color("ffcb76")
const WHITE = Color("dce9f2")
const MUTED = Color("8397b5")


# Cria textos padronizados sem bloquear o mouse.
static func label(parent: Node, value: String, rect: Rect2, size: int = 16, color: Color = WHITE, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result = Label.new()
	result.text = value
	result.position = rect.position
	result.size = rect.size
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = alignment
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


# Cria imagens com proporção preservada e pixels nítidos.
static func texture(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var result = TextureRect.new()
	result.texture = load(path)
	result.position = rect.position
	result.size = rect.size
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


# Define bordas, relevo e sombra dos componentes.
static func box_style(fill: Color, border: Color, thickness: int = 1) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(thickness)
	result.border_width_bottom = thickness + 2
	result.shadow_color = Color(0.015, 0.025, 0.055, 0.7)
	result.shadow_size = 4
	result.shadow_offset = Vector2(0, 4)
	return result


# Cria painéis com o estilo visual do arcade.
static func panel(parent: Node, rect: Rect2, color: Color = PANEL, border: Color = Color("435473")) -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.add_theme_stylebox_override("panel", box_style(color, border))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


# Cria divisórias e elementos decorativos.
static func line(parent: Node, rect: Rect2, color: Color = CYAN) -> ColorRect:
	var result = ColorRect.new()
	result.position = rect.position
	result.size = rect.size
	result.color = color
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


# Cria botões com aparência e interações padronizadas.
static func button(parent: Node, value: String, rect: Rect2) -> Button:
	var result = Button.new()
	result.text = value
	result.position = rect.position
	result.size = rect.size
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Configura fonte e cores dos estados do botão.
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override("font_color", WHITE)
	result.add_theme_color_override("font_hover_color", CYAN)
	result.add_theme_color_override("font_focus_color", CYAN)
	result.add_theme_color_override("font_pressed_color", AMBER)

	# Define os estilos normal, destacado e pressionado.
	result.add_theme_stylebox_override("normal", box_style(Color("18243f"), Color("475a7d")))
	result.add_theme_stylebox_override("hover", box_style(Color("213851"), CYAN, 2))
	result.add_theme_stylebox_override("pressed", box_style(Color("30404e"), AMBER, 2))

	# Destaca o botão selecionado pelo teclado ou mouse.
	var focus = StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = CYAN
	focus.set_border_width_all(2)
	result.add_theme_stylebox_override("focus", focus)

	parent.add_child(result)

	# Sincroniza o foco e reproduz os efeitos da interface.
	result.mouse_entered.connect(result.grab_focus)
	result.focus_entered.connect(func(): AudioManager.play_sfx(&"ui_move"))
	result.pressed.connect(func(): AudioManager.play_sfx(&"ui_confirm"))

	return result


# Organiza a navegação circular entre os botões.
static func focus_loop(buttons: Array[Button]) -> void:
	for index in buttons.size():
		var current = buttons[index]
		current.focus_neighbor_top = current.get_path_to(buttons[posmod(index - 1, buttons.size())])
		current.focus_neighbor_bottom = current.get_path_to(buttons[(index + 1) % buttons.size()])
		current.focus_next = current.focus_neighbor_bottom
		current.focus_previous = current.focus_neighbor_top
