extends Node2D
var map_settings: Dictionary = {}

@export var global_light: Node = null
@export var players_parent: Node = null

@rpc("any_peer", "call_local", "reliable")
func set_global_illumination(enabled: bool) -> void:
    Settings.global_illumination = enabled
    global_light.visible = enabled

    if !Net.is_host():
        set_players_line_of_sight(!enabled)


@rpc("any_peer", "call_local", "reliable")
func set_global_illumination_color(color: Color) -> void:
    Settings.global_illumination_color = color
    global_light.color = color

    if !Net.is_host():
        update_players_line_of_sight()

@rpc("any_peer", "call_local", "reliable")
func set_global_fog_color(color: Color) -> void:
    Settings.global_fog_color = color

    if !Net.is_host():
        update_players_line_of_sight()

@rpc("any_peer", "call_local", "reliable")
func set_global_vision_rays_count(count: int) -> void:
    match count:
        0:
            Settings.global_vision_rays_count = 256
        1:
            Settings.global_vision_rays_count = 128
        2:
            Settings.global_vision_rays_count = 64

func set_global_vision_color(color: Color) -> void:
    Settings.global_vision_color = color
    for player in get_all_player_tokens():
        player.set_vision_color.rpc_id(player.name.to_int(), color)

# Players
func get_player_token(player_id: int) -> Node2D:
    return players_parent.get_node(str(player_id))

func get_all_player_tokens() -> Array:
    var all_players = []
    for player_id in Net.get_players_ids():
        all_players.append(get_player_token(player_id))
    return all_players

func update_players_line_of_sight():
    for player in get_all_player_tokens():
        player.update_line_of_sight()

func set_players_line_of_sight(enabled: bool):
    for player in get_all_player_tokens():
        if enabled:
            player.show_line_of_sight()
        else:
            player.hide_line_of_sight()

