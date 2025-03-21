extends Node

# ===================== USER VARIABLES =======================
# User settings VARIABLES

# Window/Viewport VARIABLES
var window_settings = {
    "width": DisplayServer.window_get_size().x,
    "height": DisplayServer.window_get_size().y,
    "resolution": Vector2(DisplayServer.window_get_size().x, DisplayServer.window_get_size().y),
    "font_size": 24 if DisplayServer.window_get_size().x > 1920 else 12
}

var custom_windows = {
    "MessageBox": preload("res://UI/Instances/message_box.tscn"),
    "MessageBox3K": preload("res://UI/Instances/message_box_3k.tscn"),
    "Menu": preload("res://UI/Instances/menu_ui.tscn"),
    "Menu3K": preload("res://UI/Instances/menu_ui_3k.tscn")
}

# ===================== GM VARIABLES =========================
func _ready():
    # Create a new theme or get the default theme
    var theme = ThemeDB.get_default_theme()
    
    # Set the default font size for all text controls
    theme.set_default_font_size(window_settings["font_size"])
    
    # Apply theme to the root node (affects all children)
    get_tree().root.theme = theme

func get_ui_instance(ui_name: String) -> Node:
    # Get current window size
    var window_width = DisplayServer.window_get_size().x
    
    # Determine if we should use high-res version (3K)
    var use_high_res = window_width > 1920
    
    # Select the appropriate scene
    var scene_key = ui_name
    if use_high_res:
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

# ALL

