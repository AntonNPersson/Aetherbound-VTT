extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var test_trait = TraitResource.new("Test Trait", "This is a test trait", {"str" : 2, "dex" : 1})
	print("Name: ", test_trait.t_name)
	print("Description: ", test_trait.description)
	print("Modifiers Names: ", test_trait.get_modifiers())
	print("Modifier Value STR: ", test_trait.get_modifier("str"))
	print("Modifier Value DEX: ", test_trait.get_modifier("dex"))

	var test_perk = PerkResource.new("Test Perk", "This is a test perk", [test_trait], {"AP": 1}, "Class", "None", "None", 1)
	print("Name: ", test_perk.p_name)
	print("Description: ", test_perk.description)
	print("Costs names: ", test_perk.get_costs())
	print("Cost AP: ", test_perk.get_cost("AP"))

	var test_feat = FeatResource.new("Test Feat", "This is a test feat", [test_trait], {"AP": 1}, "None", "None", 1, 0, {"str" : 2, "dex" : 1})
	print("Name: ", test_feat.f_name)
	print("Description: ", test_feat.description)
	print("Costs names: ", test_feat.get_costs())
	print("Cost AP: ", test_feat.get_cost("AP"))
	print("Modifiers Names: ", test_feat.get_modifiers())

	var test_lineage = LineageResource.new("Test Lineage", "Test", [test_feat], [test_perk], {})
	print("Name: ", test_lineage.l_name)
	print("Description: ", test_lineage.description)

	var test_specie = SpecieResource.new("Test Specie", "Test", [test_trait], "None", "None", 1, 1, 10, 10, ["Humanoid"], ["Common"], [test_lineage], [], [test_feat])
	print("Name: ", test_specie.s_name)
	print("Description: ", test_specie.description)
	print("Feats", test_specie.get_feat_at_level(1))