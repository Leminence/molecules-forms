extends PanelContainer

@onready var element_option: OptionButton = %ElementOption
@onready var list: VBoxContainer = %AtomList
@export var atom_container_scene: PackedScene

var _placer: Node  # PlacerTool

func setup(placer: Node) -> void:
	_placer = placer
	placer.atom_added.connect(_on_atom_added)

	var sorted_elements = ChemistryData.elements.duplicate()
	for element in sorted_elements:
		element_option.add_item("Z = %d: %s [%s]" % [element.atomic_number, element.element_name, element.symbol])


func _on_atom_added(atom: Atom) -> void:
	var row: AtomContainer = atom_container_scene.instantiate()
	list.add_child(row)
	row.setup_atom_container(atom)
	row.delete_requested.connect(_on_delete_requested.bind(row))


func _on_delete_requested(atom: Atom, row: AtomContainer) -> void:
	_placer.delete_atom(atom)
	row.queue_free()


func _on_element_option_item_selected(index: int) -> void:
	var element = ChemistryData.elements[index]
	ChemistryData.element_selected = element

	print("Selected element: %s [%s, Z = %d]" % [element.element_name, element.symbol, element.atomic_number])
