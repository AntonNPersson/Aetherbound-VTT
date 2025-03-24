extends CanvasLayer

func _ready() -> void:
    var screen_scale = DisplayServer.screen_get_scale()

    if screen_scale > 1.0:
        get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        get_tree().root.content_scale_factor = screen_scale

