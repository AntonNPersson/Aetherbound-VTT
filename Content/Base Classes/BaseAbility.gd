extends Resource
class_name AbilityResource

# Base class for all abilities
var a_name: String
var description: String
var traits: Array[TraitResource]
var costs = {
    "AP": 0,
    "MP": 0,
    "KP": 0,
    "SP": 0,
    "PP": 0
}
var range : int
var targets : int
var defense : Dictionary
var duration : int
var area : int
var area_type : String
var activation_type : String
var cooldown : int
