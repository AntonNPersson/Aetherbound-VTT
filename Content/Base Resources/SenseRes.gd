class_name SenseResource extends Resource
@export var s_name: String
@export var description: String
@export var precision: GameConst.SensePrecision = GameConst.SensePrecision.PRECISE

func get_precision() -> GameConst.SensePrecision:
    return precision

func get_precision_as_string() -> String:
    match precision:
        GameConst.SensePrecision.PRECISE:
            return "PRECISE"
        GameConst.SensePrecision.IMPRECISE:
            return "IMPRECISE"
        GameConst.SensePrecision.VAGUE:
            return "VAGUE"
        _:
            return "UNKNOWN"

func set_precision(p_precision: GameConst.SensePrecision) -> void:
    precision = p_precision

func set_precision_by_string(p_precision: String) -> void:
    p_precision = p_precision.strip_edges().to_upper()
    match p_precision:
        "PRECISE":
            precision = GameConst.SensePrecision.PRECISE
        "IMPRECISE":
            precision = GameConst.SensePrecision.IMPRECISE
        "VAGUE":
            precision = GameConst.SensePrecision.VAGUE
        _:
            precision = GameConst.SensePrecision.PRECISE

func get_dictionary() -> Dictionary:
    return Helper.clean_dictionary({
        "name": s_name,
        "description": description,
        "precision": get_precision_as_string()
    })