# TRAIT #
extends Node

# ===================== JSON CONSTANTS =====================
# These are the required keys and types for the JSON files,
# that need to be parsed into resources

const TRAIT_JSON_KEYS = ["name", "description", "category"]
const TRAIT_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY]

const PERK_JSON_KEYS = ["name", "description", "traits", "costs", "category", "requirements", "prerequisites", "level", "extra"]
const PERK_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_FLOAT, TYPE_DICTIONARY]

const FEAT_JSON_KEYS = ["name", "description", "traits", "costs", "requirements", "prerequisites", "level", "frequency", "modifiers", "extra"]
const FEAT_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_STRING, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT, TYPE_DICTIONARY, TYPE_DICTIONARY]

const ACTION_JSON_KEYS = ["name", "description", "traits", "costs", "type", "proficiency_required", "targets", "range", "duration", "requirements", "extra"]
const ACTION_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_STRING, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_STRING, TYPE_DICTIONARY]

const SKILL_JSON_KEYS = ["name", "description", "key_attribute", "proficiency", "untrained_actions", "trained_actions"]
const SKILL_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_ARRAY]

const ABILITY_JSON_KEYS = ["name", "description", "traits", "costs", "range", "targets", "defense", "duration", "area", "area_type", "activation_type", "cooldown"]
const ABILITY_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_FLOAT, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING, TYPE_FLOAT]

const AFFINITY_JSON_KEYS = ["name", "description", "traits", "forced_attributes", "free_attributes", "skills", "perks", "extra"]
const AFFINITY_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_ARRAY, TYPE_ARRAY, TYPE_DICTIONARY]

const LINEAGE_JSON_KEYS = ["name", "description", "feats", "perks", "extra"]
const LINEAGE_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_ARRAY, TYPE_DICTIONARY]

const VERSATILELINEAGE_JSON_KEYS = ["name", "description", "feats", "perks", "extra", "traits", "society", "beliefs", "base_languages", "additional_languages", "abilities", "lineages"]
const VERSATILELINEAGE_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_ARRAY, TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_ARRAY, TYPE_ARRAY, TYPE_ARRAY]

const SPELL_JSON_KEYS = ["name", "description", "traits", "tier", "costs", "damage", "damage_type", "cooldown", "range", "area", "area_type", "targets", "defense_type", "duration", "tradition", "is_heightened", "heightened_effects", "heightened_costs", "spell_school", "spell_type", "essence_type", "prerequisites", "extra"]
const SPELL_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_FLOAT, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_STRING, TYPE_FLOAT, TYPE_STRING, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL, TYPE_DICTIONARY, TYPE_DICTIONARY, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_DICTIONARY]

const ITEM_JSON_KEYS = ["name", "description", "traits", "is_activatable", "activation_cost", "activation_description", "price", "weight"]
const ITEM_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_BOOL, TYPE_FLOAT, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT]

const WEAPON_JSON_KEYS = ["name"]
const WEAPON_JSON_TYPES = [TYPE_STRING]

const ARMOR_JSON_KEYS = ["name", "level", "Defense", "Price", "AC_Bonus", "Agi_Cap", "Weight", "Group"]
const ARMOR_JSON_TYPES = [TYPE_STRING, TYPE_FLOAT, TYPE_STRING, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_STRING]

const SHIELD_JSON_KEYS = ["name", "description", "traits", "is_activatable", "activation_cost", "activation_description", "price", "weight", "armor_class", "shield_penalties", "max_dex", "hardness", "hit_points", "broken_threshold"]
const SHIELD_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_BOOL, TYPE_FLOAT, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT]

const ARCHETYPE_JSON_KEYS = ["name", "description", "traits", "feats", "dedication_feat"]
const ARCHETYPE_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_ARRAY, TYPE_STRING]

const DEITY_JSON_KEYS = ["name", "description", "areas_of_concern", "edicts", "anathema", "symbol", "divine_attribute", "divine_font", "divine_consecration", "divine_skill", "domains", "favored_weapon_group"]
const DEITY_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_ARRAY, TYPE_ARRAY, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_STRING]

const SPECIE_JSON_KEYS = ["name", "description", "traits", "society", "beliefs", "hit_points", "stamina_points", "size", "speed", "base_languages", "additional_languages", "lineages", "abilities", "feats"]
const SPECIE_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_STRING, TYPE_STRING, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_ARRAY, TYPE_ARRAY, TYPE_ARRAY, TYPE_ARRAY, TYPE_ARRAY]

const CONDITION_JSON_KEYS = ["name", "description", "traits", "modifiers", "onset_time", "maximum_duration", "frequency"]
const CONDITION_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT]

const STAGECONDITION_JSON_KEYS = ["name", "description", "traits", "modifiers", "onset_time", "maximum_duration", "frequency", "stage", "max_stage", "interval", "stackable", "modifier_scaling"]
const STAGECONDITION_JSON_TYPES = [TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_FLOAT, TYPE_BOOL, TYPE_DICTIONARY]

const MONSTER_JSON_KEYS = ["name", "level", "size", "type", "traits", "perception", "attributes", "defenses", "HP", "movement", "attacks"]
const MONSTER_JSON_TYPES = [TYPE_STRING, TYPE_FLOAT, TYPE_STRING, TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_DICTIONARY, TYPE_DICTIONARY, TYPE_FLOAT, TYPE_DICTIONARY, TYPE_ARRAY]

const MONSTER_ABILITY_JSON_KEYS = ["name", "description"]
const MONSTER_ABILITY_JSON_TYPES = [TYPE_STRING, TYPE_STRING]

const MONSTER_ATTACK_JSON_KEYS = ["name", "type"]
const MONSTER_ATTACK_JSON_TYPES = [TYPE_STRING, TYPE_STRING]