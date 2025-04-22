class_name ShieldResource extends ItemResource

# ===================== SHIELD RESOURCE =====================
# Base class for all shields

# Variables
@export var ac_bonus: int = 0
@export var speed_penalty: int = 0
@export var level: int = 0
@export var agi_cap: int = 0
@export var hardness: int = 0
@export var hit_points: int = 0
@export var current_hit_points: int = 0
@export var broken_threshold: int = 0

# ===================== SHIELD FUNCTIONS =====================
# Check if the shield is broken
# Args: None
# Returns: bool
func is_broken() -> bool:
	return hit_points <= broken_threshold

# Get the AC bonus of the shield
func get_ac_bonus() -> int:
	return ac_bonus

# Get the speed penalty of the shield
func get_speed_penalty() -> int:
	return speed_penalty

# Get the level of the shield
func get_level() -> int:
	return level

# Get the agility cap of the shield
func get_agi_cap() -> int:
	return agi_cap

# Get the hardness of the shield
func get_hardness() -> int:
	return hardness

# Get the hit points of the shield
func get_hit_points() -> int:
	return hit_points

func initialize_from_dict(data: Dictionary) -> void:
	super.initialize_from_dict(data)
	ac_bonus = data.get("ac_bonus", ac_bonus)
	level = data.get("level", level)
	speed_penalty = data.get("speed_penalty", speed_penalty)
	agi_cap = data.get("agi_cap", agi_cap)
	hardness = data.get("hardness", hardness)
	hit_points = data.get("hit_points", hit_points)
	if broken_threshold == 0:
		broken_threshold = floor(hit_points / 2)
	current_hit_points = data.get("current_hit_points", hit_points)

func get_dictionary() -> Dictionary:
	var shield_dict: Dictionary = super.get_dictionary()
	shield_dict["AC Bonus"] = ac_bonus
	shield_dict["Level"] = level
	shield_dict["Speed Penalty"] = speed_penalty
	shield_dict["Hardness"] = hardness
	shield_dict["Hit Points"] = str(current_hit_points) + "/" + str(hit_points)
	shield_dict["Broken Threshold"] = broken_threshold
	return shield_dict
