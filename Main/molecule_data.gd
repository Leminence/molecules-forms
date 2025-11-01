# molecular_data.gd
extends Node

const LINEAR: String = "Linear"
const TRIGONAL_PLANAR = "Trigonal plana"
const TETRAEDRIC = "Tetraédrica"
const BIPIRAMIDAL = "Bipiramidal Trigonal"
const OCTAEDRIC = "Octaédrica"

const ANGULAR: String = "Angular"
const PIRAMIDAL: String = "Piramidal"
const SEESAW: String = "Gangorra"
const QUAD_PIRAMIDAL: String = "Piramidal Quadrada"
const T_SHAPE: String = "Forma de T"
const QUAD_PLANAR: String = "Quadrado Planar"

const GEOMETRIES = {
	"geometrias": {
		[2, 1]: ANGULAR,
		[3, 1]: PIRAMIDAL,
		[4, 1]: SEESAW,
		[5, 1]: QUAD_PIRAMIDAL,
		[2, 2]: ANGULAR,
		[3, 2]: T_SHAPE,
		[4, 2]: QUAD_PLANAR,
		[2, 3]: LINEAR,
		[3, 3]: T_SHAPE,
		[2, 4]: LINEAR,
	},
	"arranjos": {
		1: LINEAR,
		2: LINEAR,
		3: TRIGONAL_PLANAR,
		4: TETRAEDRIC,
		5: BIPIRAMIDAL,
		6: OCTAEDRIC,
	},
	"angulos": {
		LINEAR: [180],
		TRIGONAL_PLANAR: [120],
		TETRAEDRIC: [109.5],
		BIPIRAMIDAL: [90, 120, 180],
		OCTAEDRIC: [90],
		ANGULAR: [117],
		PIRAMIDAL: [107],
		SEESAW: [90, 120],
		QUAD_PIRAMIDAL: [90],
		T_SHAPE: [90],
		QUAD_PLANAR: [90],
	},
}

# Função auxiliar para buscar
func get_geometry(ligantes: int, livres: int) -> Dictionary:
	var key = [ligantes, livres]

	var dic: Dictionary = {
		"geometria": null,
		"arranjo": null,
		"angulos": []
	}

	if key in GEOMETRIES["geometrias"]:
		dic["geometria"] = GEOMETRIES["geometrias"][key] 

	if ligantes + livres in GEOMETRIES["arranjos"]:
		dic["arranjo"] = GEOMETRIES["arranjos"][ligantes + livres]
		if dic["geometria"] == null and ligantes > 0:
			dic["geometria"] = dic["arranjo"] if ligantes != 1 else LINEAR

	if dic["geometria"] in GEOMETRIES["angulos"]:
		dic["angulos"] = GEOMETRIES["angulos"][dic["geometria"]]
	
	return dic
