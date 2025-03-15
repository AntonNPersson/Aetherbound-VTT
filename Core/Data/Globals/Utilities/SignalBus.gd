extends Node
# ===================== SIGNAL BUS =====================
# Bus for sending signals between nodes, toot, toot
# =====================================================
# lobby signals
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal player_reconnected(peer_id, old_peer_id, uuid)

# network signals
signal all_players_loaded()
signal player_connection_failed()
signal map_recieved()
signal map_sent(map_name: String)
signal all_maps_recieved()

# map signals
signal map_initialized()
signal map_changed(map_index, local, player_ids)
signal map_data_changed()
signal open_map_changer(player_id)
signal data_added()