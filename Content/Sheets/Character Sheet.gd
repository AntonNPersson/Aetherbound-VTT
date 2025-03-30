class_name CharacterSheet extends Resource

# enum DamageType { ... }
# enum Condition { ... }
# enum Skill { ACROBATICS, ATHLETICS, ... }

# --- Basic Info ---
@export var character_name: String = "Default Name"
@export_multiline var edicts: String = ""       # E.g., Paladin oaths, cleric doctrines
@export_multiline var anathemas: String = ""    # Things forbidden by belief/class
@export var age: int = 20
@export var gender: String = ""
@export var height: float = 1.7 # Meters or feet, be consistent
@export var weight: float = 70.0 # Kg or lbs, be consistent
# Personality - These could also be arrays of strings or dedicated resources
@export_multiline var personality_traits: String = ""
@export_multiline var ideals: String = ""
@export_multiline var bonds: String = ""
@export_multiline var flaws: String = ""

# --- Core Stats & Progression ---
@export var level: int = 1
@export var experience_points: int = 0 # Total XP accumulated (level derived from this)
#@export var character_class: ClassResource = null # Assign specific ClassResource here
@export var specie: SpecieResource = null     # Assign specific SpecieResource here
@export var affinity: AffinityResource = null # Assign specific AffinityResource here

# --- Base Combat / Derived Stats (Template Values) ---
@export var armor_class: int = 10 # Base AC, often modified by Agility/Armor
@export var speed: int = 30       # Base speed in units per second or feet per round
@export var perception_score: int = 10 # Base perception attribute (e.g., Wisdom score)
# Add other derived base stats if needed (e.g., base Class DC, base saving throws)
@export var class_dc_base: int = 10

# --- Attributes (Base Scores) ---
@export var might_score: int = 10
@export var agility_score: int = 10   
@export var endurance_score: int = 10   
@export var intelligence_score: int = 10
@export var wisdom_score: int = 10   
@export var charisma_score: int = 10   

# --- Stat Resources (Maximums/Base) ---
@export var health_points: int = 10    # Max HP (often Class HD + Endurance Mod per level)
@export var action_points: int = 1     # Base # actions/round (e.g., 1 Action, 1 Bonus, 1 Reaction)
@export var aether_points: int = 0     # Max Mana/Spell points/etc.
@export var mythic_points: int = 0     # Max points for special abilities
@export var inspiration_points: int = 0 # Max points for inspiration/hero points
@export var carrying_capacity: int = 0 # Calculated from Might typically

# --- Skills, Feats, Abilities, Spells (Links to other Resources/Definitions) ---
# Store proficiency/known items. Actual modifiers calculated at runtime.
@export var skills_proficiency: Array[String] = [] # Array of skill names/enums character is proficient in
@export var saving_throw_proficiency: Array[String] = [] # e.g., ["might", "endurance"]
@export var feats: Array[FeatResource] = []         # Assign FeatResource instances
@export var spells_known: Array[SpellResource] = [] # Assign SpellResource instances known/prepared
@export var traits: Array[TraitResource] = []       # Assign TraitResource instances (racial, class features)
@export var languages: Array[String] = ["Common"]   # List of known languages

# --- Helper function to calculate modifiers from scores ---
# Call these from the Character Node script when needing a modifier.
func get_modifier(score: int) -> int:
	return score

func get_might_modifier() -> int: return get_modifier(might_score)
func get_agility_modifier() -> int: return get_modifier(agility_score)
func get_endurance_modifier() -> int: return get_modifier(endurance_score)
func get_intelligence_modifier() -> int: return get_modifier(intelligence_score)
func get_wisdom_modifier() -> int: return get_modifier(wisdom_score)
func get_charisma_modifier() -> int: return get_modifier(charisma_score)

func add_trait(traitresource: TraitResource) -> void:
	# Adds a trait to the character sheet
	if traitresource not in traits:
		traits.append(traitresource)
		print("Trait added:", traitresource.t_name)
	else:
		print("Trait already exists:", traitresource.t_name)

func remove_trait(traitresource: TraitResource) -> void:
	# Removes a trait from the character sheet
	if traitresource in traits:
		traits.erase(traitresource)
		print("Trait removed:", traitresource.t_name)
	else:
		print("Trait not found:", traitresource.t_name)

func add_spell(spellresource: SpellResource) -> void:
	# Adds a spell to the character sheet
	if spellresource not in spells_known:
		spells_known.append(spellresource)
		print("Spell added:", spellresource.s_name)
	else:
		print("Spell already exists:", spellresource.s_name)

func remove_spell(spellresource: SpellResource) -> void:
	# Removes a spell from the character sheet
	if spellresource in spells_known:
		spells_known.erase(spellresource)
		print("Spell removed:", spellresource.s_name)
	else:
		print("Spell not found:", spellresource.s_name)

func add_feat(featresource: FeatResource) -> void:
	# Adds a feat to the character sheet
	if featresource not in feats:
		feats.append(featresource)
		print("Feat added:", featresource.f_name)
	else:
		print("Feat already exists:", featresource.f_name)

func remove_feat(featresource: FeatResource) -> void:
	# Removes a feat from the character sheet
	if featresource in feats:
		feats.erase(featresource)
		print("Feat removed:", featresource.f_name)
	else:
		print("Feat not found:", featresource.f_name)

func add_skill(skillresource: SkillResource) -> void:
	# Adds a skill to the character sheet
	if skillresource not in skills_proficiency:
		skills_proficiency.append(skillresource)
		print("Skill added:", skillresource.s_name)
	else:
		print("Skill already exists:", skillresource.s_name)

func remove_skill(skillresource: SkillResource) -> void:
	# Removes a skill from the character sheet
	if skillresource in skills_proficiency:
		skills_proficiency.erase(skillresource)
		print("Skill removed:", skillresource.s_name)
	else:
		print("Skill not found:", skillresource.s_name)

func get_unit_name() -> String:
	# Returns the character name
	return character_name

