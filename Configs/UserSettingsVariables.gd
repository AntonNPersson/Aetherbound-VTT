extends Node

# ===================== USER VARIABLES =======================
# User settings VARIABLES

# Window/Viewport VARIABLES
var window_settings = {
	"width": DisplayServer.window_get_size().x,
	"height": DisplayServer.window_get_size().y,
	"resolution": Vector2(DisplayServer.window_get_size().x, DisplayServer.window_get_size().y),
	"display_mode": 0,
	"font_size": 18 if DisplayServer.window_get_size().x > 1920 else 12
}

var custom_windows = {
	"MessageBox": preload("res://UI/Instances/message_box.tscn"),
	"MessageBox3K": preload("res://UI/Instances/message_box_3k.tscn"),
	"Menu": preload("res://UI/Instances/menu_ui.tscn"),
	"Menu3K": preload("res://UI/Instances/menu_ui_3k.tscn")
}

var audio_settings = {
	"master_volume": 1.0,
	"music_volume": 0.5,
	"sfx_volume": 0.5,
	"menu_sfx_volume": 0.2
}

func set_master_volume(value: float) -> void:
	audio_settings["master_volume"] = value
	save_settings()

func set_music_volume(value: float) -> void:
	audio_settings["music_volume"] = value
	save_settings()

func set_sfx_volume(value: float) -> void:
	audio_settings["sfx_volume"] = value
	save_settings()

func set_menu_sfx_volume(value: float) -> void:
	audio_settings["menu_sfx_volume"] = value
	save_settings()

func set_resolution(index: int) -> void:
	var resolution = SettingConst.RESOLUTIONS[index]
	var width = resolution[0]
	var height = resolution[1]

	# Store in settings
	window_settings["width"] = width
	window_settings["height"] = height
	window_settings["resolution"] = Vector2(width, height)
	window_settings["font_size"] = 16 if width > 1920 else 12
	
	# Get current window mode
	var current_mode = DisplayServer.window_get_mode()
	
	match current_mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_size(Vector2i(width, height))
			
			var screen_size = DisplayServer.screen_get_size()
			var centered_pos = (screen_size - Vector2i(width, height)) / 2
			DisplayServer.window_set_position(centered_pos)
			
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			get_tree().root.size = Vector2i(width, height)
			
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			get_tree().root.size = Vector2i(width, height)
	
	save_settings()

func set_display_mode(index: int) -> void:
	match index:
		0:
			# Set to windowed with borders at a specific size
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			window_settings["display_mode"] = 0
		1:
			# First set borderless flag, then maximize
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			window_settings["display_mode"] = 1
		2:
			# Standard fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			window_settings["display_mode"] = 2
	save_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Save window settings
	config.set_value("window", "width", window_settings["width"])
	config.set_value("window", "height", window_settings["height"])
	config.set_value("window", "resolution_x", window_settings["resolution"].x)
	config.set_value("window", "resolution_y", window_settings["resolution"].y)
	config.set_value("window", "font_size", window_settings["font_size"])
	
	# Save display mode if it exists
	if window_settings.has("display_mode"):
		config.set_value("window", "display_mode", window_settings["display_mode"])
	
	# Save audio settings
	config.set_value("audio", "master_volume", audio_settings["master_volume"])
	config.set_value("audio", "music_volume", audio_settings["music_volume"])
	config.set_value("audio", "sfx_volume", audio_settings["sfx_volume"])
	config.set_value("audio", "menu_sfx_volume", audio_settings["menu_sfx_volume"])
	
	# Save any other settings you might add later
	
	# Write to disk
	var error = config.save("user://Settings/UserSettings.cfg")
	if error != OK:
		print("Failed to save settings: ", error)

func load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://Settings/UserSettings.cfg")
	
	# If the file doesn't exist or there's another error, use default values
	if error != OK:
		print("No settings file found or error loading. Using defaults.")
		# Defaults are already set in the variable declarations
		return
	
	# Load window settings
	window_settings["width"] = config.get_value("window", "width", DisplayServer.window_get_size().x)
	window_settings["height"] = config.get_value("window", "height", DisplayServer.window_get_size().y)
	
	var res_x = config.get_value("window", "resolution_x", DisplayServer.window_get_size().x)
	var res_y = config.get_value("window", "resolution_y", DisplayServer.window_get_size().y)
	window_settings["resolution"] = Vector2(res_x, res_y)
	
	window_settings["font_size"] = config.get_value("window", "font_size", 24 if res_x > 1920 else 12)
	
	# Load display mode if it exists
	if config.has_section_key("window", "display_mode"):
		window_settings["display_mode"] = config.get_value("window", "display_mode", 0)
	
	# Load audio settings
	audio_settings["master_volume"] = config.get_value("audio", "master_volume", 1.0)
	audio_settings["music_volume"] = config.get_value("audio", "music_volume", 0.5)
	audio_settings["sfx_volume"] = config.get_value("audio", "sfx_volume", 0.5)
	audio_settings["menu_sfx_volume"] = config.get_value("audio", "menu_sfx_volume", 0.2)


# Apply settings to the game
func apply_settings() -> void:
	# Apply resolution and display mode
	if window_settings.has("display_mode"):
		set_display_mode(window_settings["display_mode"])
	else:
		# Default to windowed mode
		set_display_mode(2)
	var resolution_index = SettingConst.RESOLUTIONS.find(Vector2i(window_settings["resolution"]))
	set_resolution(resolution_index)

	# Apply audio settings
	set_master_volume(audio_settings["master_volume"])
	set_music_volume(audio_settings["music_volume"])
	set_sfx_volume(audio_settings["sfx_volume"])
	set_menu_sfx_volume(audio_settings["menu_sfx_volume"])
# ===================== GM VARIABLES =========================
func _ready():
	# Create a new theme or get the default theme
	var theme = ThemeDB.get_default_theme()
	
	# Set the default font size for all text controls
	theme.set_default_font_size(window_settings["font_size"])
	
	# Apply theme to the root node (affects all children)
	get_tree().root.theme = theme

func get_ui_instance(ui_name: String, forced_low: bool = true) -> Node:
	# Get current window size
	var window_width = DisplayServer.window_get_size().x
	
	# Determine if we should use high-res version (3K)
	var use_high_res = window_width > 1920
	
	# Select the appropriate scene
	var scene_key = ui_name
	if use_high_res and not forced_low:
		scene_key += "3K"
	
	# Check if the key exists
	if not scene_key in custom_windows:
		push_error("UI scene not found: " + scene_key)
		# Try to fall back to non-3K version if 3K doesn't exist
		if use_high_res and ui_name in custom_windows:
			scene_key = ui_name
		else:
			return null
	
	# Instantiate a new instance
	return custom_windows[scene_key].instantiate()

func _on_first_startup() -> void:
	pass
	var settings_file = DirAccess.open("user://Settings")
	if settings_file == null or !FileAccess.file_exists("user://Settings/UserSettings.cfg"):
		# Get the screen resolution
		var screen_size = DisplayServer.screen_get_size()
		
		# Find the closest resolution in the available resolutions
		var closest_resolution_index = 0
		var min_diff = INF
		for i in range(SettingConst.RESOLUTIONS.size()):
			var resolution = SettingConst.RESOLUTIONS[i]
			var diff = abs(resolution[0] - screen_size.x) + abs(resolution[1] - screen_size.y)
			if diff < min_diff:
				min_diff = diff
				closest_resolution_index = i
		
		# Set the resolution to the closest match
		set_resolution(closest_resolution_index)
		
		# Set to fullscreen mode
		set_display_mode(2)
		
		# Save the settings so this doesn't run again
		save_settings()
	

# Lobby 
var is_player = false
var prologue_map = ""
var prologue_index = 0

# GM
const RAY_COUNT_MAPPING: Array[int] = [1024, 756, 512]
var map_settings = {
	"global_illumination": false,
	"global_illumination_color": Color(1, 1, 1, 1),
	"global_illumination_presets": ["Night", "Day"],
	"global_fog_color": Color(0, 0, 0, 1),
	"global_fog_presets": ["Dark", "Dim", "Bright"],
	"global_vision_rays_count": 512,
	"global_vision_color": Color(1, 1, 1, 0)
}

var default_map_settings = {
	"global_illumination": false,
	"global_illumination_color": Color(1, 1, 1, 1),
	"global_illumination_presets": ["Night", "Day"],
	"global_fog_color": Color(0, 0, 0, 1),
	"global_fog_presets": ["Dark", "Dim", "Bright"],
	"global_vision_rays_count": 512,
	"global_vision_color": Color(1, 1, 1, 0)
}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		window_settings.clear()
		audio_settings.clear()
		map_settings.clear()