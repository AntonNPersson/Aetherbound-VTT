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
signal draw_ability(ability_name: String, type: String, start_position: Vector2, keep: bool, global: bool, user: Node, emanation_type: int)
signal send_affected_tiles(ability_name: String, tiles: Array, user: Node)
signal untoggle_all_drawings()

signal send_roll_to_all(sender: String, info: String, target: String, roll_data: Dictionary, target_value: String, result: String)
signal send_roll_to_self(sender: String, info: String, target: String, roll_data: Dictionary, target_value: String, result: String)
signal send_roll_to_gm(sender: String, info: String, target: String, roll_data: Dictionary, target_value: String, result: String)

signal send_combat_value(value: Variant, world_position: Vector2, color: Color)
signal send_announcement(announcement: String, color: Color)
signal send_announcement_to_player(player_id: int, announcement: String, color: Color)

signal send_error_message(message: String)

signal create_base_context_panel(object: Variant)
signal create_sidebar_context_panel(object: Variant)
signal create_sidebar_combat_context_panel(objects: Variant)
signal create_sidebar_resource_panel(object: Variant)
signal create_combat_tracker(player_id: int, all_combatants: Array, owned_combatants: Array)
signal delete_combat_tracker()
signal pause_map_input(state: bool)

signal start_combat(tokens: Array)
signal initialize_turn_order(combat_id: int, combatants: Array)
signal add_comtatants_to_tracker(combatants: Array)
signal end_turn(combat_id: int)
signal turn_started(combatant: Variant)

signal update_resource_content()
signal delete_resource_content(object: Variant)
signal remove_token(token_name: String, token_position: Vector2)

signal select_lobby(lobby: Dictionary)

signal update_shader_wall_data()

signal send_tile_size(size: Vector2)