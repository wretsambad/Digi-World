class_name PipActor
extends Node3D
## Pip, the lesson companion: wraps the sculpted model with a recolourable
## jacket, a matching beanie the Glitch can steal, and simple moods.

const MODEL := preload("res://protect_base_assets/pip.tscn")
const OUTFIT_SHADER := preload("res://scripts/pip_outfit.gdshader")
const PAINTED_JACKET := Color("5d7d4f")

var model: Node3D
var hat: Node3D
var outfit_material: ShaderMaterial
var hat_material: StandardMaterial3D
var mood: String = "Idle"


func _ready() -> void:
	model = MODEL.instantiate()
	model.name = "Model"
	add_child(model)
	outfit_material = ShaderMaterial.new()
	outfit_material.shader = OUTFIT_SHADER
	outfit_material.set_shader_parameter("painted_jacket", _srgb(PAINTED_JACKET))
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as BaseMaterial3D
			if material and material.vertex_color_use_as_albedo:
				mesh.set_surface_override_material(surface, outfit_material)
	hat = _build_hat()
	put_hat_on()
	set_outfit(PlayerProfile.pip())


func set_outfit(color: Color) -> void:
	outfit_material.set_shader_parameter("outfit", _srgb(color))
	hat_material.albedo_color = color


func apply_profile() -> void:
	set_outfit(PlayerProfile.pip())


func set_mood(value: String) -> void:
	mood = value
	model.play_animation(value)


## A quick bright flash, used when a choice lands.
func flash() -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: outfit_material.set_shader_parameter("flash", v), 0.6, 0.0, 0.35)


func head() -> Node3D:
	return model.get_node("Body/Head")


func head_position() -> Vector3:
	return head().global_position


func has_hat() -> bool:
	return hat.get_parent() == head()


func put_hat_on() -> void:
	if hat.get_parent():
		hat.get_parent().remove_child(hat)
	head().add_child(hat)
	hat.position = Vector3(0, 0.27, -0.03)
	hat.rotation = Vector3(-0.12, 0, 0.08)
	hat.scale = Vector3.ONE


func _build_hat() -> Node3D:
	var root := Node3D.new()
	root.name = "Beanie"
	hat_material = StandardMaterial3D.new()
	hat_material.roughness = 1.0
	var crown := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.25
	dome.height = 0.36
	dome.is_hemisphere = true
	dome.radial_segments = 24
	dome.rings = 8
	dome.material = hat_material
	crown.mesh = dome
	crown.scale = Vector3(1.0, 0.9, 0.92)
	root.add_child(crown)
	var cuff_material := StandardMaterial3D.new()
	cuff_material.albedo_color = Color("f6e2bd")
	cuff_material.roughness = 1.0
	var cuff := MeshInstance3D.new()
	var band := CylinderMesh.new()
	band.top_radius = 0.258
	band.bottom_radius = 0.262
	band.height = 0.07
	band.radial_segments = 24
	band.material = cuff_material
	cuff.mesh = band
	cuff.scale = Vector3(1.0, 1.0, 0.92)
	cuff.position.y = 0.02
	root.add_child(cuff)
	var pom := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	ball.material = cuff_material
	pom.mesh = ball
	pom.position.y = 0.19
	root.add_child(pom)
	return root


static func _srgb(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)
