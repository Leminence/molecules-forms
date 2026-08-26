extends Node3D

## Grade de referência nos planos XY, XZ e YZ.
## Segue a câmera em snap de cell_size — parece infinita sem rebuildar.
## Inclui vetores dos eixos X, Y, Z que se estendem até a câmera.

# ─── Câmera ────────────────────────────────────────────────
@export var camera: Camera3D

# ─── Tamanho ───────────────────────────────────────────────
@export var grid_size: int = 67:
	set(v):
		grid_size = v
		if is_inside_tree(): _rebuild()

@export var cell_size: float = 1.0:
	set(v):
		cell_size = v
		if is_inside_tree(): _rebuild()

# ─── Planos visíveis ───────────────────────────────────────
@export var show_xz: bool = true:
	set(v):
		show_xz = v
		if is_inside_tree(): _rebuild()

@export var show_xy: bool = false:
	set(v):
		show_xy = v
		if is_inside_tree(): _rebuild()

@export var show_yz: bool = false:
	set(v):
		show_yz = v
		if is_inside_tree(): _rebuild()

# ─── Eixos ─────────────────────────────────────────────────
@export var show_axes: bool = true:
	set(v):
		show_axes = v
		if is_inside_tree(): _rebuild()

@export var axis_length_multiplier: float = 1.5  # multiplica a dist da câmera

# ─── Aparência ─────────────────────────────────────────────
@export var line_color: Color = Color(0.5, 0.5, 0.5, 0.35):
	set(v):
		line_color = v
		if is_inside_tree(): _rebuild()

@export var axis_color_x: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var axis_color_y: Color = Color(0.2, 0.85, 0.2, 1.0)
@export var axis_color_z: Color = Color(0.2, 0.5, 1.0, 1.0)

@export var line_width: float = 0.008
@export var axis_width: float = 0.025

# ─── Internos ──────────────────────────────────────────────
var _grid_root: Node3D       # grade — move em snap
var _axis_root: Node3D       # eixos — sempre na origem

# Meshes dos eixos para atualizar o tamanho no _process
var _axis_x_pos: MeshInstance3D
var _axis_x_neg: MeshInstance3D
var _axis_y_pos: MeshInstance3D
var _axis_y_neg: MeshInstance3D
var _axis_z_pos: MeshInstance3D
var _axis_z_neg: MeshInstance3D

var _last_snap: Vector3 = Vector3.INF


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_last_snap = Vector3.INF

	# ── Grade ──
	_grid_root = Node3D.new()
	_grid_root.name = "GridRoot"
	add_child(_grid_root)

	var half := grid_size * cell_size
	var mat_line := _make_mat(line_color)

	if show_xz:
		_build_plane_xz(_grid_root, half, mat_line)
	if show_xy:
		_build_plane_xy(_grid_root, half, mat_line)
	if show_yz:
		_build_plane_yz(_grid_root, half, mat_line)

	# ── Eixos ──
	if show_axes:
		_axis_root = Node3D.new()
		_axis_root.name = "AxisRoot"
		add_child(_axis_root)
		_build_axis_vectors()


# ─── Grade ────────────────────────────────────────────────

func _build_plane_xz(root: Node3D, half: float, mat: StandardMaterial3D) -> void:
	var steps := grid_size * 2
	for i in range(-steps, steps + 1):
		var t := i * cell_size
		# Paralela a X
		_add_line(root, Vector3(-half, 0, t), Vector3(half, 0, t), mat, line_width)
		# Paralela a Z
		_add_line(root, Vector3(t, 0, -half), Vector3(t, 0, half), mat, line_width)


func _build_plane_xy(root: Node3D, half: float, mat: StandardMaterial3D) -> void:
	var steps := grid_size * 2
	for i in range(-steps, steps + 1):
		var t := i * cell_size
		_add_line(root, Vector3(-half, t, 0), Vector3(half, t, 0), mat, line_width)
		_add_line(root, Vector3(t, -half, 0), Vector3(t, half, 0), mat, line_width)


func _build_plane_yz(root: Node3D, half: float, mat: StandardMaterial3D) -> void:
	var steps := grid_size * 2
	for i in range(-steps, steps + 1):
		var t := i * cell_size
		_add_line(root, Vector3(0, -half, t), Vector3(0, half, t), mat, line_width)
		_add_line(root, Vector3(0, t, -half), Vector3(0, t, half), mat, line_width)


# ─── Vetores dos eixos ────────────────────────────────────

func _build_axis_vectors() -> void:
	# Cria os 6 braços (+ e - de cada eixo) com comprimento 1 — será escalado no _process
	_axis_x_pos = _make_axis_mesh(axis_color_x, axis_width)
	_axis_x_neg = _make_axis_mesh(Color(axis_color_x, 0.3), axis_width * 0.6)
	_axis_y_pos = _make_axis_mesh(axis_color_y, axis_width)
	_axis_y_neg = _make_axis_mesh(Color(axis_color_y, 0.3), axis_width * 0.6)
	_axis_z_pos = _make_axis_mesh(axis_color_z, axis_width)
	_axis_z_neg = _make_axis_mesh(Color(axis_color_z, 0.3), axis_width * 0.6)

	for mesh in [_axis_x_pos, _axis_x_neg, _axis_y_pos, _axis_y_neg, _axis_z_pos, _axis_z_neg]:
		_axis_root.add_child(mesh)


func _make_axis_mesh(color: Color, width: float) -> MeshInstance3D:
	var mat := _make_mat(color)

	var cyl := CylinderMesh.new()
	cyl.height = 1.0          # comprimento base — escala no _process
	cyl.top_radius = width
	cyl.bottom_radius = width
	cyl.radial_segments = 6

	var mesh := MeshInstance3D.new()
	mesh.mesh = cyl
	mesh.material_override = mat
	return mesh


func _update_axis_arm(mesh: MeshInstance3D, direction: Vector3, length: float) -> void:
	# Reescala e reposiciona sem recriar o mesh
	var cyl := mesh.mesh as CylinderMesh
	cyl.height = length
	mesh.position = direction * (length / 2.0)
	var up_ref := Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	mesh.look_at(mesh.position + direction, up_ref)
	mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0)


# ─── Process — snap da grade + tamanho dos eixos ──────────

func _process(_delta: float) -> void:
	if camera == null:
		return

	var cam_pos := camera.global_position
	var cam_dist := cam_pos.length()

	# ── Snap da grade ──
	# Move a grade em múltiplos de cell_size para parecer infinita
	var snap := Vector3(
		snappedf(cam_pos.x, cell_size),
		snappedf(cam_pos.y, cell_size),
		snappedf(cam_pos.z, cell_size)
	)

	# Aplica snap apenas nos eixos relevantes de cada plano
	var grid_pos := Vector3.ZERO
	if show_xz:
		grid_pos.x = snap.x
		grid_pos.z = snap.z
	if show_xy:
		grid_pos.x = snap.x
		grid_pos.y = snap.y
	if show_yz:
		grid_pos.y = snap.y
		grid_pos.z = snap.z

	if grid_pos != _last_snap:
		_grid_root.position = grid_pos
		_last_snap = grid_pos

	# ── Tamanho dos eixos ──
	if show_axes and _axis_root:
		var length := maxf(cam_dist * axis_length_multiplier, 5.0)
		_update_axis_arm(_axis_x_pos,  Vector3.RIGHT,   length)
		_update_axis_arm(_axis_x_neg, -Vector3.RIGHT,   length)
		_update_axis_arm(_axis_y_pos,  Vector3.UP,      length)
		_update_axis_arm(_axis_y_neg, -Vector3.UP,      length)
		_update_axis_arm(_axis_z_pos,  Vector3.BACK,    length)
		_update_axis_arm(_axis_z_neg, -Vector3.BACK,    length)

	reset_physics_interpolation()


# ─── Helpers ──────────────────────────────────────────────

func _add_line(container: Node3D, from: Vector3, to: Vector3,
			   mat: StandardMaterial3D, width: float) -> void:
	var dir  := (to - from).normalized()
	var dist := from.distance_to(to)
	var mid  := (from + to) / 2.0

	var cyl := CylinderMesh.new()
	cyl.height        = dist
	cyl.top_radius    = width
	cyl.bottom_radius = width
	cyl.radial_segments = 4

	var mesh := MeshInstance3D.new()
	mesh.mesh = cyl
	mesh.material_override = mat
	container.add_child(mesh)

	mesh.position = mid
	var up_ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	mesh.look_at(mid + dir, up_ref)
	mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0)


func _make_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat