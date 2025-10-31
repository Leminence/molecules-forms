extends Node3D

var rotation_speed: float = 0.01
var clamp_x_deg: Vector2 = Vector2(-80, 80) # limite para evitar virar de cabeça pra baixo
var rotating: bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed

	elif event is InputEventMouseMotion and rotating:
		var rel: Vector2 = event.relative
		# Girar em Y (horizontal) e X (vertical)
		rotate_y(rel.x * rotation_speed)
		rotate_x(rel.y * rotation_speed)
		# Limita a rotação no eixo X para não ficar de cabeça pra baixo
		rotation_degrees.x = clamp(rotation_degrees.x, clamp_x_deg.x, clamp_x_deg.y)


func _physics_process(delta: float) -> void:
	if not rotating:
		rotate_y(rotation_speed * delta * 15)