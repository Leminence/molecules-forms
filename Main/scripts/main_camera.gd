extends Camera3D

@export var zoom_speed: float = 0.4
@export var zoom_min: float = 5.0
@export var zoom_max: float = 100.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom(-zoom_speed)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom(zoom_speed)

func _zoom(delta: float) -> void:
    position.z = clamp(position.z + delta, zoom_min, zoom_max)