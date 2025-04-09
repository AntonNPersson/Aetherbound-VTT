# ERROR UTILITY #
extends Node

# ===================== ERROR UTILITY FUNCTIONS =====================

# Log error, warning, info and debug messages with optional stack trace #
func log_error(message: String, stack: bool = false) -> void:
	push_error(message)
	if stack: print_stack()

func log_warning(message: String, stack: bool = false) -> void:
	push_warning(message)
	if stack: print_stack()

func log_info(message: Variant, stack: bool = false) -> void:
	print("Info: " + message)
	if stack: print_stack()

func log_debug(message: String, stack: bool = false) -> void:
	print_debug("Debug: " + message)
	if stack: print_stack()

func print_error(message: String) -> void:
	Bus.send_error_message.emit(message)