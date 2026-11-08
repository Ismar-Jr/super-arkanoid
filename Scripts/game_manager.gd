
extends Node

# Estados possíveis da partida.
enum State { MAIN_MENU, READY, PLAYING, GAME_OVER }

# Sinais de atualização do jogo e da interface.
signal state_changed(value: int)
signal score_changed(value: int)
signal best_score_changed(value: int)
signal lives_changed(value: int)
signal level_changed(value: int)
signal power_up_changed(remaining_shots: int)
signal blocks_changed(value: int)
signal sector_cleared
signal on_powerup

# Configurações iniciais da partida.
const INITIAL_LIVES := 3

var state: State = State.MAIN_MENU
var score: int = 0
var best_score: int = 0
var lives: int = INITIAL_LIVES
var level: int = 1
var blocks_remaining: int = 0
var power_up_shots: int = 0
var ready_locked: bool = false

# Arquivo de persistência do recorde.
var records_path: String = "user://records.cfg"

# Compatibilidade com os scripts que utilizam started.
var started: bool:
	get:
		return state == State.PLAYING


func _ready() -> void:
	# Recupera o recorde salvo.
	load_record()


func new_game() -> void:
	# Reinicia os dados da partida.
	score = 0
	lives = INITIAL_LIVES
	level = 1
	blocks_remaining = 0
	ready_locked = false
	set_power_up(0)

	score_changed.emit(score)
	lives_changed.emit(lives)
	level_changed.emit(level)

	_set_state(State.READY)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func enter_menu() -> void:
	# Prepara o estado do menu.
	ready_locked = false
	set_power_up(0)
	_set_state(State.MAIN_MENU)


func return_to_menu() -> void:
	# Retorna à tela inicial.
	enter_menu()
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")


func launch_ball() -> bool:
	# Autoriza o lançamento quando a partida está pronta.
	if state != State.READY or ready_locked:
		return false

	_set_state(State.PLAYING)
	return true


func lose_life() -> bool:
	# Impede perdas duplicadas de vida.
	if state != State.PLAYING:
		return false

	lives = maxi(0, lives - 1)
	ready_locked = lives > 0

	lives_changed.emit(lives)
	set_power_up(0)

	_set_state(State.READY if lives > 0 else State.GAME_OVER)

	if lives == 0:
		save_record()

	return true


func add_block_score(points: int) -> void:
	# Atualiza a pontuação após destruir um bloco.
	if state != State.PLAYING:
		return

	score += maxi(0, points)
	score_changed.emit(score)

	# Atualiza e salva um novo recorde.
	if score > best_score:
		best_score = score
		best_score_changed.emit(best_score)
		save_record()

	# Atualiza a quantidade de blocos restantes.
	blocks_remaining = maxi(0, blocks_remaining - 1)
	blocks_changed.emit(blocks_remaining)

	if blocks_remaining == 0:
		# Solicita a preparação do próximo setor.
		ready_locked = true
		_set_state(State.READY)
		sector_cleared.emit()


func configure_blocks(count: int) -> void:
	# Define a quantidade de blocos da fase.
	blocks_remaining = count
	blocks_changed.emit(count)


func advance_level() -> void:
	# Avança para o próximo nível.
	level += 1
	level_changed.emit(level)

	ready_locked = false
	_set_state(State.READY)


func set_power_up(remaining_shots: int) -> void:
	# Atualiza a quantidade de disparos disponíveis.
	power_up_shots = maxi(0, remaining_shots)
	power_up_changed.emit(power_up_shots)


func load_record() -> void:
	# Recupera o recorde armazenado localmente.
	var record := ConfigFile.new()

	if record.load(records_path) == OK:
		best_score = maxi(0, int(record.get_value("arcade", "hi_score", 0)))
		best_score_changed.emit(best_score)


func save_record() -> void:
	# Salva o recorde entre as partidas.
	var record := ConfigFile.new()
	record.set_value("arcade", "hi_score", best_score)

	var error := record.save(records_path)

	if error != OK:
		push_warning("Não foi possível salvar o recorde: %s" % error_string(error))


func _set_state(value: State) -> void:
	# Notifica mudanças reais de estado.
	if state == value:
		return

	state = value
	state_changed.emit(state)
