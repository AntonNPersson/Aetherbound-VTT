extends Node
@onready var startContainer: Control = $ScrollContainer
@onready var container: Control = $ScrollContainer/VBoxContainer
@onready var buttons: Control = $Buttons

func _ready() -> void:
	buttons.get_node("Settings").pressed.connect(open_settings)
	container.get_node("Back").pressed.connect(close_settings)
	buttons.get_node("Continue").pressed.connect(func(): self.visible = false)
	container.get_node("ResolutionOptions").item_selected.connect(Settings.set_resolution)
	container.get_node("DisplayOptions").item_selected.connect(Settings.set_display_mode)
	container.get_node("MasterSlider").value_changed.connect(Settings.set_master_volume)
	container.get_node("MusicSlider").value_changed.connect(Settings.set_music_volume)
	container.get_node("SFXSlider").value_changed.connect(Settings.set_sfx_volume)
	container.get_node("UISlider").value_changed.connect(Settings.set_menu_sfx_volume)
	container.get_node("ShowEmpty").toggled.connect(Settings.set_show_empty_values_on_character_sheet)

func open_settings() -> void:
	buttons.visible = false
	startContainer.visible = true

	container.get_node("DisplayOptions").selected = Settings.window_settings["display_mode"]
	container.get_node("MasterSlider").value = Settings.audio_settings["master_volume"]
	container.get_node("MusicSlider").value = Settings.audio_settings["music_volume"]
	container.get_node("SFXSlider").value = Settings.audio_settings["sfx_volume"]
	container.get_node("UISlider").value = Settings.audio_settings["menu_sfx_volume"]
	container.get_node("ShowEmpty").button_pressed = Settings.gameplay_settings["show_empty_values_on_character_sheet"]

func close_settings() -> void:
	buttons.visible = true
	startContainer.visible = false
