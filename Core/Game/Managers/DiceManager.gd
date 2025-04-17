class_name DiceManager
extends RefCounted # Use RefCounted for a utility class not tied to the scene tree

# --- Properties ---

# Use a specific RNG instance for potential seeding/control later
var _rng := RandomNumberGenerator.new()

# Regex to parse dice terms like "+ 2d6", "- 5", "d20"
# Groups:
# 1: Sign (+ or -), optional
# 2: Dice count (e.g., "2" in 2d6), optional (defaults to 1 if 'd' is present)
# 3: Dice sides (e.g., "6" in 2d6), required if 'd' is present
# 4: Constant modifier value (e.g., "5" in +5), only if 'd' is NOT present
const DICE_TERM_REGEX := "([+-])?\\s*(?:(\\d+)?d(\\d+)|(\\d+))"
var _regex := RegEx.new()


# --- Initialization ---
func _init():
	# Seed the random number generator once when the manager is created
	_rng.randomize()
	# Compile the regex for efficiency
	var error = _regex.compile(DICE_TERM_REGEX)
	if error != OK:
		printerr("DiceManager: Failed to compile regex! Error code: ", error)



# --- Public API ---

## Parses a dice string (e.g., "2d6+5", "1d20-1", "d8 + 2d4") and rolls the dice.
## Returns a Dictionary containing the results:
## {
##     "formula": String (original input),
##     "total": int (final result),
##     "terms": Array[Dictionary] (details of each term rolled/added),
##     "success": bool (true if parsing and rolling succeeded),
##     "error_message": String (null if success, error description otherwise)
## }
func roll(dice_string: String) -> Dictionary:
	var formula := dice_string.strip_edges()
	if formula.is_empty():
		return _create_error_result(dice_string, "Empty dice string provided.")

	# 1. Parse the string into terms
	var parse_result := _parse_dice_string(formula)
	if not parse_result.success:
		return _create_error_result(dice_string, parse_result.error_message)

	var parsed_terms: Array = parse_result.terms

	# 2. Execute the rolls for each term
	var executed_terms := []
	var total_value := 0
	for term_data in parsed_terms:
		var term_result := _execute_roll_term(term_data)
		if not term_result.success:
			# If a single term fails, propagate the error
			return _create_error_result(dice_string, term_result.error_message)

		executed_terms.append(term_result)
		total_value += term_result.value

	Audio.play_sfx_audio(load("res://Assets/Audio/SFX/Dice/dice-roll.mp3"))
	# 3. Format and return the final result
	return {
		"formula": dice_string,
		"total": total_value,
		"terms": executed_terms, # Contains detailed breakdown
		"success": true,
		"error_message": null
	}


# --- Private Helper Methods ---

## Parses the input string using regex into an array of term dictionaries.
func _parse_dice_string(text: String) -> Dictionary:
	var terms := []
	var current_pos := 0
	var first_term := true

	for match in _regex.search_all(text):
		# Check for invalid characters between matches
		if match.get_start() > current_pos:
			var invalid_part = text.substr(current_pos, match.get_start() - current_pos).strip_edges()
			if not invalid_part.is_empty():
				return { "success": false, "error_message": "Invalid characters found: '%s'" % invalid_part, "terms": [] }

		var sign_str := match.get_string(1)
		var count_str := match.get_string(2)
		var sides_str := match.get_string(3)
		var constant_str := match.get_string(4)

		var sign := "+"
		if sign_str and not sign_str.is_empty():
			sign = sign_str
		elif not first_term:
			# If no sign is explicitly given on subsequent terms, it's usually an error
			# or implies addition, depending on desired strictness.
			# We'll assume addition for now, but you could make this an error.
			sign = "+"
			# A more robust parser might handle implicit signs better.

		var term_data := {}

		if sides_str: # It's a dice term (NdX or dX)
			var count := 1
			if count_str and not count_str.is_empty():
				count = int(count_str)

			var sides := int(sides_str)

			if count <= 0:
				return { "success": false, "error_message": "Dice count must be positive.", "terms": [] }
			if sides <= 1: # A d1 is not practically useful and often indicates an error
				return { "success": false, "error_message": "Dice sides must be 2 or more.", "terms": [] }
			# Add limits if desired (e.g., max count, max sides)
			# if count > MAX_DICE_COUNT or sides > MAX_SIDES: ... error ...

			term_data = {
				"type": "dice",
				"sign": sign,
				"count": count,
				"sides": sides
			}
		elif constant_str: # It's a constant modifier term
			term_data = {
				"type": "modifier",
				"sign": sign,
				"value": int(constant_str)
			}
		else:
			# This case shouldn't happen with the current regex if it matches,
			# but good to handle defensively.
			return { "success": false, "error_message": "Internal parsing error: Unrecognized term structure.", "terms": [] }

		terms.append(term_data)
		current_pos = match.get_end()
		first_term = false

	# Check if the entire string was consumed by the regex matches
	if current_pos != text.length():
		var remaining_part = text.substr(current_pos).strip_edges()
		if not remaining_part.is_empty():
			return { "success": false, "error_message": "Could not parse trailing characters: '%s'" % remaining_part, "terms": [] }

	if terms.is_empty():
		return { "success": false, "error_message": "No valid dice or modifiers found.", "terms": [] }

	return { "success": true, "error_message": null, "terms": terms }


## Executes a single parsed term (rolls dice or returns modifier value).
func _execute_roll_term(term_data: Dictionary) -> Dictionary:
	var term_result := {
		"type": term_data.type,
		"description": "",   # String representation (e.g., "+2d6", "-5")
		"rolls": [],         # Array of individual die results (for "dice" type)
		"value": 0,          # The final value contributed by this term (respecting sign)
		"success": true,
		"error_message": null
	}

	var base_value := 0
	var description_base := ""
	var sign_multiplier := -1 if term_data.sign == "-" else 1

	match term_data.type:
		"dice":
			description_base = "%dd%d" % [term_data.count, term_data.sides]
			var rolls := []
			for _i in range(term_data.count):
				var roll_value := _roll_die(term_data.sides)
				rolls.append(roll_value)
				base_value += roll_value
				# --- Placeholder for future complex logic ---
				# Add keep/drop/explode logic here by modifying 'rolls'
				# and recalculating 'base_value' *before* applying the sign multiplier.
				# ---
			term_result.rolls = rolls

		"modifier":
			description_base = str(term_data.value)
			base_value = term_data.value

		_:
			# Should not happen if parsing is correct
			return { "success": false, "error_message": "Internal error: Unknown term type during execution.", "value": 0 }

	term_result.value = base_value * sign_multiplier
	term_result.description = term_data.sign + description_base

	return term_result


## Rolls a single die with the specified number of sides.
func _roll_die(sides: int) -> int:
	if sides <= 0: return 0 # Should be caught by parsing, but safety first
	# randi_range is inclusive [min, max]
	return _rng.randi_range(1, sides)


## Helper to create a standardized error result dictionary.
func _create_error_result(formula: String, message: String) -> Dictionary:
	return {
		"formula": formula,
		"total": 0,
		"terms": [],
		"success": false,
		"error_message": message
	}


# Types of dice rolls

func standard_roll(modifier: int, other_bonuses: int = 0) -> Dictionary:
	# Rolls a d20 and adds the perception modifier
	var is_negative = modifier + other_bonuses < 0
	var roll
	if is_negative:
		roll = roll("1d20 - " + str(-modifier - other_bonuses))
	else:
		roll = roll("1d20 + " + str(modifier + other_bonuses))
	return roll

func damage_roll(dice: int, sides: int, modifier: int) -> Dictionary:
	# Rolls a number of dice and adds the damage modifier
	var roll = roll(str(dice) + "d" + str(sides) + " + " + str(modifier))
	return roll
