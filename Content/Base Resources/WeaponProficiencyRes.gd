class_name WeaponProficiencyResource extends Resource
# ===================== ITEM PROFICIENCY RESOURCE =====================
@export var name: String = ""
@export var description: String = ""
@export var proficiency_category: GameConst.WeaponProficiencyCategory = GameConst.WeaponProficiencyCategory.SIMPLE
@export var proficiency : GameConst.ProficiencyRanks = GameConst.ProficiencyRanks.UNTRAINED

# ===================== ITEM PROFICIENCY FUNCTIONS =====================
# Get the name of the proficiency
func get_resource_name() -> String: return name
func get_proficiency_category() -> GameConst.WeaponProficiencyCategory: return proficiency_category
func get_proficiency() -> GameConst.ProficiencyRanks: return proficiency
func get_proficiency_modifier() -> int: return GameConst.RANKS[proficiency]
func get_description() -> String: return description