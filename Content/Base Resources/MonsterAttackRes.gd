class_name MonsterAttackResource extends Resource

@export var name: String = "Attack Name"
@export var type: String = "Melee" # Or use an enum: Melee, Ranged
@export var ap_cost: int = 1
@export var attack_bonus: int = 0
@export var traits: Array[String] = [] # e.g., ["agile", "finesse"]
# Store damage simply for now, maybe refine later
@export var damage_string: String = "2d10+10" # Simple text representation
# Or more structured:
@export var damage_type: GameConst.DamageType = GameConst.DamageType.PIERCING
@export var effects_description: String = "" # e.g., "Improved Grab"