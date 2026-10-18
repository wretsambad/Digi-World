extends Node
## The player's "Make it yours" choices. Held in memory only: nothing is written
## to disk, and nothing about the player is collected or sent anywhere.

signal changed(key: String)

const HOUSE_COLORS: Array[Color] = [
	Color("6f8a5f"), Color("a8402f"), Color("5b8fb8"), Color("e0a83a"),
	Color("7d5a8c"), Color("3f8a86"), Color("e8d7b0"), Color("d9752e"),
]
const HOUSE_COLOR_NAMES: Array[String] = ["Sage", "Barn red", "Sky blue", "Sunflower", "Plum", "Teal", "Cream", "Pumpkin"]

const FLAG_DESIGNS: Array[String] = ["Sun", "Star", "Heart", "Moon", "Leaf", "Bolt", "Stripes", "Diamond", "Paw", "Crown"]
const FLAG_COLORS: Array[Color] = [
	Color("f0b23c"), Color("c8401f"), Color("3d6db5"), Color("5f9a45"),
	Color("8a5bb0"), Color("e27a9a"), Color("f4efe3"), Color("2f9c94"),
]
const FLAG_COLOR_NAMES: Array[String] = ["Gold", "Scarlet", "Blue", "Green", "Purple", "Pink", "White", "Teal"]

const PIP_COLORS: Array[Color] = [
	Color("5d7d4f"), Color("3f6fa8"), Color("a83d5c"), Color("e2b13c"),
	Color("6e4f9a"), Color("4fa58a"), Color("c9542a"), Color("7a5236"),
]
const PIP_COLOR_NAMES: Array[String] = ["Sage", "Ocean", "Berry", "Sunshine", "Grape", "Mint", "Ember", "Cocoa"]

var house_color: int = 0
var flag_design: int = 0
var flag_color: int = 0
var pip_color: int = 0


func set_choice(key: String, value: int) -> void:
	var limits: Dictionary = {
		"house_color": HOUSE_COLORS.size(),
		"flag_design": FLAG_DESIGNS.size(),
		"flag_color": FLAG_COLORS.size(),
		"pip_color": PIP_COLORS.size(),
	}
	if not limits.has(key):
		push_warning("Unknown profile choice: " + key)
		return
	var clamped: int = clampi(value, 0, int(limits[key]) - 1)
	if int(get(key)) == clamped:
		return
	set(key, clamped)
	changed.emit(key)


func house() -> Color:
	return HOUSE_COLORS[house_color]


func flag() -> Color:
	return FLAG_COLORS[flag_color]


func pip() -> Color:
	return PIP_COLORS[pip_color]


func reset() -> void:
	for key: String in ["house_color", "flag_design", "flag_color", "pip_color"]:
		set_choice(key, 0)
