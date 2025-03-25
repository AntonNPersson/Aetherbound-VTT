extends Node
var buttons = null
var settings = null
var video = null
var audio = null

func _ready() -> void:
	buttons = get_node("Buttons")
	settings = get_node("Settings")
	video = settings.get_node("Video")
	audio = settings.get_node("Audio")

	buttons.get_node("Settings").pressed.connect(open_settings)
	settings.get_node("Back").pressed.connect(close_settings)
	buttons.get_node("Continue").pressed.connect(func(): self.visible = false)
	video.get_node("Resolution").get_node("Options").item_selected.connect(Settings.set_resolution)
	video.get_node("Display Mode").get_node("Options").item_selected.connect(Settings.set_display_mode)
	audio.get_node("Master Volume").get_node("Slider").value_changed.connect(Settings.set_master_volume)
	audio.get_node("Music Volume").get_node("Slider").value_changed.connect(Settings.set_music_volume)
	audio.get_node("SFX Volume").get_node("Slider").value_changed.connect(Settings.set_sfx_volume)
	audio.get_node("UI Volume").get_node("Slider").value_changed.connect(Settings.set_menu_sfx_volume)

func open_settings() -> void:
	buttons.visible = false
	settings.visible = true

	video.get_node("Display Mode").get_node("Options").selected = Settings.window_settings["display_mode"]
	audio.get_node("Master Volume").get_node("Slider").value = Settings.audio_settings["master_volume"]
	audio.get_node("Music Volume").get_node("Slider").value = Settings.audio_settings["music_volume"]
	audio.get_node("SFX Volume").get_node("Slider").value = Settings.audio_settings["sfx_volume"]
	audio.get_node("UI Volume").get_node("Slider").value = Settings.audio_settings["menu_sfx_volume"]

func close_settings() -> void:
	buttons.visible = true
	settings.visible = false
