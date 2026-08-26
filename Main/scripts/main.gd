extends Node

@onready var interaction: Node = $PlacerTool
@onready var ruler_tool: Node = $RulerTool
@onready var molecule: Node3D = %Molecule
@onready var main_viewport: SubViewportContainer = %MainViewport
@onready var atom_panel: PanelContainer = %SidePanel

@export var primary_camera: Camera3D

func _ready() -> void:
	interaction.setup(molecule, primary_camera, main_viewport)
	ruler_tool.setup(molecule, primary_camera, main_viewport)
	atom_panel.setup(interaction)


func _on_check_box_toggled(toggled_on: bool) -> void:
	primary_camera.set_cull_mask_value(3, toggled_on)


func _on_ruler_box_toggled(toggled_on: bool) -> void:
	ruler_tool.set_active(toggled_on)
