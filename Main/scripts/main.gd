extends Node

@onready var interaction: Node = $PlacerTool
@onready var molecule: Node3D = %Molecule
@onready var atom_panel: PanelContainer = %SidePanel

@export var camera: Camera3D

func _ready() -> void:
	interaction.setup(molecule, camera)
	atom_panel.setup(interaction)
