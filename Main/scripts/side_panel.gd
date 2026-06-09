extends PanelContainer

@onready var list: VBoxContainer = %AtomList
@export var atom_container_scene: PackedScene

var _placer: Node  # PlacerTool

func setup(placer: Node) -> void:
	_placer = placer
	placer.atom_added.connect(_on_atom_added)


func _on_atom_added(atom: MeshInstance3D) -> void:
	var row: AtomContainer = atom_container_scene.instantiate()
	list.add_child(row)
	row.setup_atom_container(atom)
	row.delete_requested.connect(_on_delete_requested.bind(row))


func _on_delete_requested(atom: MeshInstance3D, row: AtomContainer) -> void:
	_placer.delete_atom(atom)
	row.queue_free()