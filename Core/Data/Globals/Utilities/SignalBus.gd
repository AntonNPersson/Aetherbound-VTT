extends Node
# ===================== SIGNAL BUS =====================
# Bus for sending signals between nodes, toot, toot
# =====================================================
signal apply_map_settings_to_player(player_id: int, settings: Dictionary)
signal send_message_to_player(player_id: int, message: String, level: String)
signal send_message_to_all(message: String, level: String)
signal send_environment_message_to_player(player_id: int, message: String, level: String)
signal send_environment_message_to_all(message: String, level: String)
signal send_whisper_message(player_id: int, message: String)

signal wall_clicked(points: Array)