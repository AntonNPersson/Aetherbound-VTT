class_name FeatResource extends Resource

# Base class for all feats
var f_name: String
var description: String
var traits: Array[TraitResource]
var costs = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0
}
var requirements: String
var prerequisites: String
var level: int
var frequency: int
var extra : Dictionary
