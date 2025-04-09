class_name MonsterSheet extends Resource

# Basic info
@export var monster_name: String = "Default Monster"
@export var flavor_text: String = ""
@export_multiline var description: String = ""

# Basic stats
@export var level: int = 0
@export var gender: String = "Male"
@export var size: GameConst.MonsterSize = GameConst.MonsterSize.MEDIUM
@export var base_speed: int = 30 # Base speed
@export var base_swim_speed: int = 0 # Swim speed
@export var base_fly_speed: int = 0 # Fly speed
@export var base_climb_speed: int = 0 # Climb speed
@export var base_burrow_speed: int = 0 # Burrow speed
@export var base_armor_class: int = 10

# Attributes (Storing Scores)
@export var might_modifier: int = 0
@export var agility_modifier: int = 0
@export var endurance_modifier: int = 0
@export var intelligence_modifier: int = 0
@export var insight_modifier: int = 0
@export var charisma_modifier: int = 0

# Defenses
@export var damage_immunities: Array[GameConst.DamageType] = []
@export var damage_resistances: Array[GameConst.DamageType] = []
@export var damage_weaknesses: Array[GameConst.DamageType] = []
@export var condition_immunities: Array[GameConst.Condition] = []

@export var might_saving_throw: int = 0
@export var agility_saving_throw: int = 0
@export var endurance_saving_throw: int = 0
@export var intelligence_saving_throw: int = 0
@export var insight_saving_throw: int = 0
@export var charisma_saving_throw: int = 0

# Stat resources (Maximums/Base)
@export var max_hit_points: int = 10 # Often calculated from Endurance + Hit Dice
@export var max_temporary_hit_points: int = 0 # Temporary HP
@export var max_actions: int = 1  # Example: Base number of actions per turn
@export var max_bonus_actions: int = 0 # Example: Bonus actions
@export var max_reactions: int = 0 # Example: Reactions per round
@export var max_aether_points: int = 0  # Example: Mana/Spell points

# Senses
@export var perception_modifier: int = 0 # Usually 10 + Wis mod (+ prof if skilled)

# Extra (Using dedicated Resources is recommended)
@export var species: SpecieResource = null 
@export var traits: Array[TraitResource] = []
@export var languages: Array = ["Common"]
@export var skills: Array[String] = [] # List names of proficient skills
@export var equipped_items: Dictionary = {}
@export var loot_table: Array = [] # List of items/loot
@export var automatic_abilities: Array = [] # Actions, reactions, etc.
@export var proactive_abilities: Array = [] # Abilities that can be used proactively
@export var spells: Array[SpellResource] = []
@export var talents: Array = [] # What are these? Clarify or merge.
@export var senses: Dictionary = {} # List of senses (darkvision, blindsight, etc.)

# Current variables
@export var current_hit_points: int = 10
@export var current_temporary_hit_points: int = 0
@export var current_aether_points: int = 0
# Current Action Economy
@export var current_actions_available: int = 1
@export var current_bonus_actions_available: int = 1
@export var current_reactions_available: int = 1
# Current Derived Stats
@export var current_armor_class: int = 10 # Calculated from base_ac, agility_modifier, armor, effects
@export var current_speed: int = 30       # Calculated from base_speed, armor, effects
@export var current_movement_state: GameConst.MovementState = GameConst.MovementState.LAND
# Conditions and Effects
@export var current_conditions: Array = [] # Condition enums/strings
@export var active_effects: Array= [] # Active effects with durations/modifiers

# --- Initialization Logic ---
func initialize_runtime_state():
	# Calculate max values based on level, class, species, *modifiers*
	max_hit_points = calculate_max_hp()
	current_hit_points = max_hit_points
	current_temporary_hit_points = 0

	# max_aether_points = calculate_max_aether() # Implement based on class/level/modifiers
	current_aether_points = max_aether_points

	reset_turn_resources()
	recalculate_derived_stats() # Recalculate AC, Speed, DC etc.
	# recalculate_weight()
	current_conditions.clear()
	active_effects.clear()
	print(monster_name + " runtime state initialized.")

func reset_turn_resources():
	current_actions_available = max_actions
	current_bonus_actions_available = max_bonus_actions
	current_reactions_available = max_reactions

func calculate_max_hp() -> int:
	# NEED TO CHANGE THIS
	var base_hp = 8 # Example base
	var hit_die_avg = 4 # Example for d6 Hit Die (average is 3.5, round up?)
	return base_hp + (level * (hit_die_avg + endurance_modifier))

func calculate_max_aether():
	pass

func recalculate_derived_stats():
	# Recalculates derived stats based on current state, should be called at the start of each turn

	# Recalculates AC, Speed, DC based on modifiers, proficiency, equipment, effects
	var final_ac = base_armor_class
	final_ac += agility_modifier # Directly add the modifier
	# Add bonuses from armor (equipped_items["armor"]?), shield, spells (active_effects) etc.
	current_armor_class = final_ac

	var final_speed = 0
	if current_movement_state == GameConst.MovementState.SWIM:
		final_speed += base_swim_speed
	elif current_movement_state == GameConst.MovementState.FLY:
		final_speed += base_fly_speed
	elif current_movement_state == GameConst.MovementState.CLIMB:
		final_speed += base_climb_speed
	elif current_movement_state == GameConst.MovementState.BURROW:
		final_speed += base_burrow_speed
	elif current_movement_state == GameConst.MovementState.LAND:
		final_speed += base_speed
	# Add/subtract modifiers from armor, effects, conditions
	current_speed = max(0, final_speed) # Speed usually can't be negative
 
	print(monster_name + " derived stats recalculated.")
	pass # Implement actual calculations fully

# --- Damage/Healing/Resource Spending ---
func take_damage(amount: int, damage_type): # Add DamageType enum later
	if current_temporary_hit_points > 0:
		var absorbed = min(amount, current_temporary_hit_points)
		current_temporary_hit_points -= absorbed
		amount -= absorbed
		if amount <= 0: return

	current_hit_points -= amount
	current_hit_points = max(0, current_hit_points)
	print(monster_name + " took damage. Current HP: " + str(current_hit_points))
	if current_hit_points == 0:
		# Handle death/dying state
		pass

func heal(amount: int):
	current_hit_points += amount
	current_hit_points = min(current_hit_points, max_hit_points)
	print(monster_name + " healed. Current HP: " + str(current_hit_points))

# Add functions for spending aether, hero points, actions, etc.
func spend_action_point() -> bool:
	if current_actions_available > 0:
		current_actions_available -= 1
		return true
	return false

func spend_reaction() -> bool:
	if current_reactions_available > 0:
		current_reactions_available -= 1
		return true
	return false

func spend_bonus_action() -> bool:
	if current_bonus_actions_available > 0:
		current_bonus_actions_available -= 1
		return true
	return false

func spend_aether(cost: int) -> bool:
	if current_aether_points >= cost:
		current_aether_points -= cost
		return true
	print(monster_name + " does not have enough Aether points.")
	return false


# --- Getters and Setters ---
func set_unit_movement_state(state: GameConst.MovementState):
	current_movement_state = state
	print(monster_name + " movement state set to: " + str(current_movement_state))

func set_unit_size(size: GameConst.MonsterSize):
	self.size = size
	print(monster_name + " size set to: " + str(size))

func set_unit_size_by_name(size_name: String):
	match size_name.to_lower():
		"tiny": size = GameConst.MonsterSize.TINY
		"small": size = GameConst.MonsterSize.SMALL
		"medium": size = GameConst.MonsterSize.MEDIUM
		"large": size = GameConst.MonsterSize.LARGE
		"huge": size = GameConst.MonsterSize.HUGE
		"gargantuan": size = GameConst.MonsterSize.GARGANTUAN
		_:
			ErrorUtility.print_error("Invalid size name: " + size_name)
			return
	print(monster_name + " size set to: " + str(size))

func set_unit_name(name: String):
	monster_name = name
	print("Monster name set to: " + monster_name)

func set_unit_level(level: Variant):
	var value = safe_integer_typecast(level)
	if value == -1:
		return
	self.level = value
	print(monster_name + " level set to: " + str(self.level))

func set_unit_max_hit_points(hp: Variant):
	var value = safe_integer_typecast(hp)
	if value == -1:
		return
	self.max_hit_points = value
	self.current_hit_points = value # Reset current HP to max
	print(monster_name + " max hit points set to: " + str(self.max_hit_points))

func set_unit_temporary_hit_points(hp: Variant):
	var value = safe_integer_typecast(hp)
	if value == -1:
		return
	self.max_temporary_hit_points = value
	print(monster_name + " temporary hit points set to: " + str(self.max_temporary_hit_points))

func set_unit_base_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_speed = value
	print(monster_name + " base speed set to: " + str(self.base_speed))

func set_unit_base_swim_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_swim_speed = value
	print(monster_name + " base swim speed set to: " + str(self.base_swim_speed))

func set_unit_base_fly_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_fly_speed = value
	print(monster_name + " base fly speed set to: " + str(self.base_fly_speed))

func set_unit_base_climb_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_climb_speed = value
	print(monster_name + " base climb speed set to: " + str(self.base_climb_speed))

func set_unit_base_burrow_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_burrow_speed = value
	print(monster_name + " base burrow speed set to: " + str(self.base_burrow_speed))

func set_unit_base_armor_class(ac: Variant):
	var value = safe_integer_typecast(ac)
	if value == -1:
		return
	self.base_armor_class = value
	print(monster_name + " base armor class set to: " + str(self.base_armor_class))

func set_unit_might_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.might_modifier = value
	print(monster_name + " might modifier set to: " + str(self.might_modifier))

func set_unit_agility_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.agility_modifier = value
	print(monster_name + " agility modifier set to: " + str(self.agility_modifier))

func set_unit_endurance_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.endurance_modifier = value
	print(monster_name + " endurance modifier set to: " + str(self.endurance_modifier))

func set_unit_intelligence_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.intelligence_modifier = value
	print(monster_name + " cognition modifier set to: " + str(self.intelligence_modifier))

func set_unit_insight_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.insight_modifier = value
	print(monster_name + " insight modifier set to: " + str(self.insight_modifier))

func set_unit_charisma_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.charisma_modifier = value
	print(monster_name + " charisma modifier set to: " + str(self.charisma_modifier))

func set_unit_perception_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.perception_modifier = value
	print(monster_name + " perception modifier set to: " + str(self.perception_modifier))

func set_unit_might_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.might_saving_throw = value
	print(monster_name + " might saving throw set to: " + str(self.might_saving_throw))

func set_unit_agility_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.agility_saving_throw = value
	print(monster_name + " agility saving throw set to: " + str(self.agility_saving_throw))

func set_unit_endurance_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.endurance_saving_throw = value
	print(monster_name + " endurance saving throw set to: " + str(self.endurance_saving_throw))

func set_unit_intelligence_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.intelligence_saving_throw = value
	print(monster_name + " intelligence saving throw set to: " + str(self.intelligence_saving_throw))

func set_unit_insight_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.insight_saving_throw = value
	print(monster_name + " insight saving throw set to: " + str(self.insight_saving_throw))

func set_unit_charisma_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.charisma_saving_throw = value
	print(monster_name + " charisma saving throw set to: " + str(self.charisma_saving_throw))

func set_unit_gender(gender: String):
	if gender.to_lower() == "male" or gender.to_lower() == "female":
		self.gender = gender.capitalize()
		print(monster_name + " gender set to: " + gender)
		return

	ErrorUtility.print_error("Invalid gender.")

func get_unit_name() -> String:
	return monster_name

func get_unit_level() -> int:
	return level

func get_unit_max_hit_points() -> int:
	return max_hit_points

func get_unit_temporary_hit_points() -> int:
	return max_temporary_hit_points

func get_unit_base_speed() -> int:
	return base_speed

func get_unit_base_swim_speed() -> int:
	return base_swim_speed

func get_unit_base_fly_speed() -> int:
	return base_fly_speed

func get_unit_base_climb_speed() -> int:
	return base_climb_speed

func get_unit_base_burrow_speed() -> int:
	return base_burrow_speed

func get_unit_base_armor_class() -> int:
	return base_armor_class

func get_unit_might_modifier() -> int:
	return might_modifier

func get_unit_agility_modifier() -> int:
	return agility_modifier

func get_unit_endurance_modifier() -> int:
	return endurance_modifier

func get_unit_intelligence_modifier() -> int:
	return intelligence_modifier

func get_unit_insight_modifier() -> int:
	return insight_modifier

func get_unit_charisma_modifier() -> int:
	return charisma_modifier

func get_unit_perception_modifier() -> int:
	return perception_modifier

func get_unit_might_saving_throw() -> int:
	return might_saving_throw

func get_unit_agility_saving_throw() -> int:
	return agility_saving_throw

func get_unit_endurance_saving_throw() -> int:
	return endurance_saving_throw

func get_unit_intelligence_saving_throw() -> int:
	return intelligence_saving_throw

func get_unit_insight_saving_throw() -> int:
	return insight_saving_throw

func get_unit_charisma_saving_throw() -> int:
	return charisma_saving_throw

func get_unit_size_modifier() -> int:
	return GameConst.MONSTER_SIZE_MODIFIER[size]

func get_unit_size() -> GameConst.MonsterSize:
	return size

func get_unit_size_name() -> String:
	match size:
		GameConst.MonsterSize.TINY: return "Tiny"
		GameConst.MonsterSize.SMALL: return "Small"
		GameConst.MonsterSize.MEDIUM: return "Medium"
		GameConst.MonsterSize.LARGE: return "Large"
		GameConst.MonsterSize.HUGE: return "Huge"
		GameConst.MonsterSize.GARGANTUAN: return "Gargantuan"
	return "Undefined Size"

func get_unit_gender() -> String:
	return gender

# Helper functions

func safe_integer_typecast(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return value
	elif typeof(value) == TYPE_FLOAT:
		return int(round(value))
	elif typeof(value) == TYPE_STRING:
		value = value.strip_edges()
		if value.is_valid_int():
			return int(value)
		else:
			ErrorUtility.print_error("Value needs to be a whole number, not: " + value)
	else:
		ErrorUtility.print_error("Value needs to be a whole number.")
	return -1

func get_sheet_as_dictionary() -> Dictionary:
	# Returns the character sheet as a dictionary for saving/loading
	var sheet_dict: Dictionary = {}

	for key in self.get_property_list():
		sheet_dict[key.name] = self.get(key.name)
	return sheet_dict
