class_name LineageResource extends Resource

# ===================== LINEAGE RESOURCE =====================
# Base class for all lineages

# Variables
@export var l_name: String = ""
@export_multiline var description: String = ""
@export var perks: Array = []
@export var extra : Dictionary = {}

# ===================== LINEAGE FUNCTIONS =====================

# Get the name of the lineage
# Args: None
# Returns: String - Name of the lineage
func get_resource_name() -> String: return l_name
func get_description() -> String: return description
func get_perks() -> Array: return perks
func get_perk_names() -> Array:
    var perk_names : Array = []
    for perk in self.perks:
        if perk.has_method("get_resource_name"):
            perk_names.append(perk.get_resource_name())
        else:
            push_warning("Perk " + perk + " does not have a resource name.")
    return perk_names