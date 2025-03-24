extends Sprite2D

func _ready():
	scale_to_window()
	get_tree().root.size_changed.connect(scale_to_window)

func scale_to_window():
	var window_size = get_viewport_rect().size
	var texture_size = texture.get_size()
	
	# Calculate scale ratio
	var scale_x = window_size.x / texture_size.x
	var scale_y = window_size.y / texture_size.y
	
	# Apply scale
	scale = Vector2(scale_x, scale_y)
	
	# Center the sprite in the window