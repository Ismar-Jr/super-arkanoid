
extends Control

# Componentes visuais reutilizáveis.
const UI = preload("res://Scripts/UI/arcade_ui.gd")

# Referências aos elementos da tela.
var _content: Control
var _score: Label
var _record: Label
var _retry: Button
var _entry: Tween


func _ready() -> void:
	# Bloqueia a interação com a interface atrás da tela.
	mouse_filter = Control.MOUSE_FILTER_STOP
	UI.line(self, Rect2(0, 0, 960, 576), Color(0.02, 0.03, 0.07, 0.91))

	# Cria o painel central.
	_content = Control.new()
	_content.name = "SummaryPanel"
	_content.position = Vector2(220, 104)
	add_child(_content)

	# Configura o fundo e o título.
	UI.panel(_content, Rect2(0, 0, 520, 380), Color("111b35"), Color("7c5973"))
	UI.line(_content, Rect2(0, 0, 520, 4), Color("d978a0"))
	UI.label(_content, "CONEXÃO ENCERRADA", Rect2(24, 24, 472, 22), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_content, "GAME OVER", Rect2(24, 54, 472, 64), 40, UI.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	UI.line(_content, Rect2(40, 132, 440, 1), Color("435473"))

	# Cria os campos de pontuação e recorde.
	UI.label(_content, "SCORE FINAL", Rect2(42, 151, 208, 24), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	UI.label(_content, "HI-SCORE", Rect2(270, 151, 208, 24), 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	_score = UI.label(_content, "00000000", Rect2(42, 178, 208, 32), 24, UI.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_record = UI.label(_content, "00000000", Rect2(270, 178, 208, 32), 24, UI.AMBER, HORIZONTAL_ALIGNMENT_CENTER)

	_score.name = "FinalScore"
	_record.name = "BestScore"

	# Cria os botões de reinício e retorno ao menu.
	_retry = UI.button(_content, "JOGAR NOVAMENTE", Rect2(72, 242, 376, 44))
	var menu = UI.button(_content, "MENU PRINCIPAL", Rect2(72, 298, 376, 44))

	_retry.name = "RetryButton"
	menu.name = "MenuButton"

	# Conecta as ações ao gerenciador da partida.
	_retry.pressed.connect(GameManager.new_game)
	menu.pressed.connect(GameManager.return_to_menu)

	UI.focus_loop([_retry, menu])

	# Mantém a tela oculta até o Game Over.
	hide()


func present() -> void:
	# Atualiza as pontuações antes de exibir o painel.
	_score.text = "%08d" % GameManager.score
	_record.text = "%08d" % GameManager.best_score

	show()
	modulate.a = 0.0
	_content.position.y = 126

	# Interrompe animações anteriores, se necessário.
	if _entry and _entry.is_valid():
		_entry.kill()

	# Anima a transparência e a posição do painel.
	_entry = create_tween().set_parallel()
	_entry.tween_property(self, "modulate:a", 1.0, 0.3)
	_entry.tween_property(_content, "position:y", 104.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Seleciona o botão de reinício para navegação por teclado.
	_retry.grab_focus()


func dismiss() -> void:
	# Oculta a tela sem destruir seus componentes.
	hide()
