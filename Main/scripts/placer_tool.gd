extends Node

## Interação unificada:
## - Click: coloca átomo
## - Click + drag: coloca átomo na origem, outro no destino, liga com ligação simples
## - Click numa ligação: cicla simples → dupla → tripla

signal atom_added(atom: MeshInstance3D)
signal atom_removed(atom: MeshInstance3D)

@export var drag_threshold: float = 10.0  # pixels mínimos para considerar drag

var _molecule: Node3D
var _camera: Camera3D
var _main_viewport: SubViewportContainer
var _atom_id: int = 0

var _press_pos: Vector2
var _is_dragging: bool = false
var _drag_origin_atom: MeshInstance3D = null
var _preview_line: MeshInstance3D = null  # linha fantasma durante o drag

const COLOR_BOND := Color(0.85, 0.85, 0.85)
const COLOR_PREVIEW := Color(1.0, 1.0, 1.0, 0.3)

const PLACEMENT_PLANE := Plane(Vector3.UP, 0.0)
const PLACEMENT_DISTANCE := 5.0  # distância à frente da câmera

func setup(molecule: Node3D, camera: Camera3D, main_viewport: SubViewportContainer) -> void:
	_molecule = molecule
	_camera = camera
	_main_viewport = main_viewport


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)

	elif event is InputEventMouseMotion and _drag_origin_atom != null:
		_on_drag(event.position)

# Press
func _on_press(screen_pos: Vector2) -> void:
	_press_pos = screen_pos
	_is_dragging = false

	var bond = _pick_bond(screen_pos)
	if bond:
		_cycle_bond(bond)
		return

	# Verifica se clicou num átomo existente para iniciar drag de ligação
	var atom = _pick_atom(screen_pos)
	if atom:
		_drag_origin_atom = atom
		return

	# Clicou em espaço vazio — cria átomo na posição
	var world_pos = _raycast_plane(screen_pos)
	if world_pos != null:
		_drag_origin_atom = _place_atom(world_pos)

# Drag
func _on_drag(screen_pos: Vector2) -> void:
	if not _is_dragging:
		if screen_pos.distance_to(_press_pos) < drag_threshold:
			return
		_is_dragging = true

	var world_pos = _raycast_plane(screen_pos, _drag_origin_atom.global_position)
	if world_pos == null:
		return

	_update_preview(_drag_origin_atom.global_position, world_pos)

# Release
func _on_release(screen_pos: Vector2) -> void:
	_clear_preview()

	if _drag_origin_atom == null:
		return

	if _is_dragging:
		# Verifica se soltou em cima de um átomo existente
		var target = _pick_atom(screen_pos)

		if target == null or target == _drag_origin_atom:
			var world_pos = _raycast_plane(screen_pos, _drag_origin_atom.global_position)
			if world_pos != null:
				target = _place_atom(world_pos)

		if target and target != _drag_origin_atom:
			_create_bond(_drag_origin_atom, target, 1)

	_drag_origin_atom = null
	_is_dragging = false

# Preview de ligação
func _update_preview(from: Vector3, to: Vector3) -> void:
	if _preview_line == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOR_PREVIEW
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		_preview_line = MeshInstance3D.new()
		_preview_line.material_override = mat
		_molecule.add_child(_preview_line)

	var dist := from.distance_to(to)
	if dist < 0.01:
		return

	var cyl := CylinderMesh.new()
	cyl.height = dist
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.03
	cyl.radial_segments = 8
	_preview_line.mesh = cyl

	var mid := (from + to) / 2.0
	_preview_line.global_position = mid
	var dir := (to - from).normalized()
	var up_ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	_preview_line.look_at(mid + dir, up_ref)
	_preview_line.rotate_object_local(Vector3.RIGHT, PI / 2.0)


func _clear_preview() -> void:
	if _preview_line:
		_preview_line.queue_free()
		_preview_line = null

# Átomo
func _place_atom(world_pos: Vector3) -> MeshInstance3D:
	var element: Element = ChemistryData.element_selected

	_atom_id += 1

	var atom : Atom = Atom.new(element)
	atom.position = _molecule.to_local(world_pos)
	atom.name = "%s [%s]" % [element.symbol, _atom_id]
	atom.set_meta("is_atom", true)

	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = element.atom_radius * 1.3
	col.shape = shape
	body.add_child(col)
	body.set_meta("owner_atom", atom)
	atom.add_child(body)

	atom.set_meta("bonds", [])
	_molecule.add_child(atom)
	atom_added.emit(atom)
	return atom

# Ligação
func _create_bond(atom_a: MeshInstance3D, atom_b: MeshInstance3D, amount: int) -> void:
	var pos_a := atom_a.global_position
	var pos_b := atom_b.global_position
	var dist  := pos_a.distance_to(pos_b)
	var dir   := (pos_b - pos_a).normalized()
	var mid   := (pos_a + pos_b) / 2.0
	var _perp  := _get_perpendicular(dir)

	var radius := _bond_radius(amount)
	var _offset_dist := radius * 2.2

	var bond_root := Node3D.new()
	bond_root.name = "Bond_%s_%s" % [atom_a.name, atom_b.name]
	bond_root.set_meta("is_bond", true)
	bond_root.set_meta("bond_type", amount)
	bond_root.set_meta("atom_a", atom_a)
	bond_root.set_meta("atom_b", atom_b)
	_molecule.add_child(bond_root)

	_fill_bond_meshes(bond_root, atom_a, atom_b, amount)

	# Collider no bond_root para picking
	var body := StaticBody3D.new()
	var col  := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.15
	shape.height = dist
	col.shape = shape
	body.set_meta("owner_bond", bond_root)
	bond_root.add_child(body)
	col.shape = shape
	body.add_child(col)
	body.global_position = mid
	var up_ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	body.look_at(mid + dir, up_ref)
	body.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Registra a ligação nos dois átomos para facilitar remoção
	atom_a.get_meta("bonds").append(bond_root)
	atom_b.get_meta("bonds").append(bond_root)


func _fill_bond_meshes(bond_root: Node3D, atom_a: MeshInstance3D, atom_b: MeshInstance3D, amount: int) -> void:
	for child in bond_root.get_children():
		if child is MeshInstance3D:
			child.queue_free()

	var pos_a: Vector3 = atom_a.global_position
	var pos_b: Vector3 = atom_b.global_position
	var color_a: Color = atom_a.material_override.albedo_color
	var color_b: Color= atom_b.material_override.albedo_color

	# Gradiente sem transição — corte exato no meio
	var gradient: Gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.set_color(0, color_a)
	gradient.add_point(0.5, color_b)

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 1
	tex.height = 4
	tex.fill_from = Vector2.ZERO
	tex.fill_to = Vector2(0, 0.5)

	var dir  := (pos_b - pos_a).normalized()
	var mid  := (pos_a + pos_b) / 2.0
	var dist := pos_a.distance_to(pos_b)
	var perp := _get_perpendicular(dir)
	var radius := _bond_radius(amount)
	var offset_dist := radius * 2.2
	var up_ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT

	for i in range(amount):
		var offset := Vector3.ZERO
		if amount == 2:
			offset = perp * offset_dist * (i - 0.5)
		elif amount == 3:
			offset = perp * offset_dist * (i - 1.0)

		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.roughness = 0.5
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

		var cyl := CylinderMesh.new()
		cyl.height = dist
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.radial_segments = 10

		var mesh := MeshInstance3D.new()
		mesh.mesh = cyl
		mesh.material_override = mat
		bond_root.add_child(mesh)
		mesh.global_position = mid + offset
		mesh.look_at(mesh.global_position + dir, up_ref)
		mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0)


func _cycle_bond(bond_root: Node3D) -> void:
	var current: int = bond_root.get_meta("bond_type")
	var next := (current % 3) + 1  # 1→2→3→1
	bond_root.set_meta("bond_type", next)

	var atom_a: MeshInstance3D = bond_root.get_meta("atom_a")
	var atom_b: MeshInstance3D = bond_root.get_meta("atom_b")
	_fill_bond_meshes(bond_root, atom_a, atom_b, next)

# Picking
func _pick_atom(screen_pos: Vector2) -> MeshInstance3D:
	var result = _raycast(screen_pos)
	if result.is_empty():
		return null
	var col = result["collider"]
	if col.has_meta("owner_atom"):
		return col.get_meta("owner_atom")
	return null


func _pick_bond(screen_pos: Vector2) -> Node3D:
	var result = _raycast(screen_pos)
	if result.is_empty():
		return null
	var col = result["collider"]
	if col.has_meta("owner_bond"):
		return col.get_meta("owner_bond")
	return null

# Raycasting
func _raycast(screen_pos: Vector2) -> Dictionary:
	var space := _molecule.get_world_3d().direct_space_state
	var local_pos := screen_pos - _main_viewport.global_position
	
	var origin := _camera.project_ray_origin(local_pos)
	var end    := origin + _camera.project_ray_normal(local_pos) * 100.0
	var query  := PhysicsRayQueryParameters3D.create(origin, end)
	return space.intersect_ray(query)


func _raycast_plane(screen_pos: Vector2, reference_pos: Vector3 = Vector3.INF) -> Variant:
	var local_pos := screen_pos - _main_viewport.global_position

	var dist: float
	if reference_pos != Vector3.INF:
		dist = _camera.global_position.distance_to(reference_pos)
	else:
		dist = PLACEMENT_DISTANCE

	var plane_center := _camera.global_position + (-_camera.global_basis.z * dist)
	var plane_normal := -_camera.global_basis.z
	var plane := Plane(plane_normal, plane_center.dot(plane_normal))

	var origin := _camera.project_ray_origin(local_pos)
	var dir    := _camera.project_ray_normal(local_pos)
	return plane.intersects_ray(origin, dir)

# Helpers
func _bond_radius(amount: int) -> float:
	match amount:
		1: return 0.1
		2: return 0.07
		3: return 0.05
	return 0.08


func _get_perpendicular(dir: Vector3) -> Vector3:
	var ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	return dir.cross(ref).normalized()

# API pública
func delete_atom(atom: MeshInstance3D) -> void:
	if not is_instance_valid(atom):
		return

	# Remove todas as ligações conectadas a este átomo
	for bond in atom.get_meta("bonds"):
		if is_instance_valid(bond):
			# Remove referência deste bond no outro átomo
			var other: MeshInstance3D
			if bond.get_meta("atom_a") == atom:
				other = bond.get_meta("atom_b")
			else:
				other = bond.get_meta("atom_a")

			if is_instance_valid(other):
				var other_bonds: Array = other.get_meta("bonds")
				other_bonds.erase(bond)

			bond.queue_free()

	atom_removed.emit(atom)
	atom.queue_free()
