
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
	# Cria o fundo e os elementos visuais do menu.
	UI.texture(self, "res://Assets/16bit/menu_background.png", Rect2(0, 0, 960, 576))
	UI.line(self, Rect2(48, 40, 128, 2), UI.CYAN.darkened(0.4))
	UI.line(self, Rect2(784, 40, 128, 2), UI.CYAN.darkened(0.4))
	UI.label(self, "SP-16  /  ORBITAL REACTOR", Rect2(180, 27, 600, 28), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	UI.texture(self, "res://Assets/Pinball/logo.png", Rect2(200, 106, 560, 140))
	UI.label(self, "CARREGUE O REATOR. DOMINE A ÓRBITA.", Rect2(100, 257, 760, 24), 14, UI.AMBER, HORIZONTAL_ALIGNMENT_CENTER)

	# Cria os botões principais.
	_start_button = UI.button(self, "INICIAR JOGO", Rect2(320, 310, 320, 44))
	_help_button = UI.button(self, "COMO JOGAR", Rect2(320, 365, 320, 44))
	var quit_button = UI.button(self, "SAIR", Rect2(320, 420, 320, 44))

	_start_button.name = "StartButton"
	_help_button.name = "HelpButton"
	quit_button.name = "QuitButton"

	_main_buttons = [_start_button, _help_button, quit_button]

	# Conecta as ações dos botões.
	_start_button.pressed.connect(GameManager.new_game)
	_help_button.pressed.connect(_show_help)
	quit_button.pressed.connect(AudioManager.quit_game)

	# Configura a navegação entre as opções.
	UI.focus_loop(_main_buttons)

	# Exibe o recorde e os indicadores inferiores.
	_record = UI.label(self, "", Rect2(240, 495, 480, 28), 16, UI.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_status = UI.label(self, "REATOR ONLINE", Rect2(48, 525, 240, 22), 12, UI.CYAN)
	UI.label(self, "TECLADO + MOUSE", Rect2(704, 525, 208, 22), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.line(self, Rect2(48, 552, 864, 1), Color("334361"))

	# Adiciona os controles de áudio.
	_build_volume_controls()


func _build_volume_controls() -> void:
	# Cria os controles independentes de música e efeitos.
	UI.label(self, "MÚSICA", Rect2(290, 523, 60, 22), 12, UI.MUTED)
	_music_slider = _volume_slider("MusicVolume", Rect2(356, 525, 108, 18))

	UI.label(self, "EFEITOS", Rect2(486, 523, 70, 22), 12, UI.MUTED)
	_sfx_slider = _volume_slider("SFXVolume", Rect2(564, 525, 124, 18))

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
	# Desenha o indicador pixelado do controle de volume.
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
	# Cria a camada do manual de instruções.
	_help = Control.new()
	_help.name = "HelpOverlay"
	_help.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_help)

	# Configura o fundo e o cabeçalho.
	UI.line(_help, Rect2(0, 0, 960, 576), Color(0.025, 0.035, 0.08, 0.94))
	UI.panel(_help, Rect2(148, 84, 664, 414), UI.PANEL, UI.CYAN.darkened(0.3))
	UI.line(_help, Rect2(174, 110, 32, 4), UI.AMBER)
	UI.label(_help, "MANUAL DO REATOR", Rect2(222, 100, 530, 30), 24, UI.AMBER)

	# Apresenta os objetivos do jogo.
	UI.label(_help, "ACERTE BUMPERS E ALVOS PARA PONTUAR.", Rect2(176, 150, 612, 26), 14)
	UI.label(_help, "USE OS FLIPPERS PARA MANTER A BOLA EM JOGO.", Rect2(176, 174, 612, 26), 14, UI.MUTED)
	UI.line(_help, Rect2(176, 215, 608, 1), Color("334361"))

	# Lista os comandos disponíveis.
	_control_row(230, "A / ESQUERDA", "FLIPPER ESQUERDO")
	_control_row(268, "D / DIREITA", "FLIPPER DIREITO")
	_control_row(306, "SEGURE ESPAÇO", "CARREGAR LANÇADOR")
	_control_row(344, "SOLTE ESPAÇO", "LANÇAR A BOLA")

	# Completar o reator aumenta o multiplicador da pontuação.
	UI.label(_help, "5 ACERTOS EM BUMPERS = BÔNUS E MULTIPLICADOR", Rect2(176, 384, 608, 22), 12, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, "ESC: MENU • 3 BOLAS POR PARTIDA", Rect2(176, 408, 608, 20), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	# Cria o botão de retorno ao menu.
	_back_button = UI.button(_help, "VOLTAR", Rect2(336, 438, 288, 40))
	_back_button.name = "BackButton"
	_back_button.pressed.connect(_hide_help)

	UI.focus_loop([_back_button])

	# Mantém o manual oculto inicialmente.
	_help.hide()


func _control_row(y: float, key: String, description: String) -> void:
	# Cria uma linha padronizada de comando e descrição.
	UI.panel(_help, Rect2(176, y, 258, 30), Color("1c2c48"), Color("435473"))
	UI.label(_help, key, Rect2(188, y, 234, 30), 14, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_help, description, Rect2(458, y, 328, 30), 14)


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
	_record.text = "HI-SCORE  %08d" % value
