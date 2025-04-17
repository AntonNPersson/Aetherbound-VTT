class_name AttackResource extends Resource
@export var name: String = "Unarmed Strike"
@export var description: String = "A basic unarmed attack."
@export var traits: Array = []
@export var damage_string: String = "1d4"
@export var damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING
@export var damage_category: GameConst.DamageCategory = GameConst.DamageCategory.MELEE
@export var damage_bonus: int = 0
@export var range: int = 5
@export var weapon: WeaponResource = null

func get_dictionary() -> Dictionary:
    return {
        "name": name,
        "description": description,
        "traits": traits,
        "damage_string": damage_string,
        "damage_type": GameConst.get_damage_type_as_string(damage_type),
        "damage_category": GameConst.get_damage_category_as_string(damage_category),
        "damage_bonus": damage_bonus,
        "range": range
    }

func get_resource_name() -> String:
    return name

func apply_weapon(weapon: WeaponResource) -> void:
    if weapon.has_method("get_damage_string"): damage_string = weapon.get_damage_string()
    if weapon.has_method("get_damage_type"): damage_type = weapon.get_damage_type()
    if weapon.has_method("get_damage_category"): damage_category = weapon.get_damage_category()
    if weapon.has_method("get_damage_bonus"): damage_bonus = weapon.get_damage_bonus()
    if weapon.has_method("get_range"): range = weapon.get_range()
    if weapon.has_method("get_traits"): traits = weapon.get_traits()
    if weapon != null: self.weapon = weapon

    for category in weapon.get_damage_category():
        if category == GameConst.DamageCategory.MELEE: name = "Melee Strike"
        elif category == GameConst.DamageCategory.RANGED: name = "Ranged Strike"
        elif category == GameConst.DamageCategory.NATURAL: name = "Natural Strike"
        elif category == GameConst.DamageCategory.UNARMED: name = "Unarmed Strike"
        else:
            printerr("Error: Unknown damage category.")
            name = "Unarmed Strike"

func execute(character: Resource, target: Variant, hit_modifiers: int = 0, damage_modifiers: int = 0, map: int = 0) -> void:
    if !is_instance_valid(character) or !is_instance_valid(target):
        ErrorUtility.print_error("Invalid monster or target.")
        return


    var effective_attribute_modifier = 0
    var effective_proficiency_modifier = 0
    var effective_item_modifiers = 0

    var has_finesse = false

    for t in traits:
        if t.get_resource_name() == "Finesse":
            has_finesse = true
            break

    if has_finesse:
        var agi = 0
        var might = 0
        if character.has_method("get_unit_agility_modifier"):
            agi = character.get_unit_agility_modifier()
        else:
            printerr("Error: Character does not have an agility modifier method.")
            return
        if character.has_method("get_unit_might_modifier"):
            might = character.get_unit_might_modifier()
        else:
            printerr("Error: Character does not have a might modifier method.")
            return
        effective_attribute_modifier = agi if agi > might else might
    else:
        if character.has_method("get_unit_might_modifier"):
            effective_attribute_modifier = character.get_unit_might_modifier()
        else:
            printerr("Error: Character does not have a might modifier method.")
            return

    
    if weapon.has_method("get_weapon_proficiency_category"):
        effective_proficiency_modifier = character.get_weapon_proficiency_modifier(weapon.get_weapon_proficiency_category())

    # if weapon.has_method("get_item_modifiers):
    #     effective_item_modifiers = weapon.get_item_modifiers()
    # need to implement for enchanting

    var dice = DiceManager.new()
    var total_modifiers = hit_modifiers + effective_attribute_modifier + effective_proficiency_modifier + effective_item_modifiers + Helper.calculate_multiple_attack_modifier(map)
    var hit_roll = dice.roll("1d20 + " + str(total_modifiers))
    var hit_success = false
    if target:
        hit_success = hit_roll["total"] >= target.get_character_sheet().get_unit_base_armor_class()

    var outcome = ""
    outcome = "success" if hit_success else "failure"
    Bus.send_roll_to_all.emit(character.get_unit_name(), "rolls hit against", target.get_character_sheet().get_unit_name(), hit_roll, "vs " + target.get_character_sheet().get_unit_base_armor_class() + "AC", outcome)

    if hit_success:
        var damage_roll = dice.roll(damage_string)
        var total_damage = damage_roll["total"] + damage_bonus + damage_modifiers
        Bus.send_roll_to_all.emit(character.get_unit_name(), "rolls damage against", target.get_character_sheet().get_unit_name(), damage_roll, "for " + str(total_damage) + " " + GameConst.get_damage_type_as_string(damage_type) + " damage", outcome)
        Bus.apply_damage.emit(target.name, total_damage)