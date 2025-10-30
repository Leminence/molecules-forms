extends Node

@onready var molecule = $Molecule

@export var central_atom_color: Color = Color.BLUE
@export var atom_color: Color = Color.CYAN
@export var bond_color: Color = Color.WHITE

var central_atom: MeshInstance3D
var atoms: Array = []
var rotation_speed: float = 0.01
var clamp_x_deg: Vector2 = Vector2(-80, 80) # limite para evitar virar de cabeça pra baixo
var rotating: bool = false

func _ready():
	central_atom = create_atom(central_atom_color)
	molecule.add_child(central_atom)

	# Pares de elétrons livres (duas esferas azuis)
	# var e1 = create_electron_pair(Vector3(0, -0.5, 0.3))
	# var e2 = create_electron_pair(Vector3(0, -0.5, -0.3))
	# add_child(e1)
	# add_child(e2)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed
			print("Rotating: ", rotating)

	elif event is InputEventMouseMotion and rotating:
		# Use event.relative diretamente (deslocamento do mouse desde o último frame)
		var rel: Vector2 = event.relative
		# Girar em Y (horizontal) e X (vertical)
		molecule.rotate_y(rel.x * rotation_speed)
		molecule.rotate_x(rel.y * rotation_speed)
		# Limita a rotação no eixo X para não ficar de cabeça pra baixo
		molecule.rotation_degrees.x = clamp(molecule.rotation_degrees.x, clamp_x_deg.x, clamp_x_deg.y)


func create_atom(color: Color) -> MeshInstance3D:
	# Cria uma esfera para representar o átomo
	var atom = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	# Ajusta os valores do átomo
	sphere.radius = 0.25
	sphere.height = 0.5

	var atom_material = StandardMaterial3D.new()
	atom_material.albedo_color = color
	atom.material_override = atom_material

	atom.mesh = sphere
	atom.position = molecule.position
	atom.name = "Atom"
	return atom


func create_bond(atom: MeshInstance3D, new_atom: MeshInstance3D) -> void:
	# Cria um cilindro para representar a ligação
	var bond = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = atom.global_position.distance_to(new_atom.global_position)
	cylinder.bottom_radius = 0.08
	cylinder.top_radius = 0.08
	bond.mesh = cylinder

	# Define o material da ligação
	var bond_material = StandardMaterial3D.new()
	bond_material.albedo_color = bond_color
	bond.material_override = bond_material
	bond_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bond_material.albedo_color.a = 0.8

	# Adiciona o cilindro como filho do átomo original para herdar a transformação
	new_atom.add_child(bond)

	# Posiciona no ponto médio entre os átomos
	bond.global_position = (atom.global_position + new_atom.global_position) / 2.0
	
	# Calcula a direção da ligação
	var direction = (new_atom.global_position - atom.global_position).normalized()
	
	# O cilindro por padrão aponta para cima (Y), então alinha com a direção
	if bond.global_position == new_atom.global_position:
		push_error("Posição da ligação é igual à do novo átomo, não é possível fazer look_at.")
		return

	bond.look_at(bond.global_position + direction, Vector3.UP)
	bond.rotate_object_local(Vector3.RIGHT, PI / 2.0)


func set_atoms_position(Atoms: Array) -> void:
	var x: float = 0.0
	var y: float = 0.0
	var z: float = 0.0
	for i in range(Atoms.size()):
		if Atoms.size() >= 0:
			var angle = i * (PI * 2 / Atoms.size())
			x = cos(angle)
			y = 0.0
			z = sin(angle)

		Atoms[i].position = Vector3(x, y, z)

		if central_atom.position == Atoms[i].position:
			push_error("Posição do átomo é igual à do átomo central, não é possível fazer look_at.")
			continue

		Atoms[i].look_at(central_atom.position, Vector3.UP)

# Cria um novo átomo e sua ligação ao átomo central ao clicar no botão
func _on_simple_button_pressed() -> void:
	if atoms.size() >= 6:
		return # Limita a 6 átomos ligados ao central

	var new_atom = create_atom(atom_color)
	molecule.add_child(new_atom)
	atoms.append(new_atom)
	set_atoms_position(atoms)
	create_bond(central_atom, new_atom)
