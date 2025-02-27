# ERROR UTILITY #
extends Node

# ===================== ERROR UTILITY FUNCTIONS =====================

# Log error, warning, info and debug messages with optional stack trace #
func log_error(message: String, stack: bool = false) -> void:
	print("Error: " + message)
	push_error(message)
	if stack: print_stack()

func log_warning(message: String, stack: bool = false) -> void:
	print("Warning: " + message)
	push_warning(message)
	if stack: print_stack()

func log_info(message: String, stack: bool = false) -> void:
	print("Info: " + message)
	if stack: print_stack()

func log_debug(message: String, stack: bool = false) -> void:
	print_debug("Debug: " + message)
	if stack: print_stack()