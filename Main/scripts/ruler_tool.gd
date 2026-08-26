extends Node

## Ferramenta de régua/medição de distância entre átomos.
##
## Fluxo:
## 1º clique num átomo  → seleciona (destaca) o átomo A
## 2º clique noutro átomo → desenha uma reta entre A e B com o valor
##                           da distância flutuando no meio
## clique seguinte (em qualquer lugar) → limpa a medição atual e reinicia

signal measurement_made(atom_a: MeshInstance3D, atom_b: MeshInstance3D, distance: float)
signal measurement_cleared

@export var active: bool = false

var _molecule: Node3D
var _camera: Camera3D
var _main_viewport: SubViewportContainer

var _atom_a: MeshInstance3D = null
var _atom_b: MeshInstance3D = null

var _highlight_sphere_a: MeshInstance3D = null
var _highlight_sphere_b: MeshInstance3D = null
var _ruler_line: MeshInstance3D = null
var _ruler_label: Label3D = null

const COLOR_HIGHLIGHT := Color(1.0, 0.85, 0.1, 0.35)
const COLOR_RULER := Color(1.0, 0.65, 0.0)
const LINE_RADIUS := 0.025
const HIGHLIGHT_SCALE := 1.1  # múltiplo do raio do átomo

const ANGSTROM_SYMBOL := "\u00C5"  # símbolo de angstrom (Å)

func setup(molecule: Node3D, camera: Camera3D, main_viewport: SubViewportContainer) -> void:
	_molecule = molecule
	_camera = camera
	_main_viewport = main_viewport


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_click(event.position)


func _on_click(screen_pos: Vector2) -> void:
	# Se já existe uma medição completa, qualquer clique novo limpa e reinicia
	if _atom_a != null and _atom_b != null:
		_clear_measurement()
		return

	var atom = _pick_atom(screen_pos)
	if atom == null:
		return

	if _atom_a == null:
		_atom_a = atom
		_highlight_sphere_a = _highlight_atom(atom)
		return

	if atom == _atom_a:
		return  # clicou de novo no mesmo átomo — ignora

	_atom_b = atom
	_highlight_sphere_b = _highlight_atom(atom)
	_draw_ruler()


# ─── Desenho da régua ──────────────────────────────────────

func _draw_ruler() -> void:
	var pos_a := _atom_a.global_position
	var pos_b := _atom_b.global_position
	var dist := pos_a.distance_to(pos_b)
	var mid := (pos_a + pos_b) / 2.0
	var dir := (pos_b - pos_a).normalized()

	# Linha — unshaded + no_depth_test para sempre aparecer por cima de outros materiais
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_RULER
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.render_priority = 10

	var cyl := CylinderMesh.new()
	cyl.height = dist
	cyl.top_radius = LINE_RADIUS
	cyl.bottom_radius = LINE_RADIUS
	cyl.radial_segments = 8

	_ruler_line = MeshInstance3D.new()
	_ruler_line.mesh = cyl
	_ruler_line.material_override = mat
	_ruler_line.sorting_offset = 1.0  # ajuda no sorting entre transparentes
	_molecule.add_child(_ruler_line)

	_ruler_line.global_position = mid
	var up_ref := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	_ruler_line.look_at(mid + dir, up_ref)
	_ruler_line.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Label com a distância, um pouco acima do meio da reta
	_ruler_label = Label3D.new()
	_ruler_label.text = "%.2f" % dist + " " + ANGSTROM_SYMBOL
	_ruler_label.font_size = 48
	_ruler_label.modulate = COLOR_RULER
	_ruler_label.outline_size = 8
	_ruler_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_ruler_label.no_depth_test = true
	_ruler_label.render_priority = 12  # acima da linha (10)
	_molecule.add_child(_ruler_label)
	_ruler_label.global_position = mid + Vector3.UP * 0.5

	measurement_made.emit(_atom_a, _atom_b, dist)


func _clear_measurement() -> void:
	if _ruler_line:
		_ruler_line.queue_free()
		_ruler_line = null
	if _ruler_label:
		_ruler_label.queue_free()
		_ruler_label = null

	_restore_highlight()
	_atom_a = null
	_atom_b = null
	measurement_cleared.emit()


# ─── Destaque do átomo selecionado ─────────────────────────
# Em vez de trocar o material do átomo, cria uma esfera maior
# e transparente como filha dele, sem afetar sua aparência original.

func _highlight_atom(atom: MeshInstance3D) -> MeshInstance3D:
	var atom_radius := _get_atom_radius(atom)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_HIGHLIGHT
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var sphere := SphereMesh.new()
	sphere.radius = atom_radius * HIGHLIGHT_SCALE
	sphere.height = sphere.radius * 2.0

	var highlight := MeshInstance3D.new()
	highlight.mesh = sphere
	highlight.material_override = mat
	highlight.name = "RulerHighlight"

	atom.add_child(highlight)
	highlight.position = Vector3.ZERO
	return highlight


func _restore_highlight() -> void:
	if _highlight_sphere_a and is_instance_valid(_highlight_sphere_a):
		_highlight_sphere_a.queue_free()
	if _highlight_sphere_b and is_instance_valid(_highlight_sphere_b):
		_highlight_sphere_b.queue_free()
	_highlight_sphere_a = null
	_highlight_sphere_b = null


func _get_atom_radius(atom: MeshInstance3D) -> float:
	# O átomo (classe Atom) tem seu próprio mesh esférico — pega o raio dele
	if atom.mesh is SphereMesh:
		return (atom.mesh as SphereMesh).radius
	return 0.3  # fallback caso a estrutura do Atom seja diferente


# ─── Picking / Raycasting (mesmo padrão do PlacerTool) ────

func _pick_atom(screen_pos: Vector2) -> MeshInstance3D:
	var result = _raycast(screen_pos)
	if result.is_empty():
		return null
	var col = result["collider"]
	if col.has_meta("owner_atom"):
		return col.get_meta("owner_atom")
	return null


func _raycast(screen_pos: Vector2) -> Dictionary:
	var space := _molecule.get_world_3d().direct_space_state
	var local_pos := screen_pos - _main_viewport.global_position

	var origin := _camera.project_ray_origin(local_pos)
	var end    := origin + _camera.project_ray_normal(local_pos) * 100.0
	var query  := PhysicsRayQueryParameters3D.create(origin, end)
	return space.intersect_ray(query)


# ─── API pública ───────────────────────────────────────────

func set_active(value: bool) -> void:
	active = value
	if not active:
		_clear_measurement()