
extends Node

# Sinais de atualização do sistema de áudio.
signal volumes_changed(music: float, sfx: float)
signal effect_started(id: StringName)
signal music_changed(track: AudioStream)

# Músicas e efeitos sonoros disponíveis.
const MENU_MUSIC: AudioStream = preload("res://Audio/Music/Stranger Things - Causmic.mp3")
const GAME_MUSIC: AudioStream = preload("res://Audio/Music/GTA Type Beat - Dyalla.mp3")
const MAX_VOICES := 16

const SOUNDS := {
	&"rebote": preload("res://Audio/SFX/rebote.wav"),
	&"bloco": preload("res://Audio/SFX/bloco.wav"),
	&"laser": preload("res://Audio/SFX/laser.wav"),
	&"coleta": preload("res://Audio/SFX/coleta.wav"),
	&"vida": preload("res://Audio/SFX/2-game-over-mario.mp3"),
	&"game_over": preload("res://Audio/SFX/wa-wa-wa-waaaaaaa.mp3"),
	&"iniciar": preload("res://Audio/SFX/iniciar.wav"),
	&"setor": preload("res://Audio/SFX/setor.wav"),
	&"ui_move": preload("res://Audio/SFX/gta-sa-menu.mp3"),
	&"ui_confirm": preload("res://Audio/SFX/ui_confirm.wav"),
}

# Referências aos nós de reprodução.
@onready var music: AudioStreamPlayer = $Music
@onready var effects: Node = $Effects

# Configurações e controle interno.
var music_volume: float = 0.45
var sfx_volume: float = 0.8
var settings_path: String = "user://audio.cfg"
var _last_state: int = -1
var _previous_lives: int = 3
var _last_effect_time: Dictionary = {}
var _closing: bool = false


func _ready() -> void:
	# Inicializa o áudio e conecta os eventos do jogo.
	load_settings()
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(quit_game)

	_previous_lives = GameManager.lives
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.on_powerup.connect(_on_power_up)
	GameManager.sector_cleared.connect(_on_sector_cleared)

	_on_state_changed(GameManager.state)


func play_music(track: AudioStream) -> void:
	if _closing:
		return

	if track == null:
		stop_music()
		return

	# Evita reiniciar uma música que já está tocando.
	if music.stream == track and music.playing:
		return

	music.stream = track
	music.play()
	music_changed.emit(track)


func stop_music() -> void:
	if music.stream == null:
		return

	music.stop()
	music.stream = null
	music_changed.emit(null)


func play_sfx(id: StringName, pitch: float = 1.0) -> void:
	if _closing:
		return

	if not SOUNDS.has(id):
		push_warning("Efeito sonoro desconhecido: %s" % id)
		return

	# Evita a repetição excessiva de determinados sons.
	var now := Time.get_ticks_msec()
	var minimum_gap := 70 if id == &"ui_move" else (35 if id == &"rebote" else 0)

	if now - int(_last_effect_time.get(id, -1000)) < minimum_gap:
		return

	_last_effect_time[id] = now

	# Limita a quantidade de efeitos simultâneos.
	while effects.get_child_count() >= MAX_VOICES:
		_discard_voice(effects.get_child(0) as AudioStreamPlayer)

	# Cria um reprodutor independente para cada efeito.
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[id]
	player.bus = &"SFX"
	player.pitch_scale = clampf(pitch, 0.85, 1.15)
	player.volume_db = -14.0 if id == &"ui_move" else (-11.0 if id in [&"ui_confirm", &"laser"] else -7.0)
	player.set_meta("sound_id", id)

	effects.add_child(player)

	# Remove o reprodutor quando o som termina.
	player.finished.connect(_discard_voice.bind(player))
	player.play()
	effect_started.emit(id)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_update_volumes()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_update_volumes()
	save_settings()


func load_settings() -> void:
	# Recupera os volumes salvos anteriormente.
	var settings := ConfigFile.new()

	if settings.load(settings_path) == OK:
		music_volume = clampf(float(settings.get_value("audio", "music", 0.65)), 0.0, 1.0)
		sfx_volume = clampf(float(settings.get_value("audio", "sfx", 0.8)), 0.0, 1.0)

	_update_volumes()


func save_settings() -> void:
	# Persiste as preferências de áudio.
	var settings := ConfigFile.new()
	settings.set_value("audio", "music", music_volume)
	settings.set_value("audio", "sfx", sfx_volume)

	var error := settings.save(settings_path)

	if error != OK:
		push_warning("Não foi possível salvar os volumes: %s" % error_string(error))


func _update_volumes() -> void:
	_apply_bus_volume(&"Music", music_volume)
	_apply_bus_volume(&"SFX", sfx_volume)
	volumes_changed.emit(music_volume, sfx_volume)


func _apply_bus_volume(bus: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus)

	if index < 0:
		return

	# Converte o volume linear para decibéis.
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


func _discard_voice(player: AudioStreamPlayer) -> void:
	# Libera o reprodutor após o efeito.
	if not is_instance_valid(player) or player.is_queued_for_deletion():
		return

	player.stop()
	player.stream = null

	if player.get_parent() == effects:
		effects.remove_child(player)

	player.queue_free()


func quit_game(exit_code: int = 0) -> void:
	# Encerra os áudios antes de fechar o jogo.
	if _closing:
		return

	_closing = true
	stop_music()

	for player in effects.get_children():
		_discard_voice(player)

	await get_tree().create_timer(0.08).timeout
	get_tree().quit(exit_code)


func _exit_tree() -> void:
	# Interrompe os áudios ao remover o gerenciador.
	if is_instance_valid(music):
		music.stop()
		music.stream = null

	if is_instance_valid(effects):
		for player in effects.get_children():
			player.stop()
			player.stream = null


func _clear_effects(keep_feedback: bool = false) -> void:
	# Limpa efeitos, preservando os sons necessários.
	for player in effects.get_children():
		var id: StringName = player.get_meta("sound_id", &"")

		if id in [&"ui_move", &"ui_confirm"]:
			continue

		if keep_feedback and id in [&"vida", &"setor"]:
			continue

		_discard_voice(player)


func _on_state_changed(value: int) -> void:
	# Alterna músicas e efeitos conforme o estado do jogo.
	if value == _last_state:
		return

	_last_state = value

	match value:
		GameManager.State.MAIN_MENU:
			_clear_effects()
			play_music(MENU_MUSIC)

		GameManager.State.READY:
			_clear_effects(true)
			play_music(GAME_MUSIC)

		GameManager.State.PLAYING:
			play_music(GAME_MUSIC)

		GameManager.State.GAME_OVER:
			_clear_effects()
			stop_music()
			play_sfx(&"game_over")


func _on_lives_changed(value: int) -> void:
	# Reproduz o aviso somente quando uma vida é perdida.
	if value < _previous_lives and value > 0:
		play_sfx(&"vida")

	_previous_lives = value


func _on_power_up() -> void:
	# Reproduz o efeito de coleta durante a partida.
	if GameManager.started:
		play_sfx(&"coleta")


func _on_sector_cleared() -> void:
	# Reproduz o efeito de conclusão do setor.
	play_sfx(&"setor")
