class_name AffinityResource extends Resource

# Base class for all affinities
var a_name: String
var description: String
var traits: Array[TraitResource]
var forced_attributes: Dictionary
var free_attributes: int
var skills: Array[SkillResource]
var perks: Array[PerkResource]
var extra: Dictionary