class_name Atom
extends MeshInstance3D

var element: Element

func _init(_element: Element) -> void:
	element = _element
	var mat := StandardMaterial3D.new()

	mat.albedo_color = element.atom_color
	mat.roughness = 0.4
	mat.metallic = 0.1

	mesh = SphereMesh.new()
	mesh.radius = element.atom_radius
	mesh.height = element.atom_radius * 2.0

	material_override = mat

	_setup_atom_name_billboard()


func _setup_atom_name_billboard() -> void:
	var name_label := Label3D.new()
	name_label.set_layer_mask_value(1, false)
	name_label.set_layer_mask_value(3, true)
	name_label.text = element.symbol
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.pixel_size = element.atom_radius * 0.01
	name_label.font_size = 100
	name_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	name_label.no_depth_test = true
	add_child(name_label)
