extends Control

func _initialize(variables: Dictionary) -> void:
    var main_container = find_child("ResourceContainer")
    if main_container == null:
        printerr("ResourceContainer not found")
        return

    for key in variables.keys():
        # 1. Create a container for THIS key-value pair
        var pair_container = VBoxContainer.new()
        # Make this inner container fill the width provided by the main container
        pair_container.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND

        # --- Create Key Label ---
        var key_label = Label.new()
        # Optional: Add a colon or styling to the key
        key_label.text = str(key).capitalize() + ":"
        # Center the text horizontally WITHIN the label's bounds
        key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        # Enable autowrap in case the key itself is very long
        key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        # Make the label expand horizontally to allow centering within the full width
        key_label.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
        # Add the key label to the inner container
        pair_container.add_child(key_label)

        # --- Create Value Label ---
        var value_label = Label.new()
        value_label.text = str(variables[key])
        # Center the text horizontally
        value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        # Enable autowrap in case the value is very long
        value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        # Make the label expand horizontally
        value_label.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
        # Add the value label to the inner container
        pair_container.add_child(value_label)

        # 2. Add the container for this pair to the main container
        main_container.add_child(pair_container)