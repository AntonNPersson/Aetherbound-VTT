# Load all resources from all json directories
extends Node

func _ready():
	convert_json_dir_to_resources("user://Addons/Base/Traits/", "res://Content/Traits/", parse_traits)
	convert_json_dir_to_resources("user://Addons/Base/Perks/", "res://Content/Perks/", parse_perks)

# JSON parsing functions
# Load all JSON files in a directory, make them lowercase and call a method with the parsed JSON
func convert_json_dir_to_resources(dir_path: String, project_path: String, parser: Callable) -> void:
	var json_arr = JsonUtility.get_jsons_from_dir(dir_path)
	for json in json_arr:
		if json == {}:
			ErrorUtility.log_warning("Error parsing JSON file")
			continue
		parse_resource(parser, json, project_path + "/" + json["name"].to_lower() + ".tres")

# Parse a JSON file and create a .tres file
func parse_resource(parser: Callable, parsed_json: Dictionary, file_path: String) -> void:
	if FileUtility.check_if_file_exists(file_path):
		ErrorUtility.log_warning("File already exists: " + file_path)
		return

	var res = parser.call(parsed_json)

	if res.get_resource_name() == "":
		ErrorUtility.log_error("Error parsing JSON file " + file_path)
		return

	FileUtility.create_tres_file(file_path, res)

# CONTENT PARSE FUNCTIONS
func parse_traits(parsed_json: Dictionary) -> TraitResource:
	var _trait = TraitResource.new()

	if not JsonUtility.check_json_keys(parsed_json, ResourceConst.TRAIT_JSON_KEYS):
		return _trait

	_trait._init(parsed_json[ResourceConst.TRAIT_JSON_KEYS[0]], parsed_json[ResourceConst.TRAIT_JSON_KEYS[1]],
				 parsed_json[ResourceConst.TRAIT_JSON_KEYS[2]])
	return _trait

func parse_perks(parsed_json: Dictionary) -> PerkResource:
	var _perk = PerkResource.new()

	if not JsonUtility.check_json_keys(parsed_json, ResourceConst.PERK_JSON_KEYS):
		return _perk
	
	var traits: Array = []
	# Retrieve trait references
	for trait_name in parsed_json[ResourceConst.PERK_JSON_KEYS[2]]:
		var trait_path = "res://Content/Traits/" + trait_name.to_lower() + ".tres"
		print(trait_path)
		var trait_ref = FileUtility.get_reference_to_file(trait_path)
		
		if trait_ref:
			traits.append(trait_ref)
		else:
			ErrorUtility.log_error("Trait '{}' not found for Perk '{}'".format([trait_name, parsed_json[ResourceConst.PERK_JSON_KEYS[0]]]))

	_perk._init(parsed_json[ResourceConst.PERK_JSON_KEYS[0]], parsed_json[ResourceConst.PERK_JSON_KEYS[1]], 
				traits, parsed_json[ResourceConst.PERK_JSON_KEYS[3]], 
				parsed_json[ResourceConst.PERK_JSON_KEYS[4]], parsed_json[ResourceConst.PERK_JSON_KEYS[5]], 
				parsed_json[ResourceConst.PERK_JSON_KEYS[6]], parsed_json[ResourceConst.PERK_JSON_KEYS[7]])
	return _perk
