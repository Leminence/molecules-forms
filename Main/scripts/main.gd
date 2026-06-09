extends Node

@onready var interaction: Node = $PlacerTool
@onready var molecule: Node3D = %Molecule
@export var camera: Camera3D
@onready var atom_panel: PanelContainer = %SidePanel

func _ready() -> void:
	interaction.setup(molecule, camera)
	atom_panel.setup(interaction)
