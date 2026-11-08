
extends CanvasLayer

# Componentes visuais e tela de Game Over.
const UI = preload("res://Scripts/UI/arcade_ui.gd")
const GAME_OVER = preload("res://Scenes/UI/game_over.tscn")

# Referências aos indicadores do HUD.
var _score: Label
var _best_score: Label
var _life_count: Label
var _life_icons: Array[TextureRect] = []
var _level: Label
var _blocks: Label
var _power: Label
var _power_count: Label
var _power_segments: Array[ColorRect] = []

# Elementos de preparação e encerramento da partida.
var _ready_prompt: Control
var _ready_title: Label
var _ready_hint: Label
var _game_over


func _ready() -> void:
	# Constrói a interface e conecta os sinais do jogo.
	_build_interface()

	GameManager.score_changed.connect(_update_score)
	GameManager.best_score_changed.connect(_update_best_score)
	GameManager.lives_changed.connect(_update_lives)
	GameManager.level_changed.connect(_update_level)
	GameManager.blocks_changed.connect(_update_blocks)
	GameManager.power_up_changed.connect(_update_power)
	GameManager.state_changed.connect(_update_state)

	# Inicializa o HUD com os valores atuais.
	_update_score(GameManager.score)
	_update_best_score(GameManager.best_score)
	_update_lives(GameManager.lives)
	_update_level(GameManager.level)
	_update_blocks(GameManager.blocks_remaining)
	_update_power(GameManager.power_up_shots)
	_update_state(GameManager.state)


func _build_interface() -> void:
	# Cria o painel principal na resolução de 960 × 576.
	var frame = Control.new()
	frame.name = "Console"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	# Fundo e identidade visual.
	UI.texture(frame, "res://Assets/16bit/cabinet.png", Rect2(0, 0, 960, 576))
	UI.label(frame, "SUPER ARKANOID", Rect2(58, 14, 430, 30), 24, UI.WHITE)
	UI.label(frame, "ORBITAL DEFENSE", Rect2(698, 17, 144, 24), 12, UI.CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.label(frame, "PILOT CONSOLE", Rect2(712, 73, 208, 22), 12, UI.MUTED)

	# Indicadores de pontuação e recorde.
	UI.label(frame, "SCORE", Rect2(712, 106, 208, 22), 14, UI.CYAN)
	_score = UI.label(frame, "", Rect2(712, 130, 208, 34), 28, UI.WHITE)
	_score.name = "Score"

	UI.line(frame, Rect2(712, 177, 208, 1), Color("354462"))
	UI.label(frame, "HI-SCORE", Rect2(712, 190, 208, 22), 12, UI.MUTED)
	_best_score = UI.label(frame, "", Rect2(712, 211, 208, 30), 22, UI.AMBER)
	_best_score.name = "BestScore"

	# Contador e ícones de vidas.
	UI.label(frame, "LIVES", Rect2(712, 258, 132, 22), 12, UI.MUTED)
	_life_count = UI.label(frame, "", Rect2(872, 256, 48, 24), 16, UI.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_life_count.name = "LifeCount"

	for index in 3:
		_life_icons.append(UI.texture(frame, "res://Assets/16bit/life.png", Rect2(714 + index * 40, 286, 30, 15)))

	# Nível atual e blocos restantes.
	UI.line(frame, Rect2(712, 318, 208, 1), Color("354462"))
	UI.label(frame, "LEVEL", Rect2(712, 330, 116, 24), 12, UI.MUTED)
	_level = UI.label(frame, "", Rect2(840, 327, 80, 28), 22, UI.CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	_level.name = "Level"

	_blocks = UI.label(frame, "", Rect2(712, 358, 208, 20), 12, UI.MUTED)
	_blocks.name = "Blocks"

	# Status e quantidade de disparos do power-up.
	UI.line(frame, Rect2(712, 390, 208, 1), Color("354462"))
	UI.label(frame, "POWER-UP", Rect2(712, 402, 208, 22), 12, UI.MUTED)

	_power = UI.label(frame, "", Rect2(712, 428, 208, 24), 16, UI.CYAN)
	_power.name = "Power"

	_power_count = UI.label(frame, "", Rect2(712, 455, 208, 20), 12, UI.MUTED)
	_power_count.name = "PowerCount"

	# Cria 16 segmentos para representar os disparos restantes.
	for index in 16:
		_power_segments.append(UI.line(frame, Rect2(712 + index * 13, 484, 10, 6), Color("26344d")))

	# Instruções de controle.
	UI.label(frame, "A / D  MOVER", Rect2(712, 505, 208, 20), 12, UI.MUTED)
	UI.label(frame, "ESC  MENU", Rect2(712, 525, 208, 20), 12, UI.MUTED)

	# Adiciona os avisos de preparação e Game Over.
	_build_ready(frame)
	_game_over = GAME_OVER.instantiate()
	add_child(_game_over)


func _build_ready(parent: Control) -> void:
	# Cria o aviso exibido antes do lançamento.
	_ready_prompt = Control.new()
	_ready_prompt.name = "ReadyPrompt"
	_ready_prompt.position = Vector2(144, 350)
	_ready_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_ready_prompt)

	UI.panel(_ready_prompt, Rect2(0, 0, 400, 76), Color(0.035, 0.065, 0.13, 0.94), UI.CYAN.darkened(0.4))

	_ready_title = UI.label(_ready_prompt, "SISTEMA PRONTO", Rect2(12, 8, 376, 28), 20, UI.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_ready_hint = UI.label(_ready_prompt, "ESPAÇO PARA LANÇAR", Rect2(12, 40, 376, 24), 14, UI.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# Anima a transparência do aviso continuamente.
	var blink = create_tween().set_loops()
	blink.tween_property(_ready_hint, "modulate:a", 0.3, 0.7)
	blink.tween_property(_ready_hint, "modulate:a", 1.0, 0.7)


func _update_score(value: int) -> void:
	_score.text = "%08d" % value


func _update_best_score(value: int) -> void:
	_best_score.text = "%08d" % value


func _update_lives(value: int) -> void:
	# Atualiza o contador e apaga os ícones das vidas perdidas.
	_life_count.text = "%02d" % value

	for index in _life_icons.size():
		_life_icons[index].modulate = UI.WHITE if index < value else Color("2b354d")


func _update_level(value: int) -> void:
	_level.text = "%02d" % value


func _update_blocks(value: int) -> void:
	_blocks.text = "ALVOS RESTANTES  %02d" % value


func _update_power(value: int) -> void:
	# Atualiza o status e os indicadores de disparos restantes.
	_power.text = "LASER ONLINE" if value > 0 else "STANDBY"
	_power.modulate = UI.WHITE if value > 0 else UI.MUTED
	_power_count.text = "%02d DISPAROS RESTANTES" % value if value > 0 else "COLETE O MÓDULO LASER"

	for index in _power_segments.size():
		_power_segments[index].color = UI.CYAN if index < value else Color("26344d")


func _update_state(value: int) -> void:
	# Exibe o aviso de preparação fora do estado PLAYING.
	_ready_prompt.visible = value == GameManager.State.READY

	if value == GameManager.State.READY:
		# Diferencia reposição, mudança de setor e lançamento.
		if GameManager.ready_locked:
			_ready_title.text = "SETOR CONCLUÍDO" if GameManager.blocks_remaining == 0 else "RECALIBRANDO..."
			_ready_hint.text = "SINCRONIZANDO PRÓXIMO SETOR" if GameManager.blocks_remaining == 0 else "REPOSICIONANDO PLATAFORMA"
		else:
			_ready_title.text = "SISTEMA PRONTO"
			_ready_hint.text = "ESPAÇO PARA LANÇAR"

	# Apresenta ou oculta a tela de Game Over.
	if value == GameManager.State.GAME_OVER:
		_game_over.present()
	else:
		_game_over.dismiss()
