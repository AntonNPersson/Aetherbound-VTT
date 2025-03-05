# Load all resources from all json directories
extends Node

# ===================== RESOURCE CORE FUNCTIONS =====================
func _ready():
	convert_json_dir_to_resources("user://Addons/Base/Traits/traits.json", "res://Content/Traits/", 
									ResourceConst.TRAIT_JSON_KEYS, ResourceConst.TRAIT_JSON_TYPES, TraitResource, "", [])

func create_resources():
	convert_json_dir_to_resources("user://Addons/Base/Traits/", "res://Content/Traits/", 
									ResourceConst.TRAIT_JSON_KEYS, ResourceConst.TRAIT_JSON_TYPES, TraitResource, "", [])

	convert_json_dir_to_resources("user://Addons/Base/Perks/", "res://Content/Perks/", 
									ResourceConst.PERK_JSON_KEYS, ResourceConst.PERK_JSON_TYPES, PerkResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Feats/", "res://Content/Feats/", 
									ResourceConst.FEAT_JSON_KEYS, ResourceConst.FEAT_JSON_TYPES, FeatResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Actions/", "res://Content/Actions/", 
									ResourceConst.ACTION_JSON_KEYS, ResourceConst.ACTION_JSON_TYPES, ActionResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Skills/", "res://Content/Skills/", 
									ResourceConst.SKILL_JSON_KEYS, ResourceConst.SKILL_JSON_TYPES, SkillResource, "parse_multiple", 
									[["parse_proficiencies", "parse_actions"]])

	convert_json_dir_to_resources("user://Addons/Base/Abilties/", "res://Content/Abilities/", 
									ResourceConst.ABILITY_JSON_KEYS, ResourceConst.ABILITY_JSON_TYPES, AbilityResource, "parse", [])

	convert_json_dir_to_resources("user://Addons/Base/Affinities/", "res://Content/Affinities/",
									ResourceConst.AFFINITY_JSON_KEYS, ResourceConst.AFFINITY_JSON_TYPES, AffinityResource, "parse_multiple", 
									[[{"parse": ["traits"]}, {"parse": ["skills"]}, {"parse": ["perks"]}]])

	convert_json_dir_to_resources("user://Addons/Base/Lineages/", "res://Content/Lineages/", 
									ResourceConst.LINEAGE_JSON_KEYS, ResourceConst.LINEAGE_JSON_TYPES, LineageResource, "parse_multiple", 
									[[{"parse": ["feats"]}, {"parse": ["perks"]}]])

	convert_json_dir_to_resources("user://Addons/Base/VersatileLineages/", "res://Content/Lineages/",
									ResourceConst.VERSATILELINEAGE_JSON_KEYS, ResourceConst.VERSATILELINEAGE_JSON_TYPES, VersatileLineageResource, "parse_multiple", 
									[[{"parse": ["feats"]}, {"parse": ["perks"]}, {"parse": ["traits"]}, {"parse": ["abilities"]}, {"parse": ["lineages"]}]])

	convert_json_dir_to_resources("user://Addons/Base/Spells/", "res://Content/Spells/",
									ResourceConst.SPELL_JSON_KEYS, ResourceConst.SPELL_JSON_TYPES, SpellResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Items/", "res://Content/Items/",
									ResourceConst.ITEM_JSON_KEYS, ResourceConst.ITEM_JSON_TYPES, ItemResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Weapons/", "res://Content/Items/Weapons/",
									ResourceConst.WEAPON_JSON_KEYS, ResourceConst.WEAPON_JSON_TYPES, WeaponResource, "parse", ["traits"])
	
	convert_json_dir_to_resources("user://Addons/Base/Armor/", "res://Content/Items/Armor/",
									ResourceConst.ARMOR_JSON_KEYS, ResourceConst.ARMOR_JSON_TYPES, ArmorResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Shields/", "res://Content/Items/Shields/",
									ResourceConst.SHIELD_JSON_KEYS, ResourceConst.SHIELD_JSON_TYPES, ShieldResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/Archetypes/", "res://Content/Archetypes/",
									ResourceConst.ARCHETYPE_JSON_KEYS, ResourceConst.ARCHETYPE_JSON_TYPES, ArchetypeResource, "parse_multiple", 
									[[{"parse": ["feats"]}, {"parse": ["traits"]}, {"parse_specific": ["dedication_feat", "feats"]}]])

	convert_json_dir_to_resources("user://Addons/Base/Deities/", "res://Content/Deities/", 
									ResourceConst.DEITY_JSON_KEYS, ResourceConst.DEITY_JSON_TYPES, DeityResource, "parse_multiple",
									[[{"parse_specific": ["divine_consecration", "traits"]}, {"parse_specific": ["divine_skill", "skills"]}]])

	convert_json_dir_to_resources("user://Addons/Base/Species/", "res://Content/Species/", 
									ResourceConst.SPECIE_JSON_KEYS, ResourceConst.SPECIE_JSON_TYPES, SpecieResource, "parse_multiple", 
									[[{"parse": ["lineages"]}, {"parse": ["abilities"]}, {"parse": ["feats"]}, {"parse": ["traits"]}]])

	convert_json_dir_to_resources("user://Addons/Base/Conditions/", "res://Content/Conditions/",
									ResourceConst.CONDITION_JSON_KEYS, ResourceConst.CONDITION_JSON_TYPES, ConditionResource, "parse", ["traits"])

	convert_json_dir_to_resources("user://Addons/Base/StageConditions/", "res://Content/Conditions/",
									ResourceConst.CONDITION_JSON_KEYS, ResourceConst.CONDITION_JSON_TYPES, StageConditionResource, "parse", ["traits"])

# ===================== JSON PARSING FUNCTIONS =====================

# JSON parsing functions
# Load all JSON files in a directory, make them lowercase and call a method with the parsed JSON
# Args: dir_path: Path to the directory containing the JSON files
#		project_path: Path to the project directory
#		required_keys: Array of required keys in the JSON file
#		required_types: Array of required types of the keys in the JSON file
#		resource: Resource class to create the .tres file
#		parser: Method to parse the JSON file
#		parser_args: Array of arguments for the parser
# Returns: None
func convert_json_dir_to_resources(dir_path: String, project_path: String, required_keys: Array, required_types: Array, resource: Resource,
									parser: String, parser_args: Array) -> void:
	var json_arr = ExternalUtility.get_seperate_json_from_file(dir_path)
	for json in json_arr:
		if json == {}:
			ErrorUtility.log_warning("Error parsing JSON file" + json)
			continue
		parse_and_create_tres(parser, parser_args, json, project_path + "/" + json["name"].to_lower() + ".tres", required_keys, required_types, resource)

# ===================== CONTENT PARSE FUNCTIONS =====================

# Parse JSON into a resource
# Args: parsed_json: Parsed JSON file
# Returns: Parsed JSON file
func parse(parsed_json: Dictionary, type: String) -> Dictionary:
	parsed_json = replace_with_resource(parsed_json, type)
	return parsed_json

# Parse proficiencies JSON into a resource
# Args: parsed_json: Parsed JSON file
# Returns: Parsed JSON file
func parse_proficiencies(parsed_json: Dictionary) -> Dictionary:
	var proficiency_rank = parsed_json["proficiency"]
	parsed_json = replace_with_base_resource(parsed_json, "proficiency", ProficiencyResource)
	parsed_json["proficiency"].set_rank(proficiency_rank)
	return parsed_json

# Parse actions JSON into a resource
# Args: parsed_json: Parsed JSON file
# Returns: Parsed JSON file
func parse_actions(parsed_json: Dictionary) -> Dictionary:
	parsed_json = replace_with_resources_specific_folder(parsed_json, "untrained_actions", "actions")
	parsed_json = replace_with_resources_specific_folder(parsed_json, "trained_actions", "actions")
	return parsed_json

# Parse dedication feat JSON into a resource
# Args: parsed_json: Parsed JSON file
# Returns: Parsed JSON file
func parse_specific(parsed_json: Dictionary, key: String, folder: String) -> Dictionary:
	parsed_json = replace_with_resource_specific_folder(parsed_json, key, folder)
	return parsed_json

# Parse JSON into multiple resources
# Args: parsed_json: Parsed JSON file
# Returns: Parsed JSON file
func parse_multiple(parsed_json: Dictionary, parsers: Variant) -> Dictionary:
	for parser in parsers:
		if typeof(parser) == TYPE_STRING:
			if has_method(parser):
				parsed_json = callv(parser, [parsed_json])
			else:
				ErrorUtility.log_error("Parser method " + parser + " not found")
				return parsed_json
		elif typeof(parser) == TYPE_DICTIONARY:
			for p in parser:
				var args = [parsed_json] + parser[p]
				if has_method(p):
					parsed_json = callv(p, args)
				else:
					ErrorUtility.log_error("Parser method " + p + " not found")
					return parsed_json
		else:
			ErrorUtility.log_error("Invalid parser type" + str(typeof(parser)) + "should be String or Dictionary")
			return parsed_json
	return parsed_json

# ===================== RESOURCE LOADING FUNCTIONS =====================

# Get all resources from a directory
# Args: dir_path: Path to the directory containing the resources
#		file_names: Array of file names of the resources
# Returns: Array of resources
func get_resources(dir_path: String, file_names: Array) -> Array:
	var resources = []
	for file_name in file_names:
		var file_path = dir_path + file_name + ".tres"
		var res = ExternalUtility.get_reference_to_file(file_path)
		if res:
			resources.append(res)
		else:
			ErrorUtility.log_error("Resource " + file_name + " not found")
			continue
	return resources

# Get a resource from a directory
# Args: dir_path: Path to the directory containing the resource
#		file_name: Name of the resource
# Returns: Resource
func get_resource(dir_path: String, file_name: String) -> Resource:
	var file_path = dir_path + file_name + ".tres"
	var res = ExternalUtility.get_reference_to_file(file_path)
	if res:
		return res
	else:
		ErrorUtility.log_error("Resource " + file_name + " not found")
		return null

# Parse a JSON file and create a .tres file
# Args: parser: Method to parse the JSON file
#		parsed_json: Parsed JSON file
#		file_path: Path to the .tres file
#		required_keys: Array of required keys in the JSON file
#		required_types: Array of required types of the keys in the JSON file
#		resource: Resource class to create the .tres file
# Returns: None
func parse_and_create_tres(parser: String, parser_args: Array, parsed_json: Dictionary, file_path: String, required_keys: Array, required_types: Array, resource: Resource) -> void:
	if ExternalUtility.check_if_file_exists(file_path):
		ErrorUtility.log_warning("File already exists: " + file_path)
		return

	var res = parse_resource(parsed_json, resource, required_keys, required_types, parser, parser_args)

	if res.get_resource_name() == "":
		ErrorUtility.log_error("Error parsing JSON file " + file_path)
		return

	ExternalUtility.create_tres_file(file_path, res)

# Replace a key in a JSON with a resource
# Args: parsed_json: Parsed JSON file
#		key: Key to replace with a resource
# Returns: Parsed JSON file
func replace_with_resource(parsed_json: Dictionary, key: String) -> Dictionary:
	if typeof(parsed_json[key]) == TYPE_STRING:
		var resource = get_resource("res://Content/"+ key+ "/", parsed_json[key])
		ExternalUtility.replace_json_value(parsed_json, key, resource)
	elif typeof(parsed_json[key]) == TYPE_ARRAY:
		var resources = get_resources("res://Content/"+ key+ "/", parsed_json[key])
		ExternalUtility.replace_json_value(parsed_json, key, resources)
	return parsed_json

# Replace a key of type array in a JSON with resources from a specific folder
# Args: parsed_json: Parsed JSON file
#		key: Key to replace with a resource
#		folder: Folder containing the resources
# Returns: Parsed JSON file
func replace_with_resources_specific_folder(parsed_json: Dictionary, key: String, folder: String) -> Dictionary:
	var resources = get_resources("res://Content/"+ folder + "/", parsed_json[key])
	ExternalUtility.replace_json_value(parsed_json, key, resources)
	return parsed_json

# Replace a key of type string in a JSON with a resource from a specific folder
# Args: parsed_json: Parsed JSON file
#		key: Key to replace with a resource
#		folder: Folder containing the resources
# Returns: Parsed JSON file
func replace_with_resource_specific_folder(parsed_json: Dictionary, key: String, folder: String) -> Dictionary:
	var resources = get_resource("res://Content/"+ folder + "/", parsed_json[key])
	ExternalUtility.replace_json_value(parsed_json, key, resources)
	return parsed_json

# Replace a key in a JSON with a base resource
# Args: parsed_json: Parsed JSON file
#		key: Key to replace with a resource
#		base_resource_name: Name of the base resource
# Returns: Parsed JSON file
func replace_with_base_resource(parsed_json: Dictionary, key: String, base_resource : Resource) -> Dictionary:
	var resources = base_resource.new()
	ExternalUtility.replace_json_value(parsed_json, key, resources)
	return parsed_json

# Parse a JSON file and create a resource
# Args: parsed_json: Parsed JSON file
#		resource: Resource class to create the resource
#		required_keys: Array of required keys in the JSON file
#		required_types: Array of required types of the keys in the JSON file
#		parser: Method to parse the JSON file
# Returns: Resource
func parse_resource(parsed_json: Dictionary, resource: Resource, required_keys: Array, required_types: Array, parser: String, parser_args: Array) -> Resource:
	var res = resource.new()

	if not ExternalUtility.ensure_json_type_and_keys(parsed_json, required_keys, required_types):
		return res

	parser_args = [parsed_json] + parser_args
	if parser != "":
		if has_method(parser):
			parsed_json = callv(parser, parser_args)
		else:
			ErrorUtility.log_error("Parser method " + parser + " not found")
			return res

	var sorted_json_values = ExternalUtility.sort_json_dictionary_values(parsed_json, required_keys)
	res.callv("_init", sorted_json_values)
	return res
