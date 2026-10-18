extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func resource_equal(a: Resource, b: Resource) -> bool:
	if a == null or b == null: return a == b
	if a.get_class() != b.get_class(): return false
	for property in a.get_property_list():
		if not property.usage & PROPERTY_USAGE_STORAGE: continue
		if property.name in ["resource_path","resource_name"]: continue
		var left: Variant = a.get(property.name)
		var right: Variant = b.get(property.name)
		if left is Resource:
			if not resource_equal(left,right): return false
		elif left != right:
			print("Environment mismatch: ",property.name)
			return false
	return true

func floor_supports(deck: Node3D, at: Vector3) -> bool:
	# Check the saved plank geometry rather than trusting dimensions in metadata.
	for child in deck.get_children():
		if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
		if not (str(child.name).begins_with("DeckPlank") or str(child.name).begins_with("RingPlank")): continue
		var bounds: AABB = child.mesh.get_aabb()
		bounds.position += child.position
		if absf(bounds.end.y-at.y)>.025: continue
		# A foot bridges the intentional 15 mm gaps between adjacent boards.
		if at.x>=bounds.position.x-.008 and at.x<=bounds.end.x+.008 and at.z>=bounds.position.z and at.z<=bounds.end.z: return true
	return false

func check_access(scene: Node3D) -> void:
	var platforms: Node3D = scene.get_node("TreehouseBackyard/Treehouse/BranchPlatforms")
	var lower: Node3D = platforms.get_node("LowerLookout")
	var upper: Node3D = platforms.get_node("UpperWraparound")
	check(upper.get_meta("deck_half_size").x>6,"Upper deck was not expanded around the cabin")
	var first: Node3D = platforms.get_node("GroundToLanding")
	var second: Node3D = platforms.get_node("LandingToTopDeck")
	check(absf(first.get_meta("foot").y-.08)<.01,"First ladder does not reach the ground")
	for pair in [[first,lower],[second,upper]]:
		var top: Vector3 = pair[0].get_meta("landing")
		check(floor_supports(pair[1],top+Vector3(0,0,-.15)),"Ladder has no deck landing: "+str(pair[0].name))
	check(floor_supports(lower,second.get_meta("foot")),"Upper ladder floats above or outside the lower landing")
	# Samples follow the walking route between the ladder flights across the lower landing.
	var start: Vector3 = first.get_meta("landing")+Vector3(0,0,-.4)
	var finish: Vector3 = second.get_meta("foot")+Vector3(0,0,-.1)
	for i in range(13):
		var sample: Vector3 = start.lerp(finish,float(i)/12)
		check(floor_supports(lower,sample),"Missing plank along the connecting landing")
	var trunk: MeshInstance3D = scene.get_node("TreehouseBackyard/Treehouse/LivingTree/TrunkAndBoughs/FlaredTrunk")
	var arrays: Array = trunk.mesh.surface_get_arrays(0)
	var vertex: Vector3 = arrays[Mesh.ARRAY_VERTEX][0]
	var normal: Vector3 = arrays[Mesh.ARRAY_NORMAL][0]
	check(normal.dot(Vector3(vertex.x,0,vertex.z).normalized())>.5,"Trunk faces point inward, leaving the base hollow")
	check(not floor_supports(upper,Vector3(-2.75,6.21,.4)),"Living fork is blocked by deck planks")
	check(scene.has_node("TreehouseBackyard/Treehouse/Cabin/LivingTrunkRecess"),"Cabin is missing the fitted trunk recess")

func run() -> void:
	var source: Node3D = load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate()
	var scene: Node3D = load("res://treehouse.tscn").instantiate()
	check(resource_equal(source.get_node("WorldEnvironment").environment,scene.get_node("WorldEnvironment").environment),"Environment differs from filled neighborhood")
	var original_sun: DirectionalLight3D = source.get_node("Sun")
	var sun: DirectionalLight3D = scene.get_node("Sun")
	for property in original_sun.get_property_list():
		if not property.usage & PROPERTY_USAGE_STORAGE: continue
		check(original_sun.get(property.name)==sun.get(property.name),"Sun property differs: "+property.name)
	var houses: int = 0
	for child in scene.get_node("NeighborhoodSlice").get_children():
		if child.get_meta("category","") in ["Houses","SightlineInfillHouses"]: houses += 1
		var original: Node3D = source.get_node("ExistingNeighborhood").get_node_or_null(NodePath(child.name))
		check(original != null and child.transform.is_equal_approx(original.transform),"Copied asset transform changed: "+child.name)
	check(houses>=10,"Insufficient surrounding houses")
	check(scene.get_node("TreehouseBackyard/Treehouse").scale==Vector3.ONE,"Assembly scale changed")
	check(scene.has_node("TreehouseBackyard/Treehouse/LivingTree/TrunkAndBoughs/FlaredTrunk"),"Custom supporting tree is missing")
	check(scene.has_node("TreehouseBackyard/Treehouse/BranchPlatforms/LowerLookout"),"Lower platform missing")
	check(scene.get_node("TreehouseBackyard").get_meta("yard_dimensions_m")==Vector2(32,39),"Backyard was not expanded")
	check(scene.find_children("*","CanvasLayer",true,false).is_empty(),"Game UI leaked into standalone scene")
	check_access(scene)
	source.free()
	root.add_child(scene)
	root.size = Vector2i(1440,900)
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/treehouse.png")
		scene.get_node("Views/NeighborhoodOverview").make_current()
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/neighborhood.png")
		var access_view := Camera3D.new()
		scene.add_child(access_view)
		access_view.position = Vector3(7,9,16)
		access_view.look_at(Vector3(0,5.2,0))
		access_view.fov = 60
		access_view.make_current()
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/deck_access.png")
		access_view.position = Vector3(-11,11.5,13)
		access_view.look_at(Vector3(-1.5,8,0))
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/trunk_joinery.png")
		# Inspect the actual tree silhouette with the built structure temporarily hidden.
		scene.get_node("TreehouseBackyard/Treehouse/Cabin").hide()
		scene.get_node("TreehouseBackyard/Treehouse/BranchPlatforms").hide()
		scene.get_node("Views/BackyardCamera").make_current()
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/tree_only.png")
		scene.get_node("TreehouseBackyard/Treehouse/Cabin").show()
		scene.get_node("TreehouseBackyard/Treehouse/BranchPlatforms").show()
	print("TREEHOUSE CHECK: ","PASS" if failures==0 else "FAIL", " | houses=",houses," | exact source environment and sun | original model transforms | no lesson UI")
	scene.queue_free()
	await process_frame
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await process_frame
	quit(failures)
