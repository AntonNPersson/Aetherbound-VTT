extends Node
# ===================== SIGNAL BUS =====================
# Bus for sending signals between nodes, toot, toot
# =====================================================
var pause_busy = false

signal apply_map_settings_to_player(player_id: int, settings: Dictionary)
signal send_message_to_player(player_id: int, message: String, level: String)
signal send_message_to_all(message: String, level: String)
signal send_environment_message_to_player(player_id: int, message: String, level: String)
signal send_environment_message_to_all(message: String, level: String)
signal send_whisper_message(player_id: int, message: String)

signal wall_clicked(points: Array)

signal cancel_ability_drawing(ability_name: String)
signal draw_ability(ability_name: String, type: String, start_position: Vector2, keep: bool, global: bool, user: Node)
signal send_affected_tiles(ability_name: String, tiles: Array, user: Node)
