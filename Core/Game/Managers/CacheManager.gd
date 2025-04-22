# Manages loading of scenes, resources (simplified to only Traits), and map data.
# Provides centralized access to loaded assets.

extends Node

# --- Data & UI References ---
var data: Dictionary = {} # Holds map data (dd2vtt)
# PackedScene references preloaded for immediate UI use if needed
@onready var menu_3k: PackedScene = preload("res://UI/Instances/menu_ui_3k.tscn")
@onready var menu: PackedScene = preload("res://UI/Instances/menu_ui.tscn")
# Assume Settings and Net nodes/singletons exist elsewhere
# Assume ExternalUtility and ErrorUtility singletons exist and are Godot 4 compatible

signal loading_complete() # Signal to indicate loading completion

# --- Scene Loading State ---
var _current_scene_group_name := ""
var _scenes_to_load: Array[String] = [] # Paths
var _loaded_scenes: Dictionary = {} # group_name -> [PackedScene]
var _current_scene_load_index := 0
var _is_loading_scenes := false

# --- Resource Loading State ---
# Array of dictionaries: {"path": String, "target_dict": Dictionary, "name_prop": String}
var _resources_to_load: Array[Dictionary] = []
var _current_resource_load_index := 0
var _is_loading_resources := false
var _total_resources_to_load := 0
var _resource_load_requests := {}

# --- Global RegEx (if needed) ---
var REGEX_THROWN: RegEx = RegEx.new()
var REGEX_VERSATILE: RegEx = RegEx.new()

# --- Resource Dictionaries (Simplified) ---
var loaded_traits: Dictionary = {} # ONLY Trait resources
var loaded_monsters: Dictionary = {} # ONLY Monster resources
var loaded_monster_abilities: Dictionary = {} # ONLY MonsterAbility resources
var loaded_monster_attacks: Dictionary = {} # ONLY MonsterAttack resources
var loaded_skills: Dictionary = {} # ONLY Skill resources
var loaded_speeds: Dictionary = {} # ONLY Speed resources
var loaded_senses: Dictionary = {} # ONLY Sense resources
var loaded_templates: Dictionary = {} # ONLY Template resources
var loaded_proficiencies : Dictionary = {} # ONLY Proficiency resources
var loaded_species: Dictionary = {} # ONLY Species resources
var loaded_lineages: Dictionary = {} # ONLY Lineage resources
var loaded_affinities: Dictionary = {} # ONLY Affinity resources
var loaded_armors: Dictionary = {} # ONLY Armor resources
var loaded_weapons: Dictionary = {} # ONLY Weapon resources
var loaded_items: Dictionary = {} # ONLY Item resources
var loaded_shields: Dictionary = {} # ONLY Shield resources

var loaded_sheets: Dictionary = {} # ONLY Character sheets

# --- Constants for Resource Name Properties (Simplified) ---
const TRAIT_NAME_PROP = "t_name" # MUST match the @export var name in TraitResource.gd
const MONSTER_NAME_PROP = "monster_name"
const STANDARD_NAME_PROP = "name" # MUST match the @export var name in MonsterAbilityRes.gd
const SKILL_NAME_PROP = "s_name" # MUST match the @export var name in SkillResource.gd
const SPEED_NAME_PROP = "s_name"
const SENSE_NAME_PROP = "s_name" # MUST match the @export var name in SenseResource.gd
const SPECIES_NAME_PROP = "s_name" # MUST match the @export var name in SpeciesResource.gd
const LINEAGE_NAME_PROP = "l_name" # MUST match the @export var name in LineageResource.gd
const AFFINITY_NAME_PROP = "a_name" # MUST match the @export var name in AffinityResource.gd
const ITEM_NAME_PROP = "i_name" # MUST match the @export var name in ItemResource.gd

const KEY_TO_RESOURCE_TYPE_MAP = {
	"species": "SpeciesResource",
	"affinity": "AffinityResource",
	"lineage": "LineageResource",
	"skills": "SkillResource",
	"perks": "PerkResource", # Assuming PerkResource exists
	"spells_known": "SpellResource",
	"traits": "TraitResource",
	"talents": "TalentResource",
	"weapon_proficiency": "ProficiencyResource",
	"armor_proficiency": "ProficiencyResource",
	"extra_proficiencies": "ProficiencyResource",
	"archetype": "ArchetypeResource",
	"character_class": "ClassResource",
	"inventory": "ItemResource",
}

const SLOT_TO_RESOURCE_TYPE_MAP = {
	"main_hand": "WeaponResource",
	"off_hand": "ItemResource", # Could be WeaponResource or Shield (ItemResource?) - Adjust as needed
	"armor": "ArmorResource",
	"head": "ArmorResource",
	"neck": "ItemResource",
	"eyes": "ItemResource",
	"shoulders": "ArmorResource",
	"wrists": "ArmorResource",
	"hands": "ArmorResource",
	"ring_1": "ItemResource",
	"ring_2": "ItemResource",
	"feet": "ArmorResource",
}
# ==================== INITIALIZATION ====================

func _ready() -> void:
	print("CacheManager: Initializing...")
	var error_thrown = REGEX_THROWN.compile("(?i)^Thrown\\s+(\\d+)\\s?ft\\.?$")
	if error_thrown != OK:
		printerr("REGEX_THROWN compilation failed with error code: ", error_thrown)
		REGEX_THROWN = null # Mark as invalid if compilation fails

	var error_versatile = REGEX_VERSATILE.compile("(?i)^Versatile\\s+(\\w)$")
	if error_versatile != OK:
		printerr("REGEX_VERSATILE compilation failed with error code: ", error_versatile)
		REGEX_VERSATILE = null # Mark as invalid if compilation fails

	# --- Load Map Data (RESTORED ORIGINAL LOGIC) ---
	# Uses user's original ExternalUtility call and path reconstruction
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/", true) # Assuming this returns what the original loop expected
	for file in files: # Assuming 'file' has get_file() and get_basename() methods
		# Original logic check: Ensure 'file' is not null and has the expected methods before calling them
		if file:
			var map_name = file.get_file().get_basename()
			if not map_name.is_empty():
				var map_file_path = "user://Assets/Maps/" + map_name + ".dd2vtt"
				# Optional: Check if this reconstructed path actually exists before processing
				# if FileAccess.file_exists(map_file_path):
				data[map_name] = ExternalUtility.process_dd2vtt_file(map_file_path)
				# else:
				#     ErrorUtility.log_warning("Reconstructed map path not found: %s" % map_file_path)
			else:
				ErrorUtility.log_warning("Empty map name derived from file object: %s" % str(file))
		else:
			ErrorUtility.log_warning("Unexpected item returned by get_all_files_in_dir: %s" % str(file))
	print("CacheManager: Map data loading attempted.")
	# -----------------------------------------------------

	# --- Start Scene Loading (Async) ---
	# Example: Load NPC scenes into the "NPCs" group
	get_saved_character_sheets()
	load_scenes_from_directory_async("res://Characters/NPCs/", false, "NPCs")

	# --- Start Resource Loading (Async - ONLY TRAITS) ---
	print("--- Starting Asynchronous Resource Loading ---")
	load_resources_from_directory_async("res://Content/Traits/", false, loaded_traits, TRAIT_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Monsters/", false, loaded_monsters, MONSTER_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Skills/", false, loaded_skills, SKILL_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Monsters/Abilities/", true, loaded_monster_abilities, STANDARD_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Monsters/Attacks/", true, loaded_monster_attacks, STANDARD_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Speeds/", false, loaded_speeds, SPEED_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Senses/", false, loaded_senses, SENSE_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Templates/", false, loaded_templates, STANDARD_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Proficiencies/", false, loaded_proficiencies, STANDARD_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Species/", false, loaded_species, SPECIES_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Lineages/", false, loaded_lineages, LINEAGE_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Affinities/", false, loaded_affinities, AFFINITY_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Items/Armor", false, loaded_armors, ITEM_NAME_PROP, [".tres"])
	load_resources_from_directory_async("res://Content/Items/Weapons", false, loaded_weapons, ITEM_NAME_PROP, [".tres"])
	print("--- Resource Loading Initiated (will proceed in background) ---")


# ==================== RESOURCE/SCENE ACCESS ====================

func find_loaded_resource_by_name(resource_name: String, resource_type: String = "Any") -> Resource:
	var resource = null
	resource_name = resource_name.strip_edges().to_lower() # Normalize the name

	# Check for special cases
	var base_trait_name = resource_name
	var params_to_set = {}
	if resource_type == "TraitResource":
		if REGEX_THROWN != null:
			var thrown_match = REGEX_THROWN.search(resource_name)
			if thrown_match:
				base_trait_name = "thrown"
				params_to_set["range"] = int(thrown_match.get_string(1))
				print("Matched Thrown: ", resource_name, " Range: ", params_to_set["range"])
			
		if REGEX_VERSATILE != null:
			var versatile_match = REGEX_VERSATILE.search(resource_name)
			if versatile_match:
				base_trait_name = "versatile"
				params_to_set["damage_type"] = versatile_match.get_string(1)
				print("Matched Versatile: ", resource_name, " Damage Type: ", params_to_set["damage_type"])

	
	# Check if the resource exists in any loaded dictionary
	if loaded_traits.has(base_trait_name) and (resource_type == "Any" or resource_type == "TraitResource"):
		resource = loaded_traits[base_trait_name].duplicate(true)
		if params_to_set.size() > 0:
			resource.parameters = params_to_set
	elif loaded_monsters.has(resource_name) and (resource_type == "Any" or resource_type == "MonsterResource"):
		resource = loaded_monsters[resource_name].duplicate(true)
	elif loaded_skills.has(resource_name) and (resource_type == "Any" or resource_type == "SkillResource"):
		resource = loaded_skills[resource_name].duplicate(true)
	elif loaded_monster_abilities.has(resource_name) and (resource_type == "Any" or resource_type == "MonsterAbilityResource"):
		resource = loaded_monster_abilities[resource_name].duplicate(true)
	elif loaded_speeds.has(resource_name) and (resource_type == "Any" or resource_type == "SpeedResource"):
		resource = loaded_speeds[resource_name].duplicate(true)
	elif loaded_senses.has(resource_name) and (resource_type == "Any" or resource_type == "SenseResource"):
		resource = loaded_senses[resource_name].duplicate(true)
	elif loaded_monster_attacks.has(resource_name) and (resource_type == "Any" or resource_type == "MonsterAttackResource"):
		resource = loaded_monster_attacks[resource_name].duplicate(true)
	elif loaded_templates.has(resource_name) and (resource_type == "Any" or resource_type == "TemplateResource"):
		resource = loaded_templates[resource_name].duplicate(true)
	elif loaded_proficiencies.has(resource_name) and (resource_type == "Any" or resource_type == "ProficiencyResource" or resource_type == "WeaponProficiencyResource" or resource_type == "ArmorProficiencyResource"):
		resource = loaded_proficiencies[resource_name].duplicate(true)
	elif loaded_monsters.has(resource_name) and (resource_type == "Any" or resource_type == "MonsterResource"):
		resource = loaded_monsters[resource_name].duplicate(true)
	elif loaded_species.has(resource_name) and (resource_type == "Any" or resource_type == "SpeciesResource"):
		resource = loaded_species[resource_name].duplicate(true)
	elif loaded_lineages.has(resource_name) and (resource_type == "Any" or resource_type == "LineageResource"):
		resource = loaded_lineages[resource_name].duplicate(true)
	elif loaded_affinities.has(resource_name) and (resource_type == "Any" or resource_type == "AffinityResource"):
		resource = loaded_affinities[resource_name].duplicate(true)
	elif loaded_armors.has(resource_name) and (resource_type == "Any" or resource_type == "ArmorResource" or resource_type == "ItemResource"):
		resource = loaded_armors[resource_name].duplicate(true)
	elif loaded_weapons.has(resource_name) and (resource_type == "Any" or resource_type == "WeaponResource" or resource_type == "ItemResource"):
		resource = loaded_weapons[resource_name].duplicate(true)
	elif loaded_items.has(resource_name) and (resource_type == "Any" or resource_type == "ItemResource"):
		resource = loaded_items[resource_name].duplicate(true)
	elif loaded_shields.has(resource_name) and (resource_type == "Any" or resource_type == "ShieldResource" or resource_type == "ItemResource"):
		resource = loaded_shields[resource_name].duplicate(true)
	else:
		pass
		#ErrorUtility.log_error("Resource not found in any loaded dictionary: Name='%s'" % resource_name) # Less verbose
	return resource

# Find a loaded resource
func _find_resource_by_name(resource_name: String, resource_type: String) -> Resource:
	var lookup_key = resource_name # Or resource_name.to_lower() if keys are stored lowercase

	# Only handle TraitResource requests in this simplified version
	if resource_type == "TraitResource":
		if loaded_traits.has(lookup_key):
			return loaded_traits[lookup_key]
		else:
			print("Trait resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "MonsterSheet":
		if loaded_monsters.has(lookup_key):
			return loaded_monsters[lookup_key]
		else:
			print("Monster resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "SkillResource":
		if loaded_skills.has(lookup_key):
			return loaded_skills[lookup_key]
		else:
			print("Skill resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "MonsterAbilityResource":
		if loaded_monster_abilities.has(lookup_key):
			return loaded_monster_abilities[lookup_key]
		else:
			print("Monster ability resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "SpeedResource":
		if loaded_speeds.has(lookup_key):
			return loaded_speeds[lookup_key]
		else:
			print("Speed resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "SenseResource":
		if loaded_senses.has(lookup_key):
			return loaded_senses[lookup_key]
		else:
			print("Sense resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "MonsterAttackResource":
		if loaded_monster_abilities.has(lookup_key):
			return loaded_monster_abilities[lookup_key]
		else:
			print("Monster attack resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "TemplateResource":
		if loaded_templates.has(lookup_key):
			return loaded_templates[lookup_key]
		else:
			print("Template resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "MonsterAttackResource":
		if loaded_monster_attacks.has(lookup_key):
			return loaded_monster_attacks[lookup_key]
		else:
			print("Monster attack resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "WeaponProficiencyResource":
		if loaded_proficiencies.has(lookup_key):
			return loaded_proficiencies[lookup_key]
		else:
			print("Proficiency resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "ArmorProficiencyResource":
		if loaded_proficiencies.has(lookup_key):
			return loaded_proficiencies[lookup_key]
		else:
			print("Proficiency resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "MonsterResource":
		if loaded_monsters.has(lookup_key):
			return loaded_monsters[lookup_key]
		else:
			print("Monster resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "SpeciesResource":
		if loaded_species.has(lookup_key):
			return loaded_species[lookup_key]
		else:
			print("Species resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "LineageResource":
		if loaded_lineages.has(lookup_key):
			return loaded_lineages[lookup_key]
		else:
			print("Lineage resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "AffinityResource":
		if loaded_affinities.has(lookup_key):
			return loaded_affinities[lookup_key]
		else:
			print("Affinity resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "ArmorResource":
		if loaded_armors.has(lookup_key):
			return loaded_armors[lookup_key]
		else:
			print("Armor resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "ItemResource":
		if loaded_items.has(lookup_key):
			return loaded_items[lookup_key]
		else:
			print("Item resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "ShieldResource":
		if loaded_shields.has(lookup_key):
			return loaded_shields[lookup_key]
		else:
			print("Shield resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	elif resource_type == "WeaponResource":
		if loaded_weapons.has(lookup_key):
			return loaded_weapons[lookup_key]
		else:
			print("Weapon resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	else:
		ErrorUtility.log_warning("Attempted to find resource type '%s', but only TraitResource is handled." % resource_type)
		return null

func get_all_weapon_proficiencies(name_only: bool = false) -> Array:
	var all_proficiencies: Array = []
	var all_weapon_proficiency_names: Array = []
	for prof in GameConst.WeaponProficiencyCategory:
		all_weapon_proficiency_names.append(prof.capitalize())

	for proficiency in loaded_proficiencies.values():
		if proficiency.has_method("get_resource_name"):
			var proficiency_name = proficiency.get_resource_name()
			if all_weapon_proficiency_names.has(proficiency_name):
				if name_only:
					all_proficiencies.append(proficiency_name)
				else:
					all_proficiencies.append(proficiency.duplicate(true))
			else:
				ErrorUtility.log_warning("Proficiency '%s' not found in all weapon proficiency names." % proficiency_name)
		else:
			ErrorUtility.log_warning("Proficiency '%s' does not have a resource name." % str(proficiency))
	return all_proficiencies

func get_all_armor_proficiencies(name_only: bool = false) -> Array:
	var all_proficiencies: Array = []
	var all_armor_proficiency_names: Array = []
	for prof in GameConst.ArmorProficiencyCategory:
		all_armor_proficiency_names.append(prof.capitalize())
		print("Armor proficiency name: %s" % prof.capitalize())

	for proficiency in loaded_proficiencies.values():
		if proficiency.has_method("get_resource_name"):
			var proficiency_name = proficiency.get_proficiency_category_as_string()
			print("Proficiency name: %s" % proficiency_name)
			if all_armor_proficiency_names.has(proficiency_name):
				if name_only:
					all_proficiencies.append(proficiency.get_resource_name())
				else:
					all_proficiencies.append(proficiency.duplicate(true))
			else:
				ErrorUtility.log_warning("Proficiency '%s' not found in all armor proficiency names." % proficiency_name)
		else:
			ErrorUtility.log_warning("Proficiency '%s' does not have a resource name." % str(proficiency))
	return all_proficiencies

func reload_character_sheets() -> void:
	loaded_sheets.clear()
	get_saved_character_sheets()

# Load/populate an array property on an object with resources looked up by name
# Note: This relies on _find_resource_by_name, which now only finds Traits.
func _load_resource_array(target_object: Object, property_name: String, loaded_data: Variant, resource_type: String, default_value: Array) -> void:
	if not target_object: return
	var target_array = target_object.get(property_name)
	if not target_array is Array: return
	if not loaded_data is Array:
		target_object.set(property_name, default_value.duplicate())
		return

	target_array.clear()
	var item_index = 0
	for resource_name in loaded_data:
		if not resource_name is String:
			ErrorUtility.log_warning("Expected string resource name in loaded data for '%s' at index %d, but got %s." % [property_name, item_index, typeof(resource_name)])
			item_index += 1
			continue

		var found_resource = _find_resource_by_name(resource_name, resource_type)
		if found_resource:
			target_array.append(found_resource)
		# else: # Warning handled by _find_resource_by_name if type mismatch or not found
		item_index += 1


# Get loaded scenes for a specific group
func get_loaded_scenes(group_name: String) -> Array[PackedScene]:
	if _loaded_scenes.has(group_name):
		return _loaded_scenes[group_name]
	else:
		# ErrorUtility.log_warning("No loaded scenes found for group: '%s'" % group_name)
		return []


# Check if all loading (scenes and resources) is complete
func is_loading_complete() -> bool:
	return not _is_loading_scenes and not _is_loading_resources

func get_saved_character_sheets() -> void:
	var files = ExternalUtility.get_jsons_from_dir("user://Assets/CharacterSheets/")
	for file in files:
		if file:
			var character_name = file["character_name"]
			if not character_name.is_empty():
				loaded_sheets[character_name] = file
			else:
				ErrorUtility.log_warning("GetSavedCharacterSheets: Empty character name derived from file object: %s" % str(file))
		else:
			ErrorUtility.log_warning("GetSavedCharacterSheets: Unexpected item returned by get_jsons_from_dir: %s" % str(file))

# ==================== DATA UPLOAD (Restored) ====================

# Example function for uploading map data
func upload(load_node: Node, hide: bool = true) -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/", true)
	for file in files:
		if file:
			var map_name = file.get_file().get_basename()
			if not map_name.is_empty():
				var map_file_path = "user://Assets/Maps/" + map_name + ".dd2vtt"
				await Net.send_dd2vtt_request(map_file_path) # Assumes Net exists
			else:
				ErrorUtility.log_warning("Upload: Empty map name derived from file object: %s" % str(file))
		else:
			ErrorUtility.log_warning("Upload: Unexpected item returned by get_all_files_in_dir: %s" % str(file))

	if hide:
		if is_instance_valid(load_node):
			load_node.hide()
		else:
			ErrorUtility.log_warning("Upload: load_node is not valid, cannot hide.")


# ==================== UI HELPERS ====================

func get_menu() -> Node:
	if Settings.window_settings["width"] >= 3000:
		return Settings.custom_windows["Menu3K"]
	else:
		return Settings.custom_windows["Menu"]

func get_message_box() -> Node:
	if Settings.window_settings["width"] >= 3000:
		return Settings.custom_windows["MessageBox3K"]
	else:
		return Settings.custom_windows["MessageBox"]


# ==================== ASYNC LOADING FUNCTIONS ====================

# --- Scene Loading ---
func load_scenes_from_directory_async(folder_path: String, recursive: bool = false, group_name: String = "") -> void:
	_current_scene_group_name = group_name
	_scenes_to_load = _get_file_paths_in_folder(folder_path, recursive, [".tscn"])
	_loaded_scenes[group_name] = []
	_current_scene_load_index = 0
	_is_loading_scenes = not _scenes_to_load.is_empty()
	if _is_loading_scenes:
		print("Starting async scene load for group '%s' (%d scenes)" % [group_name, _scenes_to_load.size()])
		set_process(true)
	# else:
		ErrorUtility.log_warning("No '.tscn' files found to load for group '%s' starting from: %s" % [group_name, folder_path])


# --- Resource Loading ---
func load_resources_from_directory_async(folder_path: String, recursive: bool, target_dictionary: Dictionary, name_property: String, extensions: Array[String]) -> void:
	print("Queueing async resource load from '%s' (Recursive: %s, Name Prop: '%s', Exts: %s)" % [folder_path, recursive, name_property, extensions])

	var resource_paths: Array[String] = _get_file_paths_in_folder(folder_path, recursive, extensions)

	if resource_paths.is_empty():
		ErrorUtility.log_warning("No resources with extensions %s found in '%s' to queue." % [extensions, folder_path])
		return

	var initial_queue_size = _resources_to_load.size()
	for path in resource_paths:
		_resources_to_load.append({
			"path": path,
			"target_dict": target_dictionary,
			"name_prop": name_property
		})
		var error = ResourceLoader.load_threaded_request(path)
		if error != Error.OK:
			printerr("Failed to start threaded load request for: %s. Error: %s" % [path, error])
			_resource_load_requests[path] = ResourceLoader.THREAD_LOAD_FAILED

	var num_queued = resource_paths.size()
	_total_resources_to_load += num_queued

	if num_queued > 0:
		_is_loading_resources = true
		set_process(true)


# ==================== PROCESS LOOP (Handles Loading) ====================

func _process(delta: float) -> void:
	var still_loading_scenes = false
	var still_loading_resources = false

	# --- Process Scene Loading ---
	if _is_loading_scenes:
		if _current_scene_load_index < _scenes_to_load.size():
			var scene_path = _scenes_to_load[_current_scene_load_index]
			var scene = load(scene_path) # Sync load per frame
			if scene is PackedScene:
				if not _loaded_scenes.has(_current_scene_group_name):
					_loaded_scenes[_current_scene_group_name] = []
				_loaded_scenes[_current_scene_group_name].append(scene)
			_current_scene_load_index += 1
			still_loading_scenes = true
		else:
			print("Async scene loading complete for group '%s'." % _current_scene_group_name)
			_is_loading_scenes = false
			_scenes_to_load.clear()
			_current_scene_load_index = 0
			_current_scene_group_name = ""

	# --- Process Resource Loading ---
	if _is_loading_resources:
		if _current_resource_load_index < _resources_to_load.size():
			var load_info: Dictionary = _resources_to_load[_current_resource_load_index]
			var path: String = load_info["path"]
			var target_dict: Dictionary = load_info["target_dict"]
			var name_prop: String = load_info["name_prop"]
			var status = ResourceLoader.load_threaded_get_status(path, _resource_load_requests.get(path, []))
			var processed_this_frame = false

			match status:
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					still_loading_resources = true
				ResourceLoader.THREAD_LOAD_LOADED:
					var res: Resource = ResourceLoader.load_threaded_get(path)
					if res is Resource and name_prop in res:
						var res_name_var: Variant = res.get(name_prop)
						if typeof(res_name_var) == TYPE_STRING and not res_name_var.is_empty():
							var res_name: String = res_name_var.to_lower()
							# Apply necessary key formatting (e.g., lowercase) if needed
							# res_name = res_name_var.to_lower()
							if target_dict.has(res_name):
								ErrorUtility.log_warning("Duplicate resource name '%s' loaded (Path: %s). Overwriting." % [res_name, path])
							target_dict[res_name] = res
						# else: Handle invalid name value
						else:
							printerr("  FAILED: Name property value is empty or not a string for path: %s" % path)
					else:
						printerr("  FAILED: Name property '%s' not found in resource for path: %s" % [name_prop, path])
						printerr("  FAILED: Loaded resource is invalid for path: %s" % path)
					# else: Handle missing name prop or wrong type
					processed_this_frame = true
					_resource_load_requests.erase(path)
				ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					printerr("Threaded resource load failed for path: %s, Status: %s" % [path, status])
					processed_this_frame = true
					_resource_load_requests.erase(path)
				_:
					still_loading_resources = true

			if processed_this_frame:
				_current_resource_load_index += 1

			if _current_resource_load_index < _resources_to_load.size():
				still_loading_resources = true
		else:
			print("Asynchronous resource loading complete (%d total queued)." % _total_resources_to_load)
			_is_loading_resources = false
			_resources_to_load.clear()
			_current_resource_load_index = 0
			_total_resources_to_load = 0
			_resource_load_requests.clear()

	# --- Disable _process ---
	if not still_loading_scenes and not still_loading_resources:
		if not _is_loading_scenes and not _is_loading_resources: # Check flags again after processing
			set_process(false)
			print("CacheManager: _process disabled - all loading complete.")
			print(loaded_lineages)
			loading_complete.emit()


# ==================== HELPER FUNCTIONS ====================

# --- Generic Directory Scanner (Using ResourceLoader) ---
func _get_file_paths_in_folder(folder_path: String, recursive: bool, extensions: Array[String]) -> Array[String]:
	var file_paths: Array[String] = []
	var folders_to_scan: Array[String] = [folder_path]
	var scanned_folders: PackedStringArray = []
	var lower_extensions: Array[String] = []
	for ext in extensions: lower_extensions.append(ext.to_lower())

	while not folders_to_scan.is_empty():
		var current_folder: String = folders_to_scan.pop_front()
		if not current_folder.ends_with("/"): current_folder += "/"
		if scanned_folders.has(current_folder): continue
		scanned_folders.append(current_folder)

		var entries: PackedStringArray = ResourceLoader.list_directory(current_folder)
		if entries.is_empty(): continue

		for entry_name in entries:
			if entry_name == "." or entry_name == "..": continue
			var full_path = current_folder + entry_name
			var is_directory_guess = entry_name.ends_with("/") or not entry_name.contains(".")
			if is_directory_guess:
				if recursive and ResourceLoader.exists(full_path):
					folders_to_scan.append(full_path)
			else:
				var file_ext = "." + entry_name.get_extension().to_lower()
				if lower_extensions.has(file_ext):
					file_paths.append(full_path)
	return file_paths

func prepare_monster_sheet_data(raw_data: Dictionary) -> Dictionary:
	var prepared_data := {}

	# 1. Copy simple values directly
	prepared_data["monster_name"] = raw_data.get("monster_name", "Default Monster") # Use key expected by MonsterSheet
	prepared_data["flavor_text"] = raw_data.get("flavor_text", "")
	prepared_data["description"] = raw_data.get("description", "") # Use key expected by MonsterSheet
	prepared_data["level"] = raw_data.get("level", 0)
	prepared_data["gender"] = raw_data.get("gender", "Male")
	prepared_data["base_speed"] = raw_data.get("base_speed", 30)
	prepared_data["base_swim_speed"] = raw_data.get("base_swim_speed", 0)
	prepared_data["base_fly_speed"] = raw_data.get("base_fly_speed", 0)
	prepared_data["base_climb_speed"] = raw_data.get("base_climb_speed", 0)
	prepared_data["base_burrow_speed"] = raw_data.get("base_burrow_speed", 0)
	prepared_data["base_armor_class"] = raw_data.get("base_armor_class", 10)
	prepared_data["might_modifier"] = raw_data.get("might_modifier", 0)
	prepared_data["agility_modifier"] = raw_data.get("agility_modifier", 0)
	prepared_data["endurance_modifier"] = raw_data.get("endurance_modifier", 0)
	prepared_data["intelligence_modifier"] = raw_data.get("intelligence_modifier", 0)
	prepared_data["insight_modifier"] = raw_data.get("insight_modifier", 0)
	prepared_data["charisma_modifier"] = raw_data.get("charisma_modifier", 0)
	prepared_data["might_saving_throw"] = raw_data.get("might_saving_throw", 0)
	prepared_data["agility_saving_throw"] = raw_data.get("agility_saving_throw", 0)
	prepared_data["endurance_saving_throw"] = raw_data.get("endurance_saving_throw", 0)
	prepared_data["intelligence_saving_throw"] = raw_data.get("intelligence_saving_throw", 0)
	prepared_data["insight_saving_throw"] = raw_data.get("insight_saving_throw", 0)
	prepared_data["charisma_saving_throw"] = raw_data.get("charisma_saving_throw", 0)
	prepared_data["max_hit_points"] = raw_data.get("max_hit_points", 10)
	prepared_data["max_temporary_hit_points"] = raw_data.get("max_temporary_hit_points", 0)
	prepared_data["max_actions"] = raw_data.get("max_actions", 1)
	prepared_data["max_bonus_actions"] = raw_data.get("max_bonus_actions", 0)
	prepared_data["max_reactions"] = raw_data.get("max_reactions", 0)
	prepared_data["max_aether_points"] = raw_data.get("max_aether_points", 0)
	prepared_data["max_stamina_points"] = raw_data.get("max_stamina_points", 0)
	prepared_data["perception_modifier"] = raw_data.get("perception_modifier", 10)
	prepared_data["equipped_items"] = raw_data.get("equipped_items", {}) # Assumes dict copy is sufficient
	prepared_data["loot_table"] = raw_data.get("loot_table", []) # Assumes array copy is sufficient
	prepared_data["talents"] = raw_data.get("talents", []) # Assumes array copy is sufficient
	prepared_data["senses"] = raw_data.get("senses", {}) # Assumes dict copy is sufficient
	prepared_data["species"] = raw_data.get("species", null) # Assuming this is handled elsewhere or is just name/ID

	# Copy CURRENT state values if they exist in raw_data (important for loading saves)
	prepared_data["current_hit_points"] = raw_data.get("current_hit_points", prepared_data["max_hit_points"])
	prepared_data["current_temporary_hit_points"] = raw_data.get("current_temporary_hit_points", 0)
	prepared_data["current_aether_points"] = raw_data.get("current_aether_points", prepared_data["max_aether_points"])
	prepared_data["current_stamina_points"] = raw_data.get("current_stamina_points", prepared_data["max_stamina_points"])
	prepared_data["current_actions_available"] = raw_data.get("current_actions_available", prepared_data["max_actions"])
	prepared_data["current_bonus_actions_available"] = raw_data.get("current_bonus_actions_available", prepared_data["max_bonus_actions"])
	prepared_data["current_reactions_available"] = raw_data.get("current_reactions_available", prepared_data["max_reactions"])
	prepared_data["current_armor_class"] = raw_data.get("current_armor_class", prepared_data["base_armor_class"])
	prepared_data["current_speed"] = raw_data.get("current_speed", prepared_data["base_speed"])
	prepared_data["current_conditions"] = raw_data.get("current_conditions", [])
	prepared_data["active_effects"] = raw_data.get("active_effects", [])

	# 2. Handle Size Enum Conversion -> Store INT in prepared_data
	var size_string = raw_data.get("size", "MEDIUM") # Get string from raw data
	var size_enum_value = GameConst.MonsterSize.MEDIUM # Default
	if "MonsterSize" in GameConst:
		var size_keys = GameConst.MonsterSize.keys()
		if size_string.to_upper() in size_keys:
			size_enum_value = GameConst.MonsterSize[size_string.to_upper()]
		else:
			printerr("Prepare Data: Unknown monster size string found: ", size_string)
	else:
		printerr("Prepare Data: GameConst.MonsterSize enum not found.")
	prepared_data["size"] = size_enum_value # Store the INT value

	# 3. Handle Basic Arrays (Languages, Skills)
	prepared_data["languages"] = raw_data.get("languages", ["Common"])

	# 4. Handle Arrays of Enums (Defenses) -> Store Array[INT] in prepared_data
	# Use a generic helper or repeat logic
	prepared_data["damage_immunities"] = _convert_enum_name_array(raw_data.get("damage_immunities", []), GameConst, "DamageType")
	prepared_data["damage_resistances"] = _convert_enum_name_array(raw_data.get("damage_resistances", []), GameConst, "DamageType")
	prepared_data["damage_weaknesses"] = _convert_enum_name_array(raw_data.get("damage_weaknesses", []), GameConst, "DamageType")
	prepared_data["condition_immunities"] = _convert_enum_name_array(raw_data.get("condition_immunities", []), GameConst, "Condition")


	# 5. Handle Arrays of Resources -> Store Array[Resource] in prepared_data
	# Use a generic helper or repeat logic
	# NEED TO CHANGE FOR RESOURCES LATER
	prepared_data["proactive_abilities"] = _load_resource_name_array(raw_data.get("proactive_abilities", []), "MonsterAbilityResource", "res://Content/Monsters/Abilities/" + prepared_data["monster_name"].to_lower() + "/")
	prepared_data["automatic_abilities"] = _load_resource_name_array(raw_data.get("automatic_abilities", []), "MonsterAbilityResource", "res://Content/Monsters/Abilities/" + prepared_data["monster_name"].to_lower() + "/")
	prepared_data["spells"] = raw_data.get("spells", [])
	prepared_data["traits"] = _load_resource_name_array(raw_data.get("traits", []), "TraitResource")
	prepared_data["attacks"] = _load_resource_name_array(raw_data.get("attacks", []), "MonsterAttackResource", "res://Content/Monsters/Attacks/" + prepared_data["monster_name"].to_lower() + "/")
	prepared_data["skills"] = raw_data.get("skills", {})
	# 6. Handle Movement State Enum -> Store INT in prepared_data
	var move_state_string = raw_data.get("current_movement_state", "LAND") # Default to LAND
	if not move_state_string is String:
		move_state_string = "LAND" # Default to LAND if not a string
		printerr("Prepare Data: Movement state is not a string, defaulting to LAND.")
	var move_state_enum_value = GameConst.MovementState.LAND # Default
	if "MovementState" in GameConst:
		var move_state_keys = GameConst.MovementState.keys()
		if move_state_string.to_upper() in move_state_keys:
			move_state_enum_value = GameConst.MovementState[move_state_string.to_upper()]
		else:
			printerr("Prepare Data: Unknown movement state string found: ", move_state_string)
	else:
		printerr("Prepare Data: GameConst.MovementState enum not found.")
	prepared_data["current_movement_state"] = move_state_enum_value

	# 7. Handle Texture Path -> Load Texture2D
	var texture_path = raw_data.get("texture_path", "") # Assume path is stored
	prepared_data["texture"] = null
	if texture_path is String and not texture_path.is_empty():
		if ResourceLoader.exists(texture_path):
			prepared_data["texture"] = ResourceLoader.load(texture_path)
		else:
			printerr("Prepare Data: Texture path not found '%s'." % texture_path)
			# Maybe load a default texture here instead of null?
			# prepared_data["texture"] = load("res://path/to/default.png")

	return prepared_data

func _convert_enum_name_array(names_array: Array, enum_container, enum_name: String) -> Array:
	var enum_values: Array = []
	if not enum_name in enum_container:
		printerr("Prepare Data Helper: Enum '%s' not found in container." % enum_name)
		return []
	if not names_array is Array:
		return [] # Return empty if input isn't array

	var specific_enum = enum_container[enum_name]
	var enum_keys = specific_enum.keys()

	for name in names_array:
		if name is String:
			var upper_name = name.to_upper() # Assuming enums use uppercase keys
			if upper_name in enum_keys:
				enum_values.append(specific_enum[upper_name])
			else:
				printerr("Prepare Data Helper: Enum key '%s' not found in enum '%s'." % [upper_name, enum_name])
		elif name is int and name in specific_enum.values():
			enum_values.append(name) # Allow passing integers too
		else:
			printerr("Prepare Data Helper: Invalid item '%s' in enum name array for '%s'." % [name, enum_name])

	return enum_values

# Helper to convert an array of string names to an array of loaded Resource instances
func _load_resource_name_array(names_array: Array, resource_class_name: String, specific_path: String = "") -> Array:
	var loaded_resources: Array = [] # Consider Array[Resource] if needed elsewhere
	if not names_array is Array:
		return [] # Return empty if input isn't array

	# Determine base path (adjust this logic based on your project structure)
	var base_content_path = "res://Content/"
	var resource_folder = resource_class_name.replace("Resource", "s") # e.g., "Traits", "Spells"
	var full_dir_path = base_content_path.path_join(resource_folder)
	if specific_path != "":
		full_dir_path = specific_path

	for name in names_array:
		if name is String:
			var file_path = full_dir_path.path_join(name.to_lower() + ".tres") # Assuming lowercase filenames
			if ResourceLoader.exists(file_path):
				var res = ResourceLoader.load(file_path).duplicate(true)
				# Optional: Check type if needed: if res is load("res://path/to/" + resource_class_name + ".gd"):
				if is_instance_valid(res):
					loaded_resources.append(res)
				else:
					printerr("Prepare Data Helper: Loaded resource at '%s' is invalid." % file_path)
			else:
				# Use self.get_resource if it exists in Cache, otherwise ResourceLoader directly
				var res_alt = Cache.get_resource(full_dir_path, name) if Cache.has_method("get_resource") else null
				if is_instance_valid(res_alt):
					loaded_resources.append(res_alt)
				else:
					printerr("Prepare Data Helper: Resource not found for name '%s' in path '%s'." % [name, full_dir_path])
		else:
			printerr("Prepare Data Helper: Invalid name type '%s' in resource array for '%s'." % [typeof(name), resource_class_name])

	return loaded_resources


# ==================== CLEANUP ====================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("CacheManager: Cleaning up on close request...")
		set_process(false)
		# Clear scene loading state
		_is_loading_scenes = false
		_scenes_to_load.clear()
		_loaded_scenes.clear()
		_current_scene_load_index = 0
		_current_scene_group_name = ""
		# Clear resource loading state
		_is_loading_resources = false
		_resources_to_load.clear()
		_resource_load_requests.clear()
		_current_resource_load_index = 0
		_total_resources_to_load = 0
		# Clear resource dictionaries
		loaded_traits.clear()
		loaded_monsters.clear()
		loaded_skills.clear()
		print("CacheManager: Cleanup complete.")
