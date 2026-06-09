extends Node3D

var rotation_speed: float = 0.01
var rotating: bool = false
var auto_rotating: bool = true

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating = event.pressed

	elif event is InputEventMouseMotion and rotating:
		var rel: Vector2 = event.relative
		# Girar em Y (horizontal) e X (vertical)
		rotate_y(rel.x * rotation_speed)
		rotate_x(rel.y * rotation_speed)