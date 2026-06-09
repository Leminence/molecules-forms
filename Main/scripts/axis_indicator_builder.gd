extends Node3D

@export var target_molecule: Node3D

const AXIS_DATA := [
	# [direção, cor, label, posição do label]
	[Vector3(1, 0, 0),  Color(0.9, 0.2, 0.2), "X",  Vector3(0.75, 0, 0)],
	[Vector3(0, 1, 0),  Color(0.2, 0.85, 0.2), "Y", Vector3(0, 0.75, 0)],
	[Vector3(0, 0, 1),  Color(0.2, 0.5, 1.0),  "Z",  Vector3(0, 0, 0.75)],
]

const ARM_LENGTH := 0.5
const EDGE_RADIUS := 0.04
const TIP_HEIGHT := 0.18
const TIP_RADIUS := 0.1

const COLOR_X := Color(0.9, 0.2, 0.2)
const COLOR_Y := Color(0.2, 0.85, 0.2)
const COLOR_Z := Color(0.2, 0.5, 1.0)

func _ready() -> void:
	_build_axes()

func _build_axes() -> void:
	var origin := Vector3.ZERO

	_build_arm(origin, Vector3.RIGHT, COLOR_X, "X")
	_build_arm(origin, Vector3.UP, COLOR_Y, "Y")
	_build_arm(origin, Vector3.BACK, COLOR_Z, "Z")


func _build_arm(origin: Vector3, dir: Vector3, col: Color, label: String) -> void:
	var tip_pos := origin + dir * ARM_LENGTH

	# Haste
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.0

	var cyl := CylinderMesh.new()
	cyl.top_radius    = EDGE_RADIUS
	cyl.bottom_radius = EDGE_RADIUS
	cyl.height        = ARM_LENGTH
	cyl.radial_segments = 8

	var shaft := MeshInstance3D.new()
	shaft.mesh = cyl
	shaft.material_override = mat
	shaft.layers = 2
	add_child(shaft)

	shaft.position = origin + dir * (ARM_LENGTH / 2.0)
	var up_ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	shaft.look_at(shaft.position + dir, up_ref)
	shaft.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Cone
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = col
	tip_mat.roughness = 0.0

	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius    = 0.0
	tip_mesh.bottom_radius = TIP_RADIUS
	tip_mesh.height        = TIP_HEIGHT
	tip_mesh.radial_segments = 8

	var tip := MeshInstance3D.new()
	tip.mesh = tip_mesh
	tip.material_override = tip_mat
	tip.layers = 2
	add_child(tip)

	tip.position = tip_pos + dir * (TIP_HEIGHT / 2.0)
	tip.look_at(tip.position + dir, up_ref)
	tip.rotate_object_local(Vector3.LEFT, PI / 2.0)

	# Label
	var label3d := Label3D.new()
	label3d.text = label
	label3d.font_size = 64
	label3d.modulate = col
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.no_depth_test = true
	label3d.position = tip_pos + dir * (TIP_HEIGHT + 0.1)
	label3d.layers = 2
	add_child(label3d)


func _process(_delta: float) -> void:
	if target_molecule:
		transform.basis = target_molecule.transform.basis
