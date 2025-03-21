class_name Trigger extends Resource
var trigger_position: Vector2
var trigger_type = "Base"
var trigger_sprite = null
var trigger_description = "Someone forgot to put a description here."

func execute(player: Node) -> void:
    pass

func inspect() -> String:
    return trigger_description

func update_state(data: Dictionary) -> void:
    pass