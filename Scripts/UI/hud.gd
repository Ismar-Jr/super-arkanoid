## Backbox compacto: o placar fica acima da mesa e os controles no avental.
extends CanvasLayer

const UI = preload("res://Scripts/UI/arcade_ui.gd")
const GAME_OVER = preload("res://Scenes/UI/game_over.tscn")
const GOLD := Color("d7ae69")
const CREAM := Color("f4e3be")
const RED := Color("b44745")
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
var _game_over
var _status_clock: float = 0.0


func _ready() -> void:
	_build_interface()
	GameManager.score_changed.connect(_update_score)
	GameManager.best_score_changed.connect(_update_best_score)
	GameManager.lives_changed.connect(_update_balls)
	GameManager.multiplier_changed.connect(_update_multiplier)
	GameManager.reactor_changed.connect(_update_reactor)
	GameManager.launch_charge_changed.connect(_update_charge)
	GameManager.state_changed.connect(_update_state)
	_update_score(GameManager.score)
	_update_best_score(GameManager.best_score)
	_update_balls(GameManager.lives)
	_update_multiplier(GameManager.multiplier)
	_update_reactor(GameManager.reactor_hits, GameManager.reactor_goal)
	_update_charge(GameManager.launch_charge)
	_update_state(GameManager.state)


func _process(delta: float) -> void:
	# O canal pode receber a bola durante PLAYING, sem trocar o estado da partida.
	_status_clock += delta
	if _status_clock >= 0.12:
		_status_clock = 0.0
		_update_launcher_status()
		_ready_prompt.visible = GameManager.state == GameManager.State.READY or _launcher_available()


func _build_interface() -> void:
	var frame := Control.new()
	frame.name = "Console"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	UI.line(frame, Rect2(0, 0, 720, 156), Color("0b111c"))
	for x in [16, 696]:
		UI.line(frame, Rect2(x, 12, 8, 1092), Color("36424c"))
		UI.line(frame, Rect2(x + 2, 12, 2, 1092), GOLD)
	UI.line(frame, Rect2(40, 10, 640, 2), GOLD)
	UI.line(frame, Rect2(40, 43, 640, 2), RED)
	UI.label(frame, "ORBITAL REACTOR", Rect2(52, 12, 440, 30), 24, CREAM)
	UI.label(frame, "SUPER PINBALL", Rect2(494, 16, 172, 22), 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.panel(frame, Rect2(48, 52, 326, 65), Color("160e13"), Color("644343"))
	UI.panel(frame, Rect2(388, 52, 284, 65), Color("160e13"), Color("644343"))
	UI.label(frame, "PLAYER 1", Rect2(60, 55, 286, 16), 10, Color("ab7862"))
	_score = UI.label(frame, "", Rect2(60, 72, 296, 38), 30, Color("ffc776"))
	_score.name = "Score"
	UI.label(frame, "GRAND CHAMPION", Rect2(400, 55, 252, 16), 10, Color("ab7862"))
	_best_score = UI.label(frame, "", Rect2(400, 78, 252, 30), 24, GOLD)
	_best_score.name = "BestScore"
	UI.label(frame, "BOLAS", Rect2(52, 123, 68, 22), 12, CREAM)
	_ball_count = UI.label(frame, "", Rect2(117, 123, 36, 22), 14, GOLD)
	_ball_count.name = "BallCount"
	for index in 3:
		var icon := UI.texture(frame, "res://Assets/Pinball/life.svg", Rect2(157 + index * 25, 124, 18, 18))
		icon.name = "BallIcon%d" % (index + 1)
		_ball_icons.append(icon)
	UI.label(frame, "BONUS", Rect2(263, 123, 68, 22), 12, CREAM)
	_multiplier = UI.label(frame, "", Rect2(329, 120, 62, 28), 20, UI.CYAN)
	_multiplier.name = "Multiplier"
	_reactor = UI.label(frame, "", Rect2(418, 123, 248, 22), 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_reactor.name = "Reactor"
	UI.line(frame, Rect2(40, 152, 640, 3), GOLD)
	UI.line(frame, Rect2(40, 1062, 640, 58), Color("101722"))
	UI.line(frame, Rect2(40, 1062, 640, 2), GOLD)
	_launch_power = UI.label(frame, "", Rect2(52, 1068, 258, 22), 14, CREAM)
	_launch_power.name = "LaunchPower"
	_charge_value = UI.label(frame, "", Rect2(52, 1088, 284, 18), 10, GOLD)
	_charge_value.name = "ChargeValue"
	var segments := Control.new()
	segments.name = "ChargeSegments"
	segments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(segments)
	for index in 16:
		var segment := UI.line(segments, Rect2(52 + index * 16, 1110, 13, 3), Color("31302f"))
		segment.name = "Segment%02d" % (index + 1)
		_charge_segments.append(segment)
	UI.label(frame, "A / D OU SETAS  •  FLIPPERS", Rect2(342, 1068, 326, 22), 12, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.label(frame, "ESPAÇO  •  MOLA     ESC  •  MENU", Rect2(342, 1090, 326, 22), 10, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_build_ready(frame)
	_game_over = GAME_OVER.instantiate()
	add_child(_game_over)


func _build_ready(parent: Control) -> void:
	# A luz fica no avental e indica quando a mola está pronta.
	_ready_prompt = UI.panel(parent, Rect2(321, 1074, 9, 9), UI.CYAN, UI.CYAN)
	_ready_prompt.name = "ReadyPrompt"


func _update_score(value: int) -> void:
	_score.text = "%08d" % value


func _update_best_score(value: int) -> void:
	_best_score.text = "%08d" % value


func _update_balls(value: int) -> void:
	_ball_count.text = "%02d" % value
	for index in _ball_icons.size():
		_ball_icons[index].modulate = Color.WHITE if index < value else Color("393631")


func _update_multiplier(value: int) -> void:
	_multiplier.text = "%02dX" % value


func _update_reactor(hits: int, goal: int) -> void:
	_reactor.text = "REATOR  %d / %d" % [hits, goal]


func _update_charge(value: float) -> void:
	_launch_charge = clampf(value, 0.0, 1.0)
	var lit_segments := ceili(_launch_charge * _charge_segments.size())
	for index in _charge_segments.size():
		_charge_segments[index].color = GOLD if index < lit_segments else Color("31302f")
	_update_launcher_status()


func _launcher_available() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var table := scene.get_node_or_null("Table")
	return table != null and table.has_method("can_launch") and table.can_launch()


func _update_launcher_status() -> void:
	if GameManager.state == GameManager.State.GAME_OVER:
		_launch_power.text = "PARTIDA ENCERRADA"
		_charge_value.text = "JOGUE NOVAMENTE OU VOLTE AO MENU"
	elif GameManager.ready_locked:
		_launch_power.text = "PREPARANDO NOVA BOLA"
		_charge_value.text = "AGUARDE..."
	elif _launch_charge > 0.0:
		_launch_power.text = "MOLA CARREGADA  %03d%%" % roundi(_launch_charge * 100)
		_charge_value.text = "SOLTE ESPAÇO PARA LANÇAR"
	elif GameManager.state == GameManager.State.READY or _launcher_available():
		_launch_power.text = "BOLA NO LANÇADOR"
		_charge_value.text = "SEGURE ESPAÇO E SOLTE"
	else:
		_launch_power.text = "MOLA SEMPRE DISPONÍVEL"
		_charge_value.text = "BOLA VOLTOU AO CANAL? USE ESPAÇO"


func _update_state(value: int) -> void:
	_ready_prompt.visible = value == GameManager.State.READY
	_update_launcher_status()
	if value == GameManager.State.GAME_OVER:
		_game_over.present()
	else:
		_game_over.dismiss()
