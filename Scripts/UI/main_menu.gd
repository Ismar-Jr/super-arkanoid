
## Menu do pinball: identidade do reator, instruções e preferências de áudio.
extends Control

# Biblioteca de componentes visuais do arcade.
const UI = preload("res://Scripts/UI/arcade_ui.gd")

# Referências aos elementos do menu.
var _start_button: Button
var _help_button: Button
var _help: Control
var _back_button: Button
var _record: Label
var _status: Label
var _main_buttons: Array[Button] = []

# Controles de volume.
var _music_slider: HSlider
var _sfx_slider: HSlider
var _volume_controls: Array[HSlider] = []


func _ready() -> void:
	# Inicializa o menu e o manual de instruções.
	GameManager.enter_menu()
	_build_menu()
	_build_help()

	# Atualiza o recorde e os volumes pelos sinais.
	GameManager.best_score_changed.connect(_update_record)
	_update_record(GameManager.best_score)

	AudioManager.volumes_changed.connect(_update_volumes)
	_update_volumes(AudioManager.music_volume, AudioManager.sfx_volume)

	# Seleciona a primeira opção do menu.
	_start_button.grab_focus()

	# Aplica a animação de entrada.
	var entrance = create_tween()
	modulate.a = 0.0
	entrance.tween_property(self, "modulate:a", 1.0, 0.4)

	# Anima o indicador de sistema ativo.
	var pulse = create_tween().set_loops()
	pulse.tween_property(_status, "modulate:a", 0.35, 1.2)
	pulse.tween_property(_status, "modulate:a", 1.0, 1.2)


func _build_menu() -> void:
	UI.texture(self, "res://Assets/Pinball/menu_background.svg", Rect2(0, 0, 720, 1120))
	UI.line(self, Rect2(52, 42, 616, 2), Color("d7ae69"))
	UI.label(self, "ORBITAL AMUSEMENTS  /  CLASSIC SERIES", Rect2(52, 52, 616, 26), 12, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.texture(self, "res://Assets/Pinball/logo.svg", Rect2(80, 142, 560, 140))
	UI.label(self, "ORBITAL REACTOR", Rect2(60, 303, 600, 38), 24, Color("f4e3be"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(self, "UMA MESA. TRÊS BOLAS. SUA MELHOR PARTIDA.", Rect2(60, 349, 600, 26), 12, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.panel(self, Rect2(196, 410, 328, 72), Color("170f16"), Color("755b42"))
	UI.label(self, "GRAND CHAMPION", Rect2(208, 417, 304, 18), 10, Color("b88e68"), HORIZONTAL_ALIGNMENT_CENTER)
	_record = UI.label(self, "", Rect2(208, 438, 304, 34), 24, Color("ffc776"), HORIZONTAL_ALIGNMENT_CENTER)
	_start_button = UI.button(self, "INICIAR JOGO", Rect2(192, 532, 336, 54))
	_help_button = UI.button(self, "COMO JOGAR", Rect2(192, 604, 336, 54))
	var quit_button := UI.button(self, "SAIR", Rect2(192, 676, 336, 54))
	_start_button.name = "StartButton"
	_help_button.name = "HelpButton"
	quit_button.name = "QuitButton"
	_main_buttons = [_start_button, _help_button, quit_button]
	for option in _main_buttons:
		option.add_theme_stylebox_override("normal", UI.box_style(Color("16202a"), Color("af8b58"), 2))
		option.add_theme_color_override("font_color", Color("f4e3be"))
	_start_button.pressed.connect(GameManager.new_game)
	_help_button.pressed.connect(_show_help)
	quit_button.pressed.connect(AudioManager.quit_game)
	UI.focus_loop(_main_buttons)
	UI.label(self, "A / D OU SETAS", Rect2(92, 788, 536, 24), 16, Color("f4e3be"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(self, "SEGURE ESPAÇO E SOLTE PARA LANÇAR", Rect2(92, 819, 536, 24), 12, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.line(self, Rect2(92, 880, 536, 1), Color("755b42"))
	_build_volume_controls()
	_status = UI.label(self, "INSERT COIN? AQUI É SÓ DAR PLAY.", Rect2(52, 1020, 616, 24), 12, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	UI.line(self, Rect2(52, 1074, 616, 2), Color("d7ae69"))


func _build_volume_controls() -> void:
	# Cria os controles independentes de música e efeitos.
	UI.label(self, "MÚSICA", Rect2(116, 916, 92, 22), 12, UI.MUTED)
	_music_slider = _volume_slider("MusicVolume", Rect2(218, 918, 140, 18))

	UI.label(self, "EFEITOS", Rect2(384, 916, 80, 22), 12, UI.MUTED)
	_sfx_slider = _volume_slider("SFXVolume", Rect2(476, 918, 128, 18))

	_volume_controls = [_music_slider, _sfx_slider]

	# Conecta os ajustes ao gerenciador de áudio.
	_music_slider.value_changed.connect(AudioManager.set_music_volume)
	_sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)

	# Inclui os controles de volume na navegação por Tab.
	var order: Array[Control] = [_start_button, _help_button, _main_buttons[2], _music_slider, _sfx_slider]

	for index in order.size():
		order[index].focus_next = order[index].get_path_to(order[(index + 1) % order.size()])
		order[index].focus_previous = order[index].get_path_to(order[posmod(index - 1, order.size())])

	# Configura a navegação vertical dos sliders.
	for slider in _volume_controls:
		slider.focus_neighbor_top = slider.get_path_to(_main_buttons[2])
		slider.focus_neighbor_bottom = slider.get_path_to(_start_button)


func _volume_slider(node_name: String, rect: Rect2) -> HSlider:
	# Cria um controle de volume com valores entre 0 e 1.
	var slider = HSlider.new()
	slider.name = node_name
	slider.position = rect.position
	slider.size = rect.size
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Define a aparência da barra.
	var track = StyleBoxFlat.new()
	track.bg_color = Color("16243b")
	track.border_color = Color("435473")
	track.set_border_width_all(1)
	track.content_margin_top = 3
	track.content_margin_bottom = 3

	slider.add_theme_stylebox_override("slider", track)

	# Define a aparência da área preenchida.
	var filled = track.duplicate()
	filled.bg_color = Color("356c7d")

	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)

	# Personaliza os indicadores do slider.
	slider.add_theme_icon_override("grabber", _slider_icon(UI.CYAN))
	slider.add_theme_icon_override("grabber_highlight", _slider_icon(UI.AMBER))
	slider.add_theme_icon_override("grabber_disabled", _slider_icon(UI.MUTED))

	add_child(slider)

	# Sincroniza o foco e reproduz o som de navegação.
	slider.mouse_entered.connect(slider.grab_focus)
	slider.focus_entered.connect(func(): AudioManager.play_sfx(&"ui_move"))

	return slider


func _slider_icon(color: Color) -> Texture2D:
	# Desenha o indicador do controle de volume.
	var image = Image.create(8, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color("0b1529"))
	image.fill_rect(Rect2i(1, 1, 6, 10), color)
	image.fill_rect(Rect2i(2, 2, 4, 2), UI.WHITE)

	return ImageTexture.create_from_image(image)


func _update_volumes(music: float, sfx: float) -> void:
	# Atualiza os sliders sem emitir novos sinais.
	_music_slider.set_value_no_signal(music)
	_sfx_slider.set_value_no_signal(sfx)

	# Exibe os valores percentuais nas dicas dos controles.
	_music_slider.tooltip_text = "MÚSICA: %d%%" % roundi(music * 100)
	_sfx_slider.tooltip_text = "EFEITOS: %d%%" % roundi(sfx * 100)


func _build_help() -> void:
	_help = Control.new()
	_help.name = "HelpOverlay"
	_help.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_help)
	UI.line(_help, Rect2(0, 0, 720, 1120), Color(0.025, 0.035, 0.06, 0.97))
	UI.panel(_help, Rect2(52, 132, 616, 860), Color("101a27"), Color("d7ae69"))
	UI.label(_help, "COMO JOGAR", Rect2(80, 164, 560, 42), 28, Color("f4e3be"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, "MANTENHA A BOLA EM JOGO.", Rect2(80, 226, 560, 28), 16, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, "ACERTE BUMPERS, ALVOS E PISTAS.", Rect2(80, 260, 560, 26), 14, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_control_row(326, "A / ESQUERDA", "FLIPPER ESQUERDO")
	_control_row(416, "D / DIREITA", "FLIPPER DIREITO")
	_control_row(506, "SEGURE ESPAÇO", "CARREGAR A MOLA")
	_control_row(596, "SOLTE ESPAÇO", "LANÇAR OU RELANÇAR")
	UI.label(_help, "VOLTOU AO CANAL? USE A MOLA DE NOVO.", Rect2(80, 708, 560, 24), 12, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, "COMPLETE A / B / C PARA GANHAR BÔNUS.", Rect2(80, 746, 560, 24), 12, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, "5 BUMPERS AUMENTAM SEU MULTIPLICADOR.", Rect2(80, 778, 560, 24), 12, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, "3 BOLAS POR PARTIDA  •  ESC VOLTA AO MENU", Rect2(80, 810, 560, 24), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_back_button = UI.button(_help, "VOLTAR", Rect2(204, 872, 312, 52))
	_back_button.name = "BackButton"
	_back_button.pressed.connect(_hide_help)
	UI.focus_loop([_back_button])
	_help.hide()


func _control_row(y: float, key: String, description: String) -> void:
	UI.panel(_help, Rect2(176, y, 368, 34), Color("202a32"), Color("8f754f"))
	UI.label(_help, key, Rect2(188, y, 344, 34), 14, Color("f4e3be"), HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, description, Rect2(108, y + 41, 504, 28), 14, Color("d7ae69"), HORIZONTAL_ALIGNMENT_CENTER)


func _show_help() -> void:
	# Exibe o manual e desativa a navegação pelo menu.
	_help.show()

	for option in _main_buttons:
		option.focus_mode = Control.FOCUS_NONE

	for slider in _volume_controls:
		slider.editable = false
		slider.focus_mode = Control.FOCUS_NONE

	# Direciona o foco ao botão de retorno.
	_back_button.grab_focus()


func _hide_help() -> void:
	# Oculta o manual e restaura os controles do menu.
	_help.hide()

	for option in _main_buttons:
		option.focus_mode = Control.FOCUS_ALL

	for slider in _volume_controls:
		slider.editable = true
		slider.focus_mode = Control.FOCUS_ALL

	# Devolve o foco ao botão COMO JOGAR.
	_help_button.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	# Fecha o manual com Esc sem propagar a mesma entrada.
	if _help.visible and event.is_action_pressed("ui_cancel"):
		_hide_help()
		get_viewport().set_input_as_handled()


func _update_record(value: int) -> void:
	# Atualiza o recorde exibido no menu.
	_record.text = "%08d" % value
