extends Node

@onready var molecule: Node3D = %Molecule

@onready var vsepr_label: Label = %VSEPR
@onready var geometria_label: Label = %Geometria
@onready var arranjo_label: Label = %Arranjo

@export var central_atom_color: Color = Color.WHITE
@export var atom_color: Color = Color.SKY_BLUE
@export var free_pair_color: Color = Color.BEIGE
@export var eletron_color: Color = Color.YELLOW

@onready var molecular_data = preload("res://Main/molecule_data.gd").new()

var central_atom: MeshInstance3D
var atoms: Array = []

var central_atom_material: StandardMaterial3D
var atom_material: StandardMaterial3D
var free_pair_material: StandardMaterial3D
var eletron_material: StandardMaterial3D
var bond_material: StandardMaterial3D

class Atom extends MeshInstance3D:
	pass

class FreePair extends MeshInstance3D:
	pass

class Bond extends MeshInstance3D:
	pass

func _ready() -> void:
	set_materials()
	update_molecule_info(atoms)
	central_atom = create_atom(central_atom_material)
	molecule.add_child(central_atom)


func set_materials() -> void:
	central_atom_material = StandardMaterial3D.new()
	central_atom_material.albedo_color = central_atom_color

	atom_material = StandardMaterial3D.new()
	atom_material.albedo_color = atom_color

	free_pair_material = StandardMaterial3D.new()
	free_pair_material.albedo_color = free_pair_color
	free_pair_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	free_pair_material.albedo_color.a = 0.3

	eletron_material = StandardMaterial3D.new()
	eletron_material.albedo_color = eletron_color

	bond_material = StandardMaterial3D.new()
	var gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.add_point(0.0, central_atom_color)
	gradient.add_point(0.25, atom_color)

	var grad_tex = GradientTexture2D.new()
	grad_tex.fill_from = Vector2.ZERO
	grad_tex.fill_to = Vector2i(0.0, 1.0)
	grad_tex.width = 1
	grad_tex.gradient = gradient

	bond_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	bond_material.albedo_texture = grad_tex
	bond_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bond_material.albedo_color.a = 0.8


func create_atom(material: StandardMaterial3D) -> MeshInstance3D:
	# Cria uma esfera para representar o átomo
	var atom = Atom.new()
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
			radius = 0.12
		2:
			radius = 0.08
		3:
			radius = 0.05

	offset_distance = radius * 2.0 # Distância entre as duas ligações

	# Cria o número de cilindros necessários
	for i in range(amount):
		var bond = Bond.new()
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


func create_free_pair(material: StandardMaterial3D) -> MeshInstance3D:
	var ballon = FreePair.new()
	var sphere = SphereMesh.new()
	# Ajusta os valores do átomo
	sphere.radius = 0.25
	sphere.height = 0.75

	ballon.material_override = material

	ballon.mesh = sphere
	ballon.name = "Free pair"

	for i in range(2):
		var new_eletron = MeshInstance3D.new()
		var eletron_shape = SphereMesh.new()

		eletron_shape.radius = 0.1
		eletron_shape.height = 0.2

		new_eletron.material_override = eletron_material
		new_eletron.mesh = eletron_shape

		var offset = 0.11
		if i == 0:
			new_eletron.position = ballon.position - Vector3(0, -offset, 0)
		if i == 1:
			new_eletron.position = ballon.position - Vector3(0, offset, 0)

		ballon.add_child(new_eletron)

	return ballon


func set_atoms_position(atoms_array: Array) -> void:
	var positions = get_geometry_positions(atoms_array.size())
	
	atoms_array.sort_custom(func(a, b): 
		if a is FreePair and not b is FreePair:
			return false
		if b is FreePair and not a is FreePair:
			return true
		return true)

	for i in range(atoms_array.size()):
		atoms_array[i].position = positions[i]

		if atoms_array[i] is FreePair:
			atoms_array[i].position /= 1.5
		
		if central_atom.position == atoms_array[i].position:
			push_error("Posição do átomo é igual à do átomo central, não é possível fazer look_at.")
			continue
		
		atoms_array[i].look_at(central_atom.global_position, Vector3.UP)
		atoms_array[i].rotate_object_local(Vector3.RIGHT, PI/2)


func get_geometry_positions(num_atoms: int) -> Array:
	var positions = []
	var radius = 0.8  # Distância do átomo central
	
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
			# 2 átomos nos eixos axiais
			positions.append(Vector3(0, radius, 0))
			positions.append(Vector3(0, -radius, 0))
			# 3 átomos no plano equatorial
			for i in range(3):
				var angle = i * (PI * 2 / 3)
				positions.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
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


func update_molecule_info(molecule_array: Array) -> void:
	var atom_num: int = 0
	var freepair_num: int = 0
	for i in range(molecule_array.size()):
		if molecule_array[i] is Atom:
			atom_num += 1
		elif molecule_array[i] is FreePair:
			freepair_num += 1
	
	vsepr_label.text = "VSEPR:\n - AX" + str(atom_num) + ("E" + (str(freepair_num)if freepair_num > 1 else "") if freepair_num > 0 else "")
	
	var data = molecular_data.get_geometry(atom_num, freepair_num)

	geometria_label.text = "Geometria:\n - " + (data["geometria"] if atom_num > 1 else "")
	arranjo_label.text = ("Arranjo:\n - " + data["arranjo"] if atom_num > 1 and freepair_num > 0 else "")

# Cria um novo átomo e sua ligação ao átomo central ao clicar no botão
func _on_new_atom_pressed(num: int) -> void:
	if atoms.size() >= 6:
		return # Limita a 6 átomos ligados ao central

	var new_atom = create_atom(atom_material)

	molecule.add_child(new_atom)
	atoms.append(new_atom)

	set_atoms_position(atoms)
	update_molecule_info(atoms)
	create_bond(central_atom, new_atom, num)


func _on_new_pair_pressed():
	if atoms.size() >= 6:
		return # Limita a 6 átomos ligados ao central

	var new_pair = create_free_pair(free_pair_material)

	molecule.add_child(new_pair)
	atoms.append(new_pair)

	set_atoms_position(atoms)
	update_molecule_info(atoms)


func _on_reset_button_pressed() -> void:
	for atom in atoms:
		atom.queue_free()
	atoms.clear()
	update_molecule_info(atoms)
