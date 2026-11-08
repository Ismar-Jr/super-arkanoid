## Painel do pinball: pontos, bolas, multiplicador, reator e força do lançador.
extends CanvasLayer

const UI = preload("res://Scripts/UI/arcade_ui.gd")
const GAME_OVER = preload("res://Scenes/UI/game_over.tscn")

var _score: Label
var _best_score: Label
var _ball_count: Label
var _ball_icons: Array[TextureRect] = []
var _multiplier: Label
var _reactor: Label
var _launch_power: Label
var _charge_value: Label
var _charge_segments: Array[ColorRect] = []
var _launch_charge: float = 0.0
var _ready_prompt: Control
var _ready_title: Label
var _ready_hint: Label
var _game_over


func _ready() -> void:
	_build_interface()
	# Cada sinal atualiza somente o indicador alterado pela partida.
	GameManager.score_changed.connect(_update_score)
	GameManager.best_score_changed.connect(_update_best_score)
	GameManager.lives_changed.connect(_update_balls)
	GameManager.multiplier_changed.connect(_update_multiplier)
	GameManager.reactor_changed.connect(_update_reactor)
	GameManager.launch_charge_changed.connect(_update_charge)
	GameManager.state_changed.connect(_update_state)
	# Mostra também os dados definidos antes de este HUD entrar na árvore.
	_update_score(GameManager.score)
	_update_best_score(GameManager.best_score)
	_update_balls(GameManager.lives)
	_update_multiplier(GameManager.multiplier)
	_update_reactor(GameManager.reactor_hits, GameManager.reactor_goal)
	_update_charge(GameManager.launch_charge)
	_update_state(GameManager.state)


func _build_interface() -> void:
	# A coluna direita fica fora da mesa física de 640 × 480.
	var frame = Control.new()
	frame.name = "Console"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	UI.texture(frame, "res://Assets/16bit/cabinet.png", Rect2(0, 0, 960, 576))
	UI.label(frame, "SUPER PINBALL", Rect2(58, 14, 430, 30), 24, UI.WHITE)
	UI.label(frame, "ORBITAL REACTOR", Rect2(698, 17, 144, 24), 12, UI.CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.label(frame, "REACTOR CONSOLE", Rect2(712, 73, 208, 22), 12, UI.MUTED)
	UI.label(frame, "SCORE", Rect2(712, 106, 208, 22), 14, UI.CYAN)
	_score = UI.label(frame, "", Rect2(712, 130, 208, 34), 28, UI.WHITE)
	_score.name = "Score"
	UI.line(frame, Rect2(712, 177, 208, 1), Color("354462"))
	UI.label(frame, "HI-SCORE", Rect2(712, 190, 208, 22), 12, UI.MUTED)
	_best_score = UI.label(frame, "", Rect2(712, 211, 208, 30), 22, UI.AMBER)
	_best_score.name = "BestScore"
	UI.label(frame, "BOLAS", Rect2(712, 258, 132, 22), 12, UI.MUTED)
	_ball_count = UI.label(frame, "", Rect2(872, 256, 48, 24), 16, UI.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_ball_count.name = "BallCount"
	for index in 3:
		var icon = UI.texture(frame, "res://Assets/Pinball/life.png", Rect2(716 + index * 40, 282, 22, 22))
		icon.name = "BallIcon%d" % (index + 1)
		_ball_icons.append(icon)
	UI.line(frame, Rect2(712, 318, 208, 1), Color("354462"))
	UI.label(frame, "MULTIPLICADOR", Rect2(712, 330, 136, 24), 12, UI.MUTED)
	_multiplier = UI.label(frame, "", Rect2(840, 327, 80, 28), 22, UI.CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	_multiplier.name = "Multiplier"
	_reactor = UI.label(frame, "", Rect2(712, 358, 208, 20), 12, UI.MUTED)
	_reactor.name = "Reactor"
	UI.line(frame, Rect2(712, 390, 208, 1), Color("354462"))
	UI.label(frame, "LANÇADOR", Rect2(712, 402, 208, 22), 12, UI.MUTED)
	_launch_power = UI.label(frame, "", Rect2(712, 428, 208, 24), 16, UI.CYAN)
	_launch_power.name = "LaunchPower"
	_charge_value = UI.label(frame, "", Rect2(712, 452, 208, 20), 12, UI.MUTED)
	_charge_value.name = "ChargeValue"
	var segments = Control.new()
	segments.name = "ChargeSegments"
	segments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(segments)
	for index in 16:
		var segment = UI.line(segments, Rect2(712 + index * 13, 476, 10, 6), Color("26344d"))
		segment.name = "Segment%02d" % (index + 1)
		_charge_segments.append(segment)
	UI.label(frame, "A / D  FLIPPERS", Rect2(712, 492, 208, 20), 12, UI.MUTED)
	UI.label(frame, "ESPAÇO  LANÇAR", Rect2(712, 512, 208, 20), 12, UI.MUTED)
	UI.label(frame, "ESC  MENU", Rect2(712, 532, 208, 20), 12, UI.MUTED)
	_build_ready(frame)
	_game_over = GAME_OVER.instantiate()
	add_child(_game_over)


func _build_ready(parent: Control) -> void:
	# O aviso só aparece enquanto a bola aguarda no lançador ou está sendo reposta.
	_ready_prompt = Control.new()
	_ready_prompt.name = "ReadyPrompt"
	_ready_prompt.position = Vector2(184, 334)
	_ready_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_ready_prompt)
	UI.panel(_ready_prompt, Rect2(0, 0, 320, 76), Color(0.035, 0.065, 0.13, 0.94), UI.CYAN.darkened(0.4))
	_ready_title = UI.label(_ready_prompt, "BOLA PRONTA", Rect2(12, 8, 296, 28), 20, UI.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_ready_hint = UI.label(_ready_prompt, "SEGURE ESPAÇO E SOLTE", Rect2(12, 40, 296, 24), 14, UI.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var blink = create_tween().set_loops()
	blink.tween_property(_ready_hint, "modulate:a", 0.3, 0.7)
	blink.tween_property(_ready_hint, "modulate:a", 1.0, 0.7)


func _update_score(value: int) -> void:
	_score.text = "%08d" % value


func _update_best_score(value: int) -> void:
	_best_score.text = "%08d" % value


func _update_balls(value: int) -> void:
	_ball_count.text = "%02d" % value
	for index in _ball_icons.size():
		_ball_icons[index].modulate = UI.WHITE if index < value else Color("2b354d")


func _update_multiplier(value: int) -> void:
	_multiplier.text = "%02dX" % value


func _update_reactor(hits: int, goal: int) -> void:
	_reactor.text = "REATOR  %d / %d" % [hits, goal]


func _update_charge(value: float) -> void:
	_launch_charge = clampf(value, 0.0, 1.0)
	var lit_segments = ceili(_launch_charge * _charge_segments.size())
	var color = UI.AMBER if _launch_charge >= 0.8 else UI.CYAN
	for index in _charge_segments.size():
		_charge_segments[index].color = color if index < lit_segments else Color("26344d")
	_update_launcher_status()
	_update_ready_prompt()


func _update_launcher_status() -> void:
	if GameManager.state == GameManager.State.PLAYING:
		_launch_power.text = "EM JOGO"
		_charge_value.text = "USE OS FLIPPERS"
	elif GameManager.ready_locked:
		_launch_power.text = "REPOSICIONANDO"
		_charge_value.text = "PREPARANDO NOVA BOLA"
	elif _launch_charge > 0.0:
		_launch_power.text = "CARREGANDO"
		_charge_value.text = "FORÇA  %03d%%" % roundi(_launch_charge * 100)
	else:
		_launch_power.text = "PRONTO"
		_charge_value.text = "SEGURE E SOLTE ESPAÇO"


func _update_ready_prompt() -> void:
	if GameManager.ready_locked:
		_ready_title.text = "REPOSICIONANDO"
		_ready_hint.text = "PREPARANDO NOVA BOLA"
	elif _launch_charge > 0.0:
		_ready_title.text = "CARREGANDO..."
		_ready_hint.text = "SOLTE PARA LANÇAR"
	else:
		_ready_title.text = "BOLA PRONTA"
		_ready_hint.text = "SEGURE ESPAÇO E SOLTE"


func _update_state(value: int) -> void:
	_ready_prompt.visible = value == GameManager.State.READY
	_update_launcher_status()
	_update_ready_prompt()
	if value == GameManager.State.GAME_OVER:
		_game_over.present()
	else:
		_game_over.dismiss()
