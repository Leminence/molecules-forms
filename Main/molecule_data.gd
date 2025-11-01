# molecular_data.gd
extends Node

const GEOMETRIES = {
	# Formato: "pares_ligantes_pares_livres": {dados}
	
	"2_0": {
		"geometria": "Linear",
		"arranjo": "Linear",
		"angulo": 180,
		"exemplo": "CO₂, BeH₂"
	},
	
	"3_0": {
		"geometria": "Trigonal Plana",
		"arranjo": "Trigonal Plana",
		"angulo": 120,
		"exemplo": "BF₃, SO₃"
	},
	
	"2_1": {
		"geometria": "Angular",
		"arranjo": "Trigonal Plana",
		"angulo": 117,
		"exemplo": "SO₂, O₃"
	},
	
	"4_0": {
		"geometria": "Tetraédrica",
		"arranjo": "Tetraédrica",
		"angulo": 109.5,
		"exemplo": "CH₄, CCl₄"
	},
	
	"3_1": {
		"geometria": "Piramidal",
		"arranjo": "Tetraédrica",
		"angulo": 107,
		"exemplo": "NH₃, PH₃"
	},
	
	"2_2": {
		"geometria": "Angular",
		"arranjo": "Tetraédrica",
		"angulo": 104.5,
		"exemplo": "H₂O, H₂S"
	},
	
	"5_0": {
		"geometria": "Bipiramidal Trigonal",
		"arranjo": "Bipiramidal Trigonal",
		"angulo": [90, 120, 180],
		"exemplo": "PCl₅, PF₅"
	},
	
	"4_1": {
		"geometria": "Gangorra",
		"arranjo": "Bipiramidal Trigonal",
		"angulo": [90, 120],
		"exemplo": "SF₄, TeCl₄"
	},
	
	"3_2": {
		"geometria": "Forma de T",
		"arranjo": "Bipiramidal Trigonal",
		"angulo": 90,
		"exemplo": "ClF₃, BrF₃"
	},
	
	"2_3": {
		"geometria": "Linear",
		"arranjo": "Bipiramidal Trigonal",
		"angulo": 180,
		"exemplo": "XeF₂, I₃⁻"
	},
	
	"6_0": {
		"geometria": "Octaédrica",
		"arranjo": "Octaédrica",
		"angulo": 90,
		"exemplo": "SF₆, Mo(CO)₆"
	},
	
	"5_1": {
		"geometria": "Piramidal Quadrada",
		"arranjo": "Octaédrica",
		"angulo": 90,
		"exemplo": "BrF₅, IF₅"
	},
	
	"4_2": {
		"geometria": "Quadrado Planar",
		"arranjo": "Octaédrica",
		"angulo": 90,
		"exemplo": "XeF₄, ICl₄⁻"
	}
}

# Função auxiliar para buscar
func get_geometry(ligantes: int, livres: int) -> Dictionary:
	var key = str(ligantes) + "_" + str(livres)
	if key in GEOMETRIES:
		return GEOMETRIES[key]
	return {}

# Função para obter todas as chaves
func get_all_keys() -> Array:
	return GEOMETRIES.keys()