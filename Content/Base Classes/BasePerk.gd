class_name PerkResource extends Resource

# Base class for all perks
var p_name: String
var description: String
var traits: Array[TraitResource]
var costs = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0
}
var category : String
var requirements : String
var prerequisites : String
var level : int
var extra : Dictionary