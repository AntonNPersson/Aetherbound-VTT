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

func type_string(type_enum: int) -> String:
	match type_enum:
		TYPE_NIL: return "Nil"
		TYPE_BOOL: return "Bool"
		TYPE_INT: return "Int"
		TYPE_FLOAT: return "Float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_VECTOR4: return "Vector4"
		TYPE_VECTOR4I: return "Vector4i"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_PROJECTION: return "Projection"
		TYPE_COLOR: return "Color"
		TYPE_STRING_NAME: return "StringName"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		TYPE_CALLABLE: return "Callable"
		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
		_: return "Unknown (" + str(type_enum) + ")"