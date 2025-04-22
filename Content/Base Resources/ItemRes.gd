class_name ItemResource extends Resource

# ===================== ITEM RESOURCE =====================
# Base class for all items

# Variables
@export var i_name: String = ""
@export var description: String = ""
@export var traits: Array = []
@export var is_activatable: bool = false
@export var activation_cost: int = 0
@export var activation_description: String = ""
@export var price: Dictionary = {}
@export var weight: int = 0
@export var rarity : String = "Common"

# ===================== ITEM FUNCTIONS =====================

# Get the name of the item
# Args: None
# Returns: String - Name of the item
func get_resource_name() -> String: return i_name
func get_traits() -> Array: return traits
func get_description() -> String: return description
func get_price() -> Dictionary: return price
func get_price_in_gold() -> float:
	var total_price: float = 0.0
	for key in price.keys():
		total_price += Helper.convert_currency(price[key], key, "Gold")
	return total_price
func get_price_in_silver() -> float:
	var total_price: float = 0.0
	for key in price.keys():
		total_price += Helper.convert_currency(price[key], key, "Silver")
	return total_price
func get_price_in_copper() -> float:
	var total_price: float = 0.0
	for key in price.keys():
		total_price += Helper.convert_currency(price[key], key, "Copper")
	return total_price
func get_price_in_platinum() -> float:
	var total_price: float = 0.0
	for key in price.keys():
		total_price += Helper.convert_currency(price[key], key, "Platinum")
	return total_price
func get_weight() -> int: return weight

func initialize_from_dict(data: Dictionary) -> void:
	i_name = data.get("name", i_name)
	description = data.get("description", description)
	rarity = data.get("rarity", rarity)
	for t in data.get("traits", []):
		traits.append(Cache.find_loaded_resource_by_name(t.to_lower(), "TraitResource"))

	is_activatable = data.get("is_activatable", is_activatable)
	activation_cost = data.get("activation_cost", activation_cost)
	activation_description = data.get("activation_description", activation_description)
	price = data.get("price", price)
	weight = data.get("weight", weight)

func get_dictionary() -> Dictionary:
	var item_dict: Dictionary = {
		"name": i_name,
		"description": description,
		"traits": [],
		"rarity": rarity,
		"price": price,
		"weight": weight,
		
	}

	if item_dict["traits"] == []:
		item_dict.erase("traits")
	return item_dict
