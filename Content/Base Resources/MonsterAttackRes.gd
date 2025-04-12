# res://path/to/MonsterAttackResource.gd (Ensure path is correct)
@tool
extends Resource
class_name MonsterAttackResource

# Assuming GameConst exists and has these enums defined
# enum DamageCategory { MELEE, RANGED, AREA, ... }
# enum DamageType { PIERCING, SLASHING, BLUDGEONING, FIRE, COLD, ... }

@export var attack_name: String = "Attack Name" # Renamed from 'name'
@export var type: GameConst.DamageCategory = GameConst.DamageCategory.MELEE
@export var ap_cost: int = 1
@export var attack_bonus: int = 0
@export var traits: Array = [] # Keep as String array
@export var damage_string: String = "" # Store the dice + bonus string
@export var damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING # Default
@export_multiline var effects_description: String = "" # Combined/first effect string

# Initialization method
func initialize_from_dict(data: Dictionary):
	self.attack_name = data.get("name", "Unnamed Attack")
	self.ap_cost = data.get("AP_cost", 1) # Default to 1 AP
	self.attack_bonus = data.get("attack_bonus", 0)
	self.traits = Cache._load_resource_name_array(data.get("traits", []), "TraitResource")

	# Map Type (String to Enum) - Requires robust mapping in GameConst or here
	var type_string = data.get("type", "Melee").to_lower()
	# Example mapping (Ideally use a helper function in GameConst)
	if type_string == "melee":
		self.type = GameConst.DamageCategory.MELEE
	elif type_string == "ranged":
		self.type = GameConst.DamageCategory.RANGED
	# Add other mappings as needed...
	else:
		printerr("Warning: Unknown attack type '%s' for attack '%s'. Defaulting to MELEE." % [type_string, self.attack_name])
		self.type = GameConst.DamageCategory.MELEE

	# Extract Damage String and Type from the 'damage' array
	var damage_array = data.get("damage", [])
	if typeof(damage_array) == TYPE_ARRAY and not damage_array.is_empty():
		var first_damage_entry = damage_array[0]
		if typeof(first_damage_entry) == TYPE_ARRAY and first_damage_entry.size() >= 2:
			self.damage_string = first_damage_entry[0] # e.g., "2d10+10"
			var damage_type_string = first_damage_entry[1].to_lower() # e.g., "piercing"

			# Map Damage Type (String to Enum) - Requires robust mapping
			# Example (Again, use a helper function ideally)
			if damage_type_string == "piercing": self.damage_type = GameConst.DamageType.PIERCING
			elif damage_type_string == "fire": self.damage_type = GameConst.DamageType.FIRE
			elif damage_type_string == "cold": self.damage_type = GameConst.DamageType.COLD
			elif damage_type_string == "acid": self.damage_type = GameConst.DamageType.ACID
			elif damage_type_string == "poison": self.damage_type = GameConst.DamageType.POISON
			elif damage_type_string == "psychic": self.damage_type = GameConst.DamageType.PSYCHIC
			elif damage_type_string == "radiant": self.damage_type = GameConst.DamageType.RADIANT
			elif damage_type_string == "necrotic": self.damage_type = GameConst.DamageType.NECROTIC
			elif damage_type_string == "thunder": self.damage_type = GameConst.DamageType.THUNDER
			elif damage_type_string == "slashing": self.damage_type = GameConst.DamageType.SLASHING
			elif damage_type_string == "bludgeoning": self.damage_type = GameConst.DamageType.BLUDGEONING
			# Add ALL other damage types...
			else:
				printerr("Warning: Unknown damage type '%s' for attack '%s'. Defaulting." % [damage_type_string, self.attack_name])
				# Keep default or handle error
		else:
			printerr("Warning: Unexpected format in 'damage' entry for attack '%s'. Expected [String, String]. Data: %s" % [self.attack_name, str(first_damage_entry)])
	else:
		printerr("Warning: Missing or invalid 'damage' array for attack '%s'." % self.attack_name)


	# Extract Effects Description
	var effects_array = data.get("effects", [])
	if typeof(effects_array) == TYPE_ARRAY and not effects_array.is_empty():
		# Combine effects or take the first one? Let's join them for now.
		self.effects_description = ", ".join(effects_array)
		# Or just take the first: self.effects_description = effects_array[0] if typeof(effects_array[0]) == TYPE_STRING else ""
	else:
		self.effects_description = "" # Ensure it's empty if no effects

# Optional: Override _to_string for better debugging
func _to_string() -> String:
	return "MonsterAttackResource(name='%s', dmg='%s %s')" % [attack_name, damage_string, GameConst.DamageType.keys()[damage_type]]
