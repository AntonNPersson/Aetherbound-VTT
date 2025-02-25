class_name SpecieResource extends Resource

# Base class for all species
var s_name: String
var description: String
var traits: Array[TraitResource]
var society : String
var beleifs : String
var hit_points : int
var stamina_points : int
var size : int
var speed : int
var base_languages : Array[String]
var additional_languages : Array[String]
var lineages : Array[LineageResource]
var special_abilities : Array[AbilityResource]
var feats : Array[FeatResource]