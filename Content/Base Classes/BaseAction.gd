class_name ActionResource extends Resource

# Base class for all actions
var a_name: String
var description: String
var traits : Array[TraitResource]
var costs = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0
}
var type : String
var proficiency_required : ProficiencyResource
var skill_check : String
var opposed_skill_check : String
var targets : int
var range : int
var duration : int
var requirements : String
var extra : Dictionary