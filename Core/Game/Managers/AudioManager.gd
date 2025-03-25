extends Node

var hover_sound = preload("res://Assets/Audio/UI/button-hover.mp3")
var click_sound = preload("res://Assets/Audio/UI/button-click.mp3")
var audio_player: AudioStreamPlayer
var sfx_audio_player: AudioStreamPlayer
var music_audio_player: AudioStreamPlayer

func _ready():
	# Create a persistent audio player
	audio_player = AudioStreamPlayer.new()
	sfx_audio_player = AudioStreamPlayer.new()
	music_audio_player = AudioStreamPlayer.new()
	audio_player.bus = "UI"
	add_child(audio_player)
	add_child(sfx_audio_player)
	add_child(music_audio_player)
	
	# Connect to node added signal to catch new buttons
	get_tree().connect("node_added", _on_node_added)
	
	# Connect to existing buttons
	_connect_to_existing_buttons()

func _connect_to_existing_buttons():
	# Find all buttons in the scene tree regardless of groups
	var buttons = []
	_find_all_buttons(get_tree().root, buttons)
	
	for button in buttons:
		_connect_button_signals(button)

func _find_all_buttons(node, buttons_array):
	# Recursively find all button nodes
	if node is Button:
		buttons_array.append(node)
	elif node is TextureButton:
		buttons_array.append(node)
	
	for child in node.get_children():
		_find_all_buttons(child, buttons_array)

func _on_node_added(node):
	# When a new node is added to the scene, check if it's a button
	if node is Button:
		_connect_button_signals(node)
	elif node is TextureButton:
		_connect_button_signals(node)

func _connect_button_signals(button):
	# Avoid duplicate connections
	if not button.is_connected("mouse_entered", _on_button_hover):
		if button.disabled:
			return
		button.connect("mouse_entered", _on_button_hover)
	if not button.is_connected("pressed", _on_button_pressed):
		button.connect("pressed", _on_button_pressed)

func _on_button_hover():
	# Get current SFX volume from settings and convert to dB
	var final_volume = Settings.audio_settings["menu_sfx_volume"] * Settings.audio_settings["master_volume"]
	var volume_db = linear_to_db(final_volume)
	
	# Add any offset you want for hover sounds (e.g. make them slightly quieter)
	volume_db -= 5.0  # Make hover sound 5dB quieter than regular SFX
	
	# Play hover sound
	audio_player.stream = hover_sound
	audio_player.volume_db = volume_db
	audio_player.play()

func _on_button_pressed():
	# Get current SFX volume from settings and convert to dB
	var final_volume = Settings.audio_settings["menu_sfx_volume"] * Settings.audio_settings["master_volume"]
	var volume_db = linear_to_db(final_volume)
	
	# Play click sound
	audio_player.stream = click_sound
	audio_player.volume_db = volume_db
	audio_player.play()

func linear_to_db(linear_value: float) -> float:
	if linear_value <= 0:
		return -80.0  # Effectively silent
	return 20.0 * log(linear_value) / log(10.0)

func play_sfx_audio(stream: AudioStream, pitch_scale: float = 1.0):
	var final_volume = Settings.audio_settings["sfx_volume"] * Settings.audio_settings["master_volume"]
	var volume_db = linear_to_db(final_volume)
	sfx_audio_player.stream = stream
	sfx_audio_player.volume_db = volume_db
	sfx_audio_player.pitch_scale = pitch_scale
	sfx_audio_player.play()

func play_music_audio(stream: AudioStream, pitch_scale: float = 1.0):
	var final_volume = Settings.audio_settings["music_volume"] * Settings.audio_settings["master_volume"]
	var volume_db = linear_to_db(final_volume)

	music_audio_player.stream = stream
	music_audio_player.volume_db = volume_db
	music_audio_player.pitch_scale = pitch_scale
	music_audio_player.play()
