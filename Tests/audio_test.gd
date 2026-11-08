
extends SceneTree

# Referências aos gerenciadores e resultados dos testes.
var audio: Node
var manager: Node
var checks := 0
var failures: Array[String] = []
var music_events: Array[AudioStream] = []
var effect_events: Array[StringName] = []
var volume_events: Array[Vector2] = []
var bullets_created := 0

# Arquivos temporários para preservar os dados do jogador.
var settings_path := ""
var records_path := ""


func _initialize() -> void:
	# Inicia os testes após a inicialização da árvore.
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	# Registra o resultado de cada verificação.
	checks += 1

	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)


func frames(count := 3) -> void:
	# Aguarda a quantidade solicitada de frames.
	for index in count:
		await process_frame


func voices() -> Array[AudioStreamPlayer]:
	# Retorna os efeitos sonoros ainda ativos.
	var result: Array[AudioStreamPlayer] = []

	for child in audio.effects.get_children():
		if child is AudioStreamPlayer and not child.is_queued_for_deletion():
			result.append(child)

	return result


func has_voice(id: StringName) -> bool:
	# Verifica se determinado efeito está sendo reproduzido.
	for voice in voices():
		if voice.playing and voice.stream != null and voice.stream.resource_path.ends_with("/%s.wav" % id):
			return true

	return false


func track_bullet(node: Node) -> void:
	# Conta os projéteis criados sem permitir colisões acidentais.
	if node.scene_file_path == "res://Scenes/bullet.tscn":
		bullets_created += 1
		node.set_physics_process(false)
		node.set_physics_process.call_deferred(false)
		node.monitoring = false


func blocks(node: Node) -> Array[Node2D]:
	# Localiza recursivamente os blocos destrutíveis.
	var result: Array[Node2D] = []

	for child in node.get_children():
		if child.has_method("destroy"):
			result.append(child)

		result.append_array(blocks(child))

	return result


func _run() -> void:
	# Prepara o ambiente e os arquivos isolados de teste.
	root.size = Vector2i(960, 576)

	audio = root.get_node_or_null("AudioManager")
	manager = root.get_node("GameManager")

	check(audio != null and audio.get_script() != null, "autoload AudioManager carregado sem erros")

	if audio == null or audio.get_script() == null:
		_finish()
		return

	settings_path = "/private/tmp/super-arkanoid-audio-%d.cfg" % OS.get_process_id()
	records_path = "/private/tmp/super-arkanoid-audio-record-%d.cfg" % OS.get_process_id()

	audio.settings_path = settings_path
	manager.records_path = records_path

	# Registra os sinais emitidos durante os testes.
	audio.music_changed.connect(func(track: AudioStream): music_events.append(track))
	audio.effect_started.connect(func(id: StringName): effect_events.append(id))
	audio.volumes_changed.connect(func(music_value: float, sfx_value: float):
		volume_events.append(Vector2(music_value, sfx_value)))

	# Executa as verificações do sistema de áudio.
	_verify_assets_and_buses()
	_verify_volumes()
	await _verify_players()
	await _verify_mix()
	await _verify_game_events()

	_finish()


func _verify_assets_and_buses() -> void:
	# Verifica os canais e arquivos de áudio.
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")

	check(AudioServer.get_bus_index("Master") == 0 and music_bus > 0 and sfx_bus > 0
		and music_bus != sfx_bus, "buses Master, Music e SFX separados")

	check(audio.music is AudioStreamPlayer and audio.music.bus == &"Music",
		"player permanente de música usa o bus Music")

	# Confere músicas com reprodução contínua.
	for id in ["menu", "partida"]:
		var stream := load("res://Audio/Music/%s.wav" % id) as AudioStreamWAV

		check(stream != null and stream.get_length() > 0
			and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"música %s contém áudio e repetição contínua" % id)

	# Confere efeitos que devem tocar apenas uma vez.
	for id in ["rebote", "bloco", "laser", "coleta", "vida", "game_over", "iniciar", "setor", "ui_move", "ui_confirm"]:
		var stream := load("res://Audio/SFX/%s.wav" % id) as AudioStreamWAV

		check(stream != null and stream.get_length() > 0
			and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			"efeito %s contém áudio sem repetição" % id)


func _verify_volumes() -> void:
	# Testa limites, canais independentes e persistência.
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")

	audio.set_music_volume(-1.0)
	audio.set_sfx_volume(2.0)

	check(audio.music_volume == 0.0 and AudioServer.is_bus_mute(music_bus)
		and audio.sfx_volume == 1.0 and not AudioServer.is_bus_mute(sfx_bus),
		"volumes limitados a 0–1 e música silenciada em zero")

	audio.set_music_volume(2.0)
	audio.set_sfx_volume(-1.0)

	check(audio.music_volume == 1.0 and not AudioServer.is_bus_mute(music_bus)
		and audio.sfx_volume == 0.0 and AudioServer.is_bus_mute(sfx_bus),
		"limites e silêncio também funcionam no bus SFX")

	audio.set_music_volume(0.3)
	audio.set_sfx_volume(0.7)

	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.3)
		and is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)), 0.7),
		"volumes independentes aplicados aos respectivos buses")

	check(not volume_events.is_empty() and volume_events.back().is_equal_approx(Vector2(0.3, 0.7)),
		"sinal comunica os volumes atualizados à interface")

	audio.save_settings()

	check(FileAccess.file_exists(settings_path), "configuração de áudio salva em arquivo isolado")

	# Modifica os valores em memória para testar a restauração.
	audio.music_volume = 0.9
	audio.sfx_volume = 0.1
	audio.load_settings()

	check(is_equal_approx(audio.music_volume, 0.3) and is_equal_approx(audio.sfx_volume, 0.7),
		"configuração de áudio restaurada do arquivo local")


func _verify_players() -> void:
	# Testa reprodução, troca de músicas e gerenciamento de efeitos.
	var menu: AudioStream = load("res://Audio/Music/menu.wav")
	var game: AudioStream = load("res://Audio/Music/partida.wav")

	audio.stop_music()
	music_events.clear()

	audio.play_music(menu)
	await create_timer(0.18).timeout

	var previous_position: float = audio.music.get_playback_position()

	audio.play_music(menu)
	await create_timer(0.18).timeout

	# Verifica se a mesma música continua sem reiniciar.
	check(music_events.size() == 1 and audio.music.playing and audio.music.stream == menu
		and audio.music.get_playback_position() > previous_position,
		"pedir a mesma música mantém a reprodução sem reiniciar nem duplicar players")

	audio.play_music(game)

	check(music_events.size() == 2 and audio.music.stream == game,
		"troca de faixa substitui a música no mesmo player")

	audio.stop_music()

	check(not audio.music.playing, "stop_music interrompe a reprodução")

	# Verifica a criação e liberação automática dos efeitos.
	await create_timer(0.8).timeout
	audio.play_sfx(&"rebote")

	check(has_voice(&"rebote"), "efeito cria um player SFX em reprodução")

	check(voices().all(func(voice: AudioStreamPlayer): return voice.bus == &"SFX"),
		"efeitos são encaminhados ao bus SFX")

	var rebound: AudioStream = load("res://Audio/SFX/rebote.wav")

	await create_timer(rebound.get_length() + 0.2).timeout

	check(voices().is_empty(), "fim do efeito remove automaticamente o player transitório")

	# Testa o limite de 16 efeitos simultâneos.
	for index in 40:
		audio.play_sfx(&"bloco")

	check(voices().size() <= 16, "rajada de efeitos respeita o limite de 16 vozes")

	await create_timer(0.8).timeout

	check(voices().is_empty(), "vozes da rajada também são liberadas após os efeitos")


func _verify_game_events() -> void:
	# Testa a integração do áudio com menus e eventos da partida.
	manager._set_state(manager.State.READY)
	manager.enter_menu()

	change_scene_to_file("res://Scenes/UI/main_menu.tscn")
	await frames(5)

	check(audio.music.playing and audio.music.stream.resource_path.ends_with("/menu.wav"),
		"menu principal seleciona sua música")

	# Verifica os controles de volume do menu.
	var music_slider: HSlider = current_scene.get_node("MusicVolume")
	var sfx_slider: HSlider = current_scene.get_node("SFXVolume")

	check(is_equal_approx(music_slider.value, 0.3) and is_equal_approx(sfx_slider.value, 0.7),
		"controles do menu exibem os volumes carregados")

	music_slider.value = 0.0
	sfx_slider.value = 0.5

	check(audio.music_volume == 0.0 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
		and is_equal_approx(audio.sfx_volume, 0.5), "controles do menu ajustam e silenciam os canais independentemente")

	music_slider.value = 0.3
	sfx_slider.value = 0.7

	# Inicia a partida e verifica a transição musical.
	effect_events.clear()
	music_events.clear()

	current_scene.get_node("StartButton").pressed.emit()
	await frames(5)

	var world: Node = current_scene.get_node("Level")
	var ball: CharacterBody2D = world.get_node("Ball")
	var player: CharacterBody2D = world.get_node("Player")
	var environment: Node = world.get_node("Environment")

	check(audio.music.playing and audio.music.stream.resource_path.ends_with("/partida.wav")
		and music_events.size() == 1, "início da partida troca para sua música uma única vez")

	ball.play_game()
	ball.set_physics_process(false)

	check(effect_events.count(&"iniciar") == 1, "início da partida ou lançamento emite um som de início")

	check(music_events.size() == 1, "transição READY para PLAYING não reinicia a música")

	# Testa a coleta e a sequência automática de lasers.
	effect_events.clear()
	node_added.connect(track_bullet)

	manager.on_powerup.emit()
	await create_timer(1.55).timeout

	check(effect_events.count(&"coleta") == 1, "coleta do item emite seu efeito uma única vez")

	check(bullets_created == 16 and player.get_node("SpawnShootTimer").is_stopped()
		and manager.power_up_shots == 0, "áudio preserva a sequência original de 16 projéteis")

	check(effect_events.count(&"laser") == 8, "cada dupla de disparos emite um efeito de laser")

	node_added.disconnect(track_bullet)

	# Simula uma colisão real com um bloco.
	var target: Node2D

	for block in blocks(world.get_node("Blocks")):
		if target == null or block.global_position.y > target.global_position.y:
			target = block

	effect_events.clear()

	ball.global_position = target.global_position + Vector2(40, 48)
	ball.velocity = Vector2(0, -250)
	ball.set_physics_process(true)

	await create_timer(0.14).timeout
	ball.set_physics_process(false)

	check(effect_events.count(&"bloco") == 1 and effect_events.count(&"rebote") == 0,
		"destruição real toca o efeito do bloco sem duplicar o som de rebote")

	check(manager.score == 100 and manager.blocks_remaining == 47,
		"efeitos de colisão preservam pontuação e blocos")

	# Simula uma colisão com a parede.
	effect_events.clear()

	ball.position = Vector2(620, 300)
	ball.velocity = Vector2(250, 0)
	ball.set_physics_process(true)

	await create_timer(0.14).timeout
	ball.set_physics_process(false)

	check(effect_events.count(&"rebote") == 1 and ball.velocity.x < 0,
		"colisão real com a parede emite o efeito de rebote")

	# Testa perda de vida sem duplicação de efeitos.
	effect_events.clear()
	var music_count := music_events.size()

	environment._on_death_zone_body_entered(ball)
	environment._on_death_zone_body_entered(ball)

	check(effect_events.count(&"vida") == 1 and manager.lives == 2 and has_voice(&"vida"),
		"mesma queda emite só um efeito de perda de vida")

	check(music_events.size() == music_count and audio.music.playing,
		"reposição da tentativa mantém a música contínua")

	# Consome as vidas restantes para testar o Game Over.
	await create_timer(2.1).timeout

	ball.play_game()
	ball.set_physics_process(false)
	environment._on_death_zone_body_entered(ball)

	await create_timer(2.1).timeout

	ball.play_game()
	ball.set_physics_process(false)

	effect_events.clear()
	environment._on_death_zone_body_entered(ball)

	check(manager.state == manager.State.GAME_OVER and not audio.music.playing
		and effect_events.count(&"game_over") == 1 and effect_events.count(&"vida") == 0,
		"última vida interrompe a música e toca GAME OVER uma única vez")

	manager.state_changed.emit(manager.State.GAME_OVER)

	check(effect_events.count(&"game_over") == 1, "notificação repetida não duplica o efeito de Game Over")

	# Inicia outra partida para testar a conclusão de setor.
	manager.new_game()
	await frames(5)

	world = current_scene.get_node("Level")
	ball = world.get_node("Ball")
	ball.play_game()
	ball.set_physics_process(false)

	effect_events.clear()
	music_events.clear()

	for block in blocks(world.get_node("Blocks")):
		block.destroy()

	check(effect_events.count(&"setor") == 1, "concluir a formação toca um único efeito de setor")

	await create_timer(1.45).timeout

	check(manager.level == 2 and manager.blocks_remaining == 48 and audio.music.playing
		and music_events.is_empty(), "setor seguinte mantém a trilha sem interrupção")

	# Verifica a limpeza dos efeitos ao retornar ao menu.
	audio.play_sfx(&"laser")
	audio.play_sfx(&"ui_confirm")
	manager.return_to_menu()

	check(not has_voice(&"laser") and has_voice(&"ui_confirm"),
		"voltar ao menu limpa efeitos de jogo e preserva a confirmação da interface")

	await frames(5)

	check(audio.music.playing and audio.music.stream.resource_path.ends_with("/menu.wav"),
		"retorno ao menu restaura a música do menu")


func _verify_mix() -> void:
	# Captura amostras da mistura de música e efeitos.
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 0.5

	var position := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, capture)

	audio.play_music(load("res://Audio/Music/menu.wav"))
	audio.play_sfx(&"laser")

	await create_timer(0.25).timeout

	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0

	for sample in samples:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))

	check(not samples.is_empty() and peak > 0.0001,
		"mistura real de música e efeito produz amostras de áudio não nulas")

	# Remove o capturador temporário após o teste.
	AudioServer.remove_bus_effect(0, position)
	audio.stop_music()


func _finish() -> void:
	# Remove arquivos temporários e apresenta o resultado.
	for path in [settings_path, records_path]:
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	print("AUDIO RESULT: %d checks, %d failures" % [checks, failures.size()])

	# Finaliza o processo com o código de resultado.
	if is_instance_valid(audio):
		audio.quit_game(0 if failures.is_empty() else 1)
	else:
		quit(1)
