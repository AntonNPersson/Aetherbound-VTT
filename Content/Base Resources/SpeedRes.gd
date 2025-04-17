class_name SpeedResource extends Resource
@export var s_name: String
@export var description: String

func get_dictionary() -> Dictionary:
    return Helper.clean_dictionary({
        "name": s_name,
        "description": description
    })