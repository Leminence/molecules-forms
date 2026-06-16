class_name AtomContainer
extends PanelContainer

signal delete_requested(atom: MeshInstance3D)

@export var atom_name_label: Label
@export var atom_position_label: Label
@export var atom_delete_button: Button

var _atom: MeshInstance3D

func setup_atom_container(atom: MeshInstance3D) -> void:
	_atom = atom
	atom_name_label.text = atom.name
	var pos = atom.position
	atom_position_label.text = "Pos: <%.2f, %.2f, %.2f>" % [pos.x, pos.y, pos.z]
	atom_delete_button.pressed.connect(_on_delete_pressed)


func _on_delete_pressed() -> void:
	delete_requested.emit(_atom)
