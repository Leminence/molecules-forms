extends Node

var elements: Array[Element] = [
	preload("res://data/elements/hydrogen.tres"),
	preload("res://data/elements/carbon.tres"),
	preload("res://data/elements/nitrogen.tres"),
	preload("res://data/elements/oxygen.tres"),
	preload("res://data/elements/fluorine.tres"),
	preload("res://data/elements/sulfur.tres"),
]

@export var element_selected: Element = elements[0]