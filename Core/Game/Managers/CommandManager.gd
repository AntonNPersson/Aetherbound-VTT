class_name CommandManager extends Node

var command_history = []
var undo_history = []
var current_player_id = 0

func execute_command(command: Command) -> void:
    command.execute()
    command_history.append(command)
    current_player_id = command.player_id

func undo_command() -> void:
    if command_history.size() == 0:
        return
    var command = command_history.pop_back()
    command.undo()
    undo_history.append(command)

func redo_command() -> void:
    if undo_history.size() == 0:
        return
    var command = undo_history.pop_back()
    command.execute()
    command_history.append(command)

func end_turn() -> void:
    undo_history.clear()