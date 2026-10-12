extends Node3D
var model: Node3D
var mood: String = "idle"
var tint: ShaderMaterial

func _ready() -> void:
	model = preload("res://protect_base_assets/pip.tscn").instantiate()
	add_child(model)
	tint = ShaderMaterial.new()
	tint.shader = preload("res://scripts/pip_color.gdshader")
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var original: Material = mesh.get_active_material(0)
		if original is StandardMaterial3D and original.vertex_color_use_as_albedo:
			mesh.material_override = tint
	PlayerProfile.changed.connect(apply_profile)
	apply_profile()

func react(value: String) -> void:
	mood = value
	model.play_animation("Idle" if PlayerProfile.reduced_motion else {"idle":"Idle", "happy":"Wave", "worried":"Startled", "cheer":"Celebrate"}.get(value,"Idle"))

func apply_profile() -> void:
	# Recolor warm fur in the sculpt's vertex paint; preserve cream markings and clothes.
	tint.set_shader_parameter("fur_color",Color(PlayerProfile.COLORS[PlayerProfile.pip_color]))
