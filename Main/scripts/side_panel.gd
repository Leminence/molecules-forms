extends PanelContainer

## Painel lateral que lista os átomos criados.
## Conecte os sinais do PlacerTool via setup().

@onready var list: VBoxContainer = %AtomList

var _placer: Node  # PlacerTool

func setup(placer: Node) -> void:
	_placer = placer
	placer.atom_added.connect(_on_atom_added)
	placer.atom_removed.connect(_on_atom_removed)


func _on_atom_added(atom: MeshInstance3D) -> void:
	var row := HBoxContainer.new()
	row.name = "Row_" + atom.name
	row.set_meta("atom", atom)

	var label := Label.new()
	label.text = atom.name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	var btn := Button.new()
	btn.text = "✕"
	btn.flat = true
	btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	btn.pressed.connect(_on_delete_pressed.bind(atom, row))

	row.add_child(label)
	row.add_child(btn)
	list.add_child(row)


func _on_atom_removed(atom: MeshInstance3D) -> void:
	# Remove a linha correspondente (caso a remoção venha de outra fonte futuramente)
	for row in list.get_children():
		if row.get_meta("atom") == atom:
			row.queue_free()
			return


func _on_delete_pressed(atom: MeshInstance3D, row: HBoxContainer) -> void:
	_placer.delete_atom(atom)
	# _on_atom_removed vai limpar a row via sinal,
	# mas se o atom já foi free'd antes do sinal chegar, garante aqui também
	if is_instance_valid(row):
		row.queue_free()