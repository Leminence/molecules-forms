extends Node

@onready var molecule = $Molecule

@export var central_atom_color: Color = Color.BLUE
@export var atom_color: Color = Color.CYAN
@export var bond_color: Color = Color.WHITE

var central_atom: MeshInstance3D
var atoms: Array = []

var central_atom_material: StandardMaterial3D
var atom_material: StandardMaterial3D
var bond_material: StandardMaterial3D

func _ready():
	set_materials()
	central_atom = create_atom(central_atom_material)
	molecule.add_child(central_atom)


func set_materials():
	central_atom_material = StandardMaterial3D.new()
	central_atom_material.albedo_color = central_atom_color

	atom_material = StandardMaterial3D.new()
	atom_material.albedo_color = atom_color

	bond_material = StandardMaterial3D.new()
	bond_material.albedo_color = bond_color
	bond_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bond_material.albedo_color.a = 1


func create_atom(material: StandardMaterial3D) -> MeshInstance3D:
	# Cria uma esfera para representar o átomo
	var atom = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	# Ajusta os valores do átomo
	sphere.radius = 0.25
	sphere.height = 0.5

	atom.material_override = material

	atom.mesh = sphere
	atom.position = molecule.position
	atom.name = "Atom"
	return atom


func create_bond(atom: MeshInstance3D, new_atom: MeshInstance3D, amount: int) -> void:
	var distance = atom.global_position.distance_to(new_atom.global_position)
	var direction = (new_atom.global_position - atom.global_position).normalized()
	var mid_position = (atom.global_position + new_atom.global_position) / 2.0
	
	# Calcula um vetor perpendicular à ligação para deslocar os cilindros
	var perpendicular = get_perpendicular_vector(direction)
	
	# Configurações baseadas no tipo de ligação
	var radius: float
	var offset_distance: float
	
	match amount:
		1:
			radius = 0.08
		2:
			radius = 0.05
		3:
			radius = 0.03

	offset_distance = radius * 2 # Distância entre as duas ligações

	# Cria o número de cilindros necessários
	for i in range(amount):
		var bond = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.height = distance
		cylinder.bottom_radius = radius
		cylinder.top_radius = radius
		
		bond.mesh = cylinder
		bond.material_override = bond_material
		bond.name = "Bond_" + str(i)
		new_atom.add_child(bond)
		
		# Calcula o deslocamento para cada cilindro
		var offset = Vector3.ZERO
		if amount == 2:
			# Para ligação dupla: desloca um para cada lado
			offset = perpendicular * offset_distance * (i - 0.5)
		elif amount == 3:
			# Para ligação tripla: um no centro, dois nas laterais
			offset = perpendicular * offset_distance * (i - 1.0)
		
		bond.global_position = mid_position + offset
		
		# Orienta o cilindro
		if bond.global_position == new_atom.global_position:
			push_error("Posição da ligação é igual à do novo átomo, não é possível fazer look_at.")
			continue
		
		bond.look_at(bond.global_position + direction, Vector3.UP)
		bond.rotate_object_local(Vector3.RIGHT, PI / 2.0)


func get_perpendicular_vector(direction: Vector3) -> Vector3:
	# Encontra um vetor perpendicular ao eixo da ligação
	# Usa o vetor UP como referência, mas evita quando paralelo
	var reference = Vector3.UP
	
	# Se a direção é paralela ao UP, usa outro vetor de referência
	if abs(direction.dot(Vector3.UP)) > 0.99:
		reference = Vector3.RIGHT
	
	# Produto vetorial para obter um vetor perpendicular
	var perpendicular = direction.cross(reference).normalized()
	return perpendicular


func set_atoms_position(Atoms: Array) -> void:
	var positions = get_geometry_positions(Atoms.size())
	
	for i in range(Atoms.size()):
		Atoms[i].position = positions[i]
		
		if central_atom.position == Atoms[i].position:
			push_error("Posição do átomo é igual à do átomo central, não é possível fazer look_at.")
			continue
		
		Atoms[i].look_at(central_atom.position, Vector3.UP)


func get_geometry_positions(num_atoms: int) -> Array:
	var positions = []
	var radius = 1.0  # Distância do átomo central
	
	match num_atoms:
		1:
			# Linear
			positions.append(Vector3(radius, 0, 0))
		2:
			# Linear (180°)
			positions.append(Vector3(radius, 0, 0))
			positions.append(Vector3(-radius, 0, 0))
		3:
			# Trigonal planar (120°)
			for i in range(3):
				var angle = i * (PI * 2 / 3)
				positions.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
		4:
			# Tetraédrica (109.5°)
			var a = radius / sqrt(3.0)
			positions.append(Vector3(a, a, a))
			positions.append(Vector3(a, -a, -a))
			positions.append(Vector3(-a, a, -a))
			positions.append(Vector3(-a, -a, a))
		5:
			# Bipiramidal trigonal
			# 3 átomos no plano equatorial
			for i in range(3):
				var angle = i * (PI * 2 / 3)
				positions.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
			# 2 átomos nos eixos axiais
			positions.append(Vector3(0, radius, 0))
			positions.append(Vector3(0, -radius, 0))
		6:
			# Octaédrica
			positions.append(Vector3(radius, 0, 0))
			positions.append(Vector3(-radius, 0, 0))
			positions.append(Vector3(0, radius, 0))
			positions.append(Vector3(0, -radius, 0))
			positions.append(Vector3(0, 0, radius))
			positions.append(Vector3(0, 0, -radius))
		_:
			# Para outros casos, usa distribuição circular no plano
			for i in range(num_atoms):
				var angle = i * (PI * 2 / num_atoms)
				positions.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
				
	return positions

# Cria um novo átomo e sua ligação ao átomo central ao clicar no botão
func _on_new_atom_pressed(num: int) -> void:
	if atoms.size() >= 6:
		return # Limita a 6 átomos ligados ao central

	var new_atom = create_atom(atom_material)

	molecule.add_child(new_atom)
	atoms.append(new_atom)

	set_atoms_position(atoms)
	create_bond(central_atom, new_atom, num)


func _on_reset_button_pressed() -> void:
	for atom in atoms:
		atom.queue_free()
	atoms.clear()
