extends Node
signal changed
const COLORS: Array[String] = ["409b89", "ef9d59", "76a8ce", "b68cc7", "df7990", "e2c468", "92b96b", "d9c8ac"]
const COLOR_NAMES: Array[String] = ["Teal", "Apricot", "Sky", "Lilac", "Rose", "Sunshine", "Leaf", "Sand"]
const FLAGS: Array[String] = ["Sun", "Moon", "Star", "Diamond", "Stripes", "Cross", "Mountain", "Dot"]
var house_color: int = 0
var flag_color: int = 5
var flag_design: int = 0
var pip_color: int = 1
var reduced_motion: bool = false
var muted: bool = false

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://player_profile.cfg") == OK:
		for key in ["house_color", "flag_color", "flag_design", "pip_color"]:
			set(key, clampi(int(config.get_value("appearance", key, get(key))), 0, 7))
		reduced_motion = bool(config.get_value("accessibility", "reduced_motion", false))
		muted = bool(config.get_value("accessibility", "muted", false))

func choose(key: String, value: int) -> void:
	if key not in ["house_color", "flag_color", "flag_design", "pip_color"]: return
	set(key, clampi(value, 0, 7))
	changed.emit()
	save_profile()

func save_profile() -> void:
	var config := ConfigFile.new()
	for key in ["house_color", "flag_color", "flag_design", "pip_color"]:
		config.set_value("appearance", key, get(key))
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	config.set_value("accessibility", "muted", muted)
	config.save("user://player_profile.cfg")
