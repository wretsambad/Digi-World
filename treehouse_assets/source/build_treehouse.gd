extends SceneTree
## Authoring utility: bakes an editable scene, never generates the world at play time.
const SOURCE := "res://neighborhood_assets/preview/neighborhood_filled.tscn"
const DEST := "res://treehouse.tscn"
const MODEL_DIR := "res://treehouse_assets/models/"
const ORIGIN := Vector3(-32.45957, 0, -2)
var palette: Dictionary = {}
var counts: Dictionary = {}
var removed: Array[String] = []

func _initialize() -> void:
	call_deferred("build")

func mat(key: String, hex: String) -> StandardMaterial3D:
	if not palette.has(key):
		var material := StandardMaterial3D.new()
		material.resource_name = key
		material.albedo_color = Color(hex)
		material.roughness = .88
		palette[key] = material
	return palette[key]

func group(parent: Node3D, label: String, position: Vector3 = Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = position
	parent.add_child(node,true)
	return node

func shape(parent: Node3D, label: String, at: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node,true)
	return node

func box(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return shape(parent,label,at,mesh,material)

func beam(parent: Node3D, label: String, start: Vector3, end: Vector3, width: float, depth: float, material: Material) -> MeshInstance3D:
	var node := box(parent,label,(start+end)*.5,Vector3(width,start.distance_to(end),depth),material)
	node.quaternion = Quaternion(Vector3.UP,(end-start).normalized())
	return node

func cylinder(parent: Node3D, label: String, at: Vector3, radius: float, height: float, material: Material, sides: int = 10) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	return shape(parent,label,at,mesh,material)

func prism(parent: Node3D, label: String, points: PackedVector3Array, faces: Array, material: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		for i in range(1,face.size()-1):
			for index in [face[0],face[i],face[i+1]]: st.add_vertex(points[index])
	st.generate_normals()
	return shape(parent,label,Vector3.ZERO,st.commit(),material)

func assign_owner(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		# Imported instances retain their own editable model boundaries.
		if child.scene_file_path.is_empty(): assign_owner(child,owner_root)

func save_scene(node: Node3D, path: String) -> void:
	assign_owner(node,node)
	var packed := PackedScene.new()
	assert(packed.pack(node)==OK,"Could not pack "+path)
	assert(ResourceSaver.save(packed,path)==OK,"Could not save "+path)

func export_model(node: Node3D, path: String) -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	assert(document.append_from_scene(node,state)==OK)
	assert(document.write_to_filesystem(state,path)==OK)

func limb(parent: Node3D, label: String, centers: Array[Vector3], radii: Array[float]) -> void:
	# Continuous tapered rings create bent, faceted boughs instead of pole joints.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	var sides: int = 9
	for j in range(centers.size()):
		var tangent: Vector3 = (centers[mini(j+1,centers.size()-1)]-centers[maxi(0,j-1)]).normalized()
		var frame := Basis(Quaternion(Vector3.UP,tangent))
		var ring := PackedVector3Array()
		for i in range(sides):
			var a: float = TAU*i/sides
			var organic: float = 1.0+.075*sin(i*2.7+j*.65)
			ring.append(centers[j]+frame*Vector3(cos(a)*radii[j]*organic,0,sin(a)*radii[j]*organic))
		rings.append(ring)
	for j in range(rings.size()-1):
		for i in range(sides):
			var n: int = (i+1)%sides
			var shade: Color = Color("805a3e").lightened(.075*sin(i*2.1))
			for point in [rings[j][i],rings[j+1][n],rings[j+1][i],rings[j][i],rings[j][n],rings[j+1][n]]:
				st.set_color(shade)
				st.add_vertex(point)
	for i in range(sides):
		for point in [centers[-1],rings[-1][i],rings[-1][(i+1)%sides]]:
			st.set_color(Color("926344"))
			st.add_vertex(point)
	st.generate_normals()
	var bark := mat("SculptedBark","ffffff")
	bark.vertex_color_use_as_albedo = true
	bark.vertex_color_is_srgb = true
	shape(parent,label,Vector3.ZERO,st.commit(),bark)

func crown(parent: Node3D, at: Vector3, dimensions: Vector3, seed: int) -> void:
	# Start with the engine's watertight winding, then sculpt irregular flat facets.
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	var arrays: Array = sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var colors: Array[Color] = [Color("4eac76"),Color("61c589"),Color("78cf96")]
	for tri in range(0,indices.size(),3):
		var shade: Color = colors[seed%colors.size()].lightened(.025*sin(tri*.13+seed))
		for offset in range(3):
			var point: Vector3 = vertices[indices[tri+offset]]
			var irregular: float = 1.0+.13*sin(point.x*3.7+point.y*2.1+point.z*4.2+seed*2.3)+.055*sin(point.x*8.1-point.z*5.4+seed)
			st.set_color(shade)
			st.add_vertex(point*dimensions*irregular)
	st.generate_normals()
	var leaves := mat("CanopyVertexPaint","ffffff")
	leaves.vertex_color_use_as_albedo = true
	leaves.vertex_color_is_srgb = true
	var cluster := shape(parent,"FoliageCluster%02d"%seed,at,st.commit(),leaves)
	cluster.rotation = Vector3(.14*sin(seed*2.1),seed*.73,.19*cos(seed*1.7))

func make_living_tree() -> Node3D:
	var tree := Node3D.new()
	tree.name = "LivingTree"
	tree.set_meta("purpose","Broad rooted trunk with an offset leader, unequal branching and a continuous natural canopy above the shelter")
	var boughs := group(tree,"TrunkAndBoughs")
	# A broad, blunt foot stays substantial through the lower lookout level.
	limb(boughs,"FlaredTrunk",[Vector3(0,-.45,0),Vector3(.08,.35,.02),Vector3(-.18,1.6,0),Vector3(-.35,3.25,-.35),Vector3(-.55,4.55,-1.45),Vector3(-.65,5.8,-3.45),Vector3(-.65,7,-3.75)],[2.9,2.78,2.4,2.0,1.5,1.2,1.08])
	# Roots merge below the lawn instead of ending in exposed triangular spikes.
	var root_angles: Array[float] = [.18,1.32,2.5,3.38,4.6,5.53]
	for i in range(root_angles.size()):
		var direction := Vector3(cos(root_angles[i]),0,sin(root_angles[i]))
		var reach: float = 2.65+.25*sin(i*2.1)
		limb(boughs,"ButtressRoot%02d"%i,[direction*.65+Vector3(0,.75,0),direction*1.7+Vector3(0,.45,0),direction*reach+Vector3(0,-.06,0),direction*(reach+.48)+Vector3(0,-.52,0)],[.95,.8,.5,.3])
	# One dominant leaning leader. Branches split at different heights and in depth,
	# rather than forming a matched pair of arms on either side of the cabin.
	limb(boughs,"MainLeader",[Vector3(-.65,6.1,-3.65),Vector3(-1.3,8.1,-3.9),Vector3(-2.8,10.4,-4.1),Vector3(-3.5,13.1,-4.6),Vector3(-5.1,16,-4.9),Vector3(-4.7,18.9,-4.3)],[1.14,1.01,.87,.68,.41,.12])
	limb(boughs,"LongWestBough",[Vector3(-.45,4.5,-1.2),Vector3(-2.6,5.55,-1.5),Vector3(-4.5,7.1,-1.8),Vector3(-6.3,8.3,-1.2),Vector3(-8.7,8.7,-.65),Vector3(-11.1,10.1,-1.5),Vector3(-12.2,11.5,-1.9)],[1.05,.87,.7,.54,.39,.24,.07])
	limb(boughs,"WestRisingFork",[Vector3(-5.4,7.7,-1.5),Vector3(-6.2,10.3,-2),Vector3(-7.9,12.1,-2.6),Vector3(-8.5,14.3,-2.5)],[.54,.42,.27,.08])
	limb(boughs,"WestOuterTwig",[Vector3(-9.5,9.1,-.9),Vector3(-10.3,10.7,.1),Vector3(-10.1,12.2,.5)],[.27,.17,.05])
	limb(boughs,"WestDroopingTwig",[Vector3(-10.6,9.8,-1.3),Vector3(-12.4,9.55,-2.4),Vector3(-13.2,9.1,-2.8)],[.2,.12,.035])
	limb(boughs,"HighEastBough",[Vector3(-2.5,10,-4.05),Vector3(-.1,10.7,-5.1),Vector3(2.3,12,-5.4),Vector3(4.5,12.6,-4.8),Vector3(6.6,14.1,-4.2)],[.72,.59,.46,.31,.09])
	limb(boughs,"EastSideTwig",[Vector3(3.4,12.3,-5.1),Vector3(4.8,12.1,-3.5),Vector3(6.8,12.5,-2.7),Vector3(7.6,13.3,-2.4)],[.3,.24,.15,.045])
	limb(boughs,"EastUpright",[Vector3(1.5,11.6,-5.3),Vector3(2.4,14.3,-6),Vector3(1.7,16.4,-5.8)],[.36,.23,.06])
	limb(boughs,"UpperWestFork",[Vector3(-3.5,13.1,-4.6),Vector3(-6.3,14.1,-5.9),Vector3(-8.7,16.2,-6),Vector3(-9.3,17.1,-5.3)],[.48,.36,.21,.055])
	limb(boughs,"LeaderSideShoot",[Vector3(-5,16,-4.9),Vector3(-2.7,17.1,-5.9),Vector3(-1.1,18,-5.7)],[.3,.19,.06])
	limb(boughs,"RearBough",[Vector3(-1.6,8.7,-4),Vector3(-2,10.5,-6.3),Vector3(-.7,12.5,-8.1),Vector3(-1.5,14.8,-8.8)],[.61,.43,.28,.07])
	limb(boughs,"ShortOldSpur",[Vector3(-4.5,7.1,-1.8),Vector3(-5.2,7.65,.2),Vector3(-5.9,7.85,.7)],[.3,.2,.12])
	# A living fork runs through the balcony and a purpose-cut cabin wall/eave.
	limb(boughs,"CabinSideTrunk",[Vector3(-.35,4.2,-.7),Vector3(-2.75,6.25,.4),Vector3(-3.2,8.6,.5),Vector3(-3.8,10.4,.1),Vector3(-5,12.4,-1.1),Vector3(-6,13.4,-2.3)],[.96,.8,.66,.48,.28,.08])
	# Clear the balcony, rise, then turn back toward the cabin and rear canopy.
	# The compact returning curve differs from the long outward western bough.
	limb(boughs,"PlatformSupportingFork",[Vector3(-.1,4.1,0),Vector3(2,5,-.4),Vector3(3.9,5.58,1.1),Vector3(5.3,5.62,1.9),Vector3(6.8,5.85,1.7),Vector3(7.8,6.75,1.25),Vector3(8.15,8.25,.3),Vector3(7.65,9.85,-.9),Vector3(6.7,10.95,-1.9),Vector3(5.8,11.7,-2.7)],[.72,.54,.34,.3,.28,.25,.21,.16,.1,.045])
	limb(boughs,"SupportingForkLeafShoot",[Vector3(8.1,8.2,.35),Vector3(7.25,8.9,1.1),Vector3(6.35,9.65,.8)],[.2,.13,.04])
	# A full upper branching system continues over the roof, independent of the cabin.
	limb(boughs,"CentralUpperLeader",[Vector3(-2.8,10.4,-4.1),Vector3(-.7,12.3,-4),Vector3(.3,14.8,-3.3),Vector3(1.7,17.3,-2.6),Vector3(1.1,19.5,-1.8),Vector3(1.5,21.15,-2.1)],[.72,.6,.49,.37,.23,.055])
	limb(boughs,"OverRoofBough",[Vector3(.3,14.8,-3.3),Vector3(2.4,15.4,-1.8),Vector3(4.5,16.5,-.7),Vector3(5.5,18,.2)],[.43,.34,.22,.06])
	limb(boughs,"OverRoofFork",[Vector3(2.9,15.7,-1.5),Vector3(3.7,17.9,-2.4),Vector3(4.8,19.2,-2.8)],[.26,.18,.045])
	limb(boughs,"CentralForwardShoot",[Vector3(1.7,17.3,-2.6),Vector3(.2,17.7,-.7),Vector3(-.3,18.7,.8)],[.26,.18,.04])
	limb(boughs,"FrontCanopyFork",[Vector3(-5,12.4,-1.1),Vector3(-3.8,13.7,.25),Vector3(-2.3,15.1,1.3),Vector3(-2.55,16,1.55)],[.26,.21,.12,.035])
	limb(boughs,"RearLowerBough",[Vector3(-1.3,8.1,-3.9),Vector3(1,8.8,-5.6),Vector3(3.3,9.8,-7.1),Vector3(5,11.1,-8.2)],[.58,.43,.28,.06])
	limb(boughs,"RearLowerTwig",[Vector3(3.3,9.8,-7.1),Vector3(3.1,11.6,-8.1),Vector3(2.4,12.7,-8.9)],[.23,.14,.04])
	# The bulk grows left of the house. Smaller flattened leaf sprays break the outline,
	# with visible gaps around branch junctions and a much lower, shorter eastern side.
	var foliage := group(tree,"NaturalCanopy")
	var clusters: Array = [
		[Vector3(-5,18.2,-4.4),Vector3(3.2,2.45,2.8)],
		[Vector3(-6.3,16.3,-4.8),Vector3(4.0,2.25,3.1)],
		[Vector3(-3.1,16.1,-5.8),Vector3(3.3,2.7,3.2)],
		[Vector3(-1.2,18,-5.8),Vector3(2.5,1.35,2.0)],
		[Vector3(-8.8,16.8,-5.6),Vector3(2.5,1.6,2.5)],
		[Vector3(-9.8,15.7,-6.2),Vector3(2.0,1.25,1.7)],
		[Vector3(-8.6,14,-2.5),Vector3(2.65,1.7,2.3)],
		[Vector3(-6.7,13.3,-3.6),Vector3(2.0,1.6,2.1)],
		[Vector3(-12,11.6,-2),Vector3(2.7,1.6,2.0)],
		[Vector3(-10.2,12.3,.35),Vector3(1.7,1.25,1.55)],
		[Vector3(-13.1,9.65,-2.8),Vector3(1.55,1.0,1.4)],
		[Vector3(-1.4,14.6,-8.5),Vector3(3.0,2.15,2.6)],
		[Vector3(1.5,16,-5.9),Vector3(2.1,1.8,2.2)],
		[Vector3(3.7,14.2,-5.8),Vector3(2.7,1.5,2.5)],
		[Vector3(6.4,14.1,-4.4),Vector3(2.2,1.55,2.15)],
		[Vector3(7.7,13.4,-2.4),Vector3(1.6,1.1,1.5)],
		[Vector3(-4.4,19.65,-4.8),Vector3(1.7,1.1,1.6)],
		[Vector3(5.9,11.7,-2.55),Vector3(2.1,1.65,1.95)],
		[Vector3(6.4,9.8,.75),Vector3(1.55,1.3,1.45)],
		[Vector3(1,19.15,-1.8),Vector3(3.0,2.4,2.7)],
		[Vector3(1.45,21.15,-2.2),Vector3(1.9,1.25,1.85)],
		[Vector3(2.1,16.8,-2),Vector3(2.8,2.0,2.3)],
		[Vector3(5.4,17.9,.1),Vector3(2.5,1.9,2.1)],
		[Vector3(4.7,19.3,-2.9),Vector3(2.0,1.45,1.8)],
		[Vector3(-2.4,15.9,1.4),Vector3(1.85,1.4,1.8)],
		[Vector3(4.9,11.4,-8.1),Vector3(2.25,1.55,2.1)],
		[Vector3(2.5,12.9,-8.9),Vector3(1.5,1.2,1.45)]]
	for i in range(clusters.size()): crown(foliage,clusters[i][0],clusters[i][1],i)
	return tree

func deck_edge_z(x: float, rx: float, rz: float, center_z: float) -> float:
	return center_z+rz*sqrt(maxf(0,1-pow(x/rx,4)))

func ring_deck(parent: Node3D, label: String, y: float, rx: float, rz: float, center_z: float, hole: Vector2, hole_radius: float, access_x: float, extra_holes: Array[Vector3] = []) -> Node3D:
	var deck := group(parent,label)
	deck.set_meta("deck_half_size",Vector2(rx,rz))
	deck.set_meta("surface_height",y+.09)
	var wood := mat("HoneyCedar","b58150")
	var light := mat("HoneyCedarLight","c99965")
	var columns: int = ceili(rx*2/.31)
	var spacing: float = rx*2/columns
	for i in range(columns):
		var x: float = -rx+spacing*(i+.5)
		var end: float = rz*sqrt(maxf(0,1-pow(x/rx,4)))
		var holes: Array[Vector3] = [Vector3(hole.x,hole.y,hole_radius)]
		holes.append_array(extra_holes)
		var segments: Array[Vector2] = [Vector2(center_z-end,center_z+end)]
		for opening in holes:
			var gap: float = sqrt(maxf(0,opening.z*opening.z-pow(x-opening.x,2)))
			if gap<=0: continue
			var remaining: Array[Vector2] = []
			for segment in segments:
				if opening.y+gap<=segment.x or opening.y-gap>=segment.y:
					remaining.append(segment)
				else:
					if opening.y-gap>segment.x: remaining.append(Vector2(segment.x,opening.y-gap))
					if opening.y+gap<segment.y: remaining.append(Vector2(opening.y+gap,segment.y))
			segments = remaining
		for segment in segments:
			if segment.y>segment.x: box(deck,"RingPlank",Vector3(x,y,(segment.x+segment.y)*.5),Vector3(spacing-.015,.18,segment.y-segment.x),light if i%3==0 else wood)
	# Traverse the same superellipse as the planks. Insert exact ladder opening corners.
	var points: Array[Vector3] = []
	var front_x: Array[float] = []
	for i in range(17): front_x.append(-rx+2*rx*i/16)
	front_x.append(access_x-.87)
	front_x.append(access_x+.87)
	front_x.sort()
	for x in front_x:
		if absf(x-access_x)<.86: continue
		points.append(Vector3(x,y,deck_edge_z(x,rx,rz,center_z)))
	for i in range(1,16):
		var x: float = rx-2*rx*i/16
		points.append(Vector3(x,y,2*center_z-deck_edge_z(x,rx,rz,center_z)))
	for i in range(points.size()):
		var at: Vector3 = points[i]
		box(deck,"RailingPost",at+Vector3.UP*.68,Vector3(.16,1.44,.16),wood)
		var next: Vector3 = points[(i+1)%points.size()]
		var opening: bool = at.z>center_z and next.z>center_z and at.x<access_x and next.x>access_x
		if not opening:
			for h in [.4,1.28]: beam(deck,"PerimeterRail",at+Vector3.UP*h,next+Vector3.UP*h,.13,.14,light)
	return deck

func access_ladder(parent: Node3D, label: String, foot: Vector3, landing: Vector3) -> void:
	var ladder := group(parent,label)
	ladder.set_meta("foot",foot)
	ladder.set_meta("landing",landing)
	var wood := mat("HoneyCedarLight","c99965")
	var dark := mat("HoneyCedar","b58150")
	var direction: Vector3 = (landing-foot).normalized()
	for side in [-1,1]:
		var offset := Vector3(side*.66,0,0)
		beam(ladder,"ContinuousStringer",foot+offset,landing+direction*.98+offset,.15,.2,dark)
	var steps: int = ceili((landing.y-foot.y)/.29)
	for i in range(1,steps+1):
		var at: Vector3 = foot.lerp(landing,float(i)/steps)
		box(ladder,"LevelTread%02d"%i,at-Vector3.UP*.07,Vector3(1.4,.14,.34),wood)

func make_platforms() -> Node3D:
	var platforms := Node3D.new()
	platforms.name = "BranchPlatforms"
	ring_deck(platforms,"UpperWraparound",6.12,6.35,5.2,0,Vector2(-.65,-3.75),1.3,2.3,[Vector3(-2.75,.4,1.1),Vector3(-3.32,-1.62,1.05)])
	ring_deck(platforms,"LowerLookout",3.2,4.5,4.6,1.2,Vector2(-.35,-.35),2.4,-.9)
	var wood := mat("SupportTimber","785b43")
	var support := group(platforms,"BranchBracing")
	for x in [-4.8,4.8]:
		box(support,"UpperJoist",Vector3(x,5.82,0),Vector3(.3,.45,8.1),wood)
		beam(support,"ForkBrace",Vector3(x*.48,4.95,-1.5),Vector3(x,5.82,3.35),.3,.34,wood)
	for z in [-2.9,2.9]: box(support,"UpperCrossBeam",Vector3(0,5.82,z),Vector3(11.8,.43,.3),wood)
	for x in [-2.6,2.6]:
		box(support,"LowerJoist",Vector3(x,2.94,1.5),Vector3(.27,.35,7.8),wood)
		beam(support,"LowerKneeBrace",Vector3(x*.5,1.7,.7),Vector3(x,2.94,4.7),.27,.3,wood)
	var fitted := group(platforms,"FittedTreeJoinery")
	for i in range(10):
		var a: float = TAU*i/10
		var b: float = TAU*(i+1)/10
		beam(fitted,"TrunkOpeningRim",Vector3(-2.75+1.15*cos(a),6.25,.4+1.15*sin(a)),Vector3(-2.75+1.15*cos(b),6.25,.4+1.15*sin(b)),.16,.22,mat("HoneyCedarLight","c99965"))
	box(fitted,"BranchSaddle",Vector3(3.85,5.91,1.12),Vector3(.48,.35,2.1),wood)
	beam(fitted,"CabinCornerBrace",Vector3(-3.05,7.25,1.06),Vector3(-1.45,6.03,1.68),.22,.25,wood)
	# A walkable front landing joins both flights; each ends flush with its deck.
	var lower_edge: float = deck_edge_z(-.9,4.5,4.6,1.2)
	var upper_edge: float = deck_edge_z(2.3,6.35,5.2,0)
	access_ladder(platforms,"GroundToLanding",Vector3(-.9,.08,lower_edge+1.9),Vector3(-.9,3.29,lower_edge))
	access_ladder(platforms,"LandingToTopDeck",Vector3(2.3,3.29,5.48),Vector3(2.3,6.21,upper_edge))
	return platforms

func make_cabin() -> Node3D:
	var cabin := Node3D.new()
	cabin.name = "TreehouseCabin"
	var wood := mat("HoneyCedar","b58150")
	var board_light := mat("HoneyCedarLight","c99965")
	var board_dark := mat("HoneyCedarDark","a97447")
	var bark := mat("SupportTimber","785b43")
	var sage := mat("SagePaint","648c7b")
	var trim := mat("CreamTrim","eee1b7")
	var roof := mat("Terracotta","c8784c")
	var roof_light := mat("TerracottaLight","d58a59")
	var glass := mat("WindowTeal","396c73")
	var iron := mat("DarkIron","3b5154")
	var structure := group(cabin,"PlatformAndBraces")
	for x in [-3.7,0.0,3.7]:
		box(structure,"MainBeam",Vector3(x,3.82,0),Vector3(.32,.5,8.25),bark)
	for z in [-3.4,-1.6,.3,2.2,3.8]:
		box(structure,"CrossBeam",Vector3(0,3.72,z),Vector3(9.8,.3,.22),bark)
	for i in range(30):
		box(structure,"DeckPlank%02d"%i,Vector3(-4.68+i*.322,4.12,0),Vector3(.308,.18,8.1),[wood,board_light,board_dark][i%3])
	for x in [-3.7,3.7]:
		beam(structure,"TreeBrace",Vector3(-1.6,1.7,-2.6),Vector3(x,3.82,2.6),.26,.32,bark)
		beam(structure,"RearTreeBrace",Vector3(-1.8,2,-2.6),Vector3(x,3.82,-3.2),.26,.32,bark)
	# Short side supports ground the outer balcony without turning the tree into stilts.
	for x in [-4.2,4.2]:
		beam(structure,"KneeBrace",Vector3(x,2.9,-2.8),Vector3(x,3.85,-.8),.22,.26,bark)
	var walls := group(cabin,"CabinCladding")
	# Wall shell: front has a real doorway and two window apertures.
	box(walls,"BackWall",Vector3(0,5.73,-2.7),Vector3(6.8,3.1,.16),sage)
	for side in [-1,1]:
		for row in range(12):
			if side == -1:
				# The wall ends on either side of the living trunk; no wall mesh clips through it.
				for section in [Vector2(-2.775,-.85),Vector2(1.8,2.475)]:
					box(walls,"TreeNotchedClapboard",Vector3(side*3.4,4.34+row*.255,(section.x+section.y)*.5),Vector3(.18,.245,section.y-section.x),[wood,board_light,wood,board_dark][row%4])
			else:
				box(walls,"SideClapboard",Vector3(side*3.4,4.34+row*.255,-.15),Vector3(.18,.245,5.25),[wood,board_light,wood,board_dark][row%4])
	for row in range(12):
		var y: float = 4.34+row*.255
		for side in [-1,1]:
			# Door centered; windows occupy the top half of the side panels.
			if y < 5.35 or y > 6.7:
				box(walls,"FrontBoard",Vector3(side*2.14,y,2.5),Vector3(2.5,.245,.18),[wood,board_light,wood][row%3])
			else:
				for x in [1.04,3.12]: box(walls,"WindowEdgeBoard",Vector3(side*x,y,2.5),Vector3(.45,.245,.18),wood)
		if y > 6.75: box(walls,"DoorLintelBoard",Vector3(0,y,2.5),Vector3(1.8,.245,.18),wood)
	for x in [-3.48,3.48]:
		for z in [-2.7,2.55]: box(walls,"CornerPost",Vector3(x,5.78,z),Vector3(.23,3.3,.24),trim)
	box(walls,"Sill",Vector3(0,4.3,2.62),Vector3(7.1,.16,.22),trim)
	var door := group(cabin,"Door",Vector3(0,4.22,2.57))
	for i in range(6): box(door,"SageDoorPlank",Vector3(-.68+i*.27,1.24,0),Vector3(.26,2.48,.14),sage)
	for y in [.4,1.9]: box(door,"DoorBrace",Vector3(0,y,.1),Vector3(1.6,.16,.07),trim)
	beam(door,"DiagonalDoorBrace",Vector3(-.65,.4,.11),Vector3(.65,1.9,.11),.12,.06,trim)
	cylinder(door,"RoundHandle",Vector3(.51,1.18,.15),.065,.1,iron).rotation.x = PI/2
	for x in [-.91,.91]: box(door,"DoorFrame",Vector3(x,1.35,0),Vector3(.16,2.7,.23),trim)
	box(door,"DoorHeader",Vector3(0,2.7,0),Vector3(1.98,.18,.23),trim)
	for x in [-2.08,2.08]:
		var window := group(cabin,"Window",Vector3(x,6.04,2.62))
		box(window,"RecessedGlass",Vector3(0,0,-.015),Vector3(1.4,1.3,.06),glass)
		for xx in [-.76,0,.76]: box(window,"VerticalMullion",Vector3(xx,0,.04),Vector3(.1,1.48,.12),trim)
		for yy in [-.72,0,.72]: box(window,"HorizontalMullion",Vector3(0,yy,.045),Vector3(1.6,.1,.13),trim)
		for side in [-1,1]:
			var shutter := group(window,"Shutter",Vector3(side*1.05,0,-.03))
			shutter.rotation.y = side*.18
			box(shutter,"Panel",Vector3.ZERO,Vector3(.43,1.45,.12),sage)
			for y in [-.5,-.25,0,.25,.5]: box(shutter,"Louver",Vector3(0,y,.09),Vector3(.39,.075,.05),trim)
		box(window,"FlowerBox",Vector3(0,-.94,.19),Vector3(1.65,.3,.4),board_dark)
		for xx in [-.58,-.18,.23,.56]:
			cylinder(window,"Plant",Vector3(xx,-.65,.17),.14,.28,mat("Leaves","638b50"),5)
			var flower := SphereMesh.new()
			flower.radius = .115
			flower.height = .19
			flower.radial_segments = 6
			flower.rings = 3
			shape(window,"Blossom",Vector3(xx,-.48,.17),flower,mat("Flowers","edba68"))
	var roof_group := group(cabin,"GabledRoof")
	var pts := PackedVector3Array([Vector3(-3.4,7.28,2.5),Vector3(3.4,7.28,2.5),Vector3(0,10.35,2.5),Vector3(-3.4,7.28,-2.7),Vector3(3.4,7.28,-2.7),Vector3(0,10.35,-2.7)])
	prism(roof_group,"Gables",pts,[[0,2,1],[3,4,5],[0,3,5,2],[1,2,5,4],[0,1,4,3]],sage)
	for side in [-1,1]:
		for strip in range(18):
			var z: float = -3.04+strip*.35
			var notched: bool = side == -1 and z > -.95 and z < 1.85
			var shift: float = .68 if notched else 0.0
			var slope := box(roof_group,"RoofBoard",Vector3(side*1.98+shift*cos(.7),8.81+shift*sin(.7),z),Vector3(5.15-shift*2,.17,.337),roof_light if strip%4==0 else roof)
			slope.rotation.z = -side*.70
		beam(roof_group,"CreamGableFascia",Vector3(side*4.0,7.13,3.11),Vector3(0,10.5,3.11),.19,.2,trim)
		if side == -1:
			for section in [Vector2(-3.225,-1.12),Vector2(1.98,3.225)]:
				box(roof_group,"NotchedEave",Vector3(side*3.95,7.12,(section.x+section.y)*.5),Vector3(.18,.2,section.y-section.x),trim)
		else:
			box(roof_group,"Eave",Vector3(side*3.95,7.12,0),Vector3(.18,.2,6.45),trim)
	beam(roof_group,"Ridge",Vector3(0,10.45,-3.24),Vector3(0,10.45,3.22),.23,.23,roof_light)
	cylinder(roof_group,"AtticFrame",Vector3(0,8.09,2.58),.47,.14,trim,12).rotation.x = PI/2
	cylinder(roof_group,"AtticWindow",Vector3(0,8.09,2.67),.34,.06,glass,12).rotation.x = PI/2
	box(roof_group,"AtticMullion",Vector3(0,8.09,2.72),Vector3(.065,.66,.06),trim)
	var rail := group(cabin,"BalconyRailings")
	for x in [-4.65,-3.3,-1.8,1.8,3.3,4.65]:
		box(rail,"FrontPost",Vector3(x,4.78,3.94),Vector3(.16,1.34,.16),trim)
		box(rail,"PostCap",Vector3(x,5.48,3.94),Vector3(.24,.08,.24),wood)
	for side in [-1,1]:
		for y in [4.52,5.32]: box(rail,"FrontRail",Vector3(side*3.21,y,3.94),Vector3(2.9,.13,.13),wood)
		for z in [-3.8,-2,-.1,1.8]: box(rail,"SidePost",Vector3(side*4.65,4.78,z),Vector3(.16,1.34,.16),trim)
		for y in [4.52,5.32]: box(rail,"SideRail",Vector3(side*4.65,y,0),Vector3(.13,.13,8.0),wood)
	for x in [-4.5,4.5]:
		box(cabin,"Planter",Vector3(x,4.46,2.85),Vector3(.52,.48,.58),sage)
	# Remove the former freestanding porch: the tree forks support new ring decks.
	for obsolete in [structure,rail]:
		cabin.remove_child(obsolete)
		obsolete.free()
	var reshape := Transform3D(Basis.from_scale(Vector3(.84,1,.82)),Vector3(0,2,0))
	for child in cabin.get_children(): child.transform = reshape*child.transform
	# Visible jambs and a small header express a house constructed around the living fork.
	var tree_recess := group(cabin,"LivingTrunkRecess")
	for z in [-.7,1.48]:
		box(tree_recess,"RecessJamb",Vector3(-2.89,7.76,z),Vector3(.18,3.05,.16),trim)
	box(tree_recess,"RecessHeader",Vector3(-2.89,9.28,.39),Vector3(.2,.18,2.34),wood)
	box(tree_recess,"NotchInnerFascia",Vector3(-2.46,10.04,.35),Vector3(.18,.2,2.58),trim)
	# A small roof pennant echoes the supplied reference.
	cylinder(cabin,"Flagpole",Vector3(.1,13.1,-.5),.045,1.9,trim,8)
	prism(cabin,"Pennant",PackedVector3Array([Vector3(.12,13.98,-.5),Vector3(1.25,13.77,-.5),Vector3(.93,13.4,-.5),Vector3(.12,13.5,-.5)]),[[0,1,2,3],[3,2,1,0]],mat("FlagCoral","d66b46"))
	return cabin

func instance_asset(parent: Node3D, path: String, label: String, at: Vector3, scale_factor: float = 1) -> Node3D:
	var node: Node3D = load(path).instantiate()
	node.name = label
	parent.add_child(node,true)
	node.position = at
	node.scale = Vector3.ONE*scale_factor
	return node

func build() -> void:
	var source: Node3D = load(SOURCE).instantiate()
	var scene := Node3D.new()
	scene.name = "Treehouse"
	scene.set_meta("source_neighborhood",SOURCE)
	scene.set_meta("scale_convention","1 Godot unit = approximately 1 metre; source models retain original transforms")
	var neighborhood := group(scene,"NeighborhoodSlice",-ORIGIN)
	for child in source.get_node("ExistingNeighborhood").get_children():
		if not child is Node3D or child.scene_file_path.is_empty(): continue
		if child.name == "LearningHouse": continue
		var pos: Vector3 = child.position
		var ground: bool = str(child.name).begins_with("NeighborhoodGround")
		if not ground and (pos.x < -82 or pos.x > 56 or pos.z < -62 or pos.z > 60): continue
		# Keep mature crowns outside the enlarged yard and the main viewing approach.
		var category_name: String = child.get_meta("category", "")
		var tree_position: Vector3 = pos-ORIGIN
		if ("Trees" in category_name or category_name == "TreeBelt") and tree_position.x > -22 and tree_position.x < 14 and tree_position.z > -22 and tree_position.z < 29:
			removed.append(str(child.name))
			continue
		# Expand the garden across adjacent rear plots. Preserve its owning house.
		var local: Vector3 = pos-ORIGIN
		if not ground and child.name != "House_West_03" and local.x > -20 and local.x < 12 and local.z > -19 and local.z < 20:
			removed.append(str(child.name))
			continue
		var copied := child.duplicate()
		neighborhood.add_child(copied)
		var category: String = child.get_meta("category", "Other")
		counts[category] = int(counts.get(category,0))+1
	# Exact source environment and sunlight; do not reinterpret any lighting values.
	for name in ["WorldEnvironment","Sun"]:
		var copied: Node = source.get_node(name).duplicate()
		scene.add_child(copied)
	var garden := group(scene,"TreehouseBackyard")
	garden.set_meta("belongs_to","NeighborhoodSlice/House_West_03")
	var cabin := make_cabin()
	save_scene(cabin,MODEL_DIR+"treehouse_cabin.tscn")
	export_model(cabin,MODEL_DIR+"treehouse_cabin.glb")
	cabin.free()
	var living_tree := make_living_tree()
	save_scene(living_tree,MODEL_DIR+"living_tree.tscn")
	export_model(living_tree,MODEL_DIR+"living_tree.glb")
	living_tree.free()
	var platforms := make_platforms()
	save_scene(platforms,MODEL_DIR+"branch_platforms.tscn")
	export_model(platforms,MODEL_DIR+"branch_platforms.glb")
	platforms.free()
	var assembly := Node3D.new()
	assembly.name = "TreehouseOak"
	instance_asset(assembly,MODEL_DIR+"treehouse_cabin.tscn","Cabin",Vector3.ZERO)
	instance_asset(assembly,MODEL_DIR+"living_tree.tscn","LivingTree",Vector3.ZERO)
	instance_asset(assembly,MODEL_DIR+"branch_platforms.tscn","BranchPlatforms",Vector3.ZERO)
	save_scene(assembly,MODEL_DIR+"treehouse_oak.tscn")
	export_model(assembly,MODEL_DIR+"treehouse_oak.glb")
	assembly.free()
	instance_asset(garden,MODEL_DIR+"treehouse_oak.tscn","Treehouse",Vector3.ZERO)
	garden.set_meta("yard_dimensions_m",Vector2(32,39))
	# Wide garden perimeter, well outside the crown. The house-facing side stays open.
	for i in range(20):
		var fence := instance_asset(garden,"res://neighborhood_assets/models/fence_picket.glb","WestBoundary%02d"%i,Vector3(-19,0,-17+i*1.8),4.5)
		fence.rotation.y = PI/2
	for i in range(17):
		for z in [-18.5,18.5]:
			# Leave a generous entrance on the front edge.
			if z > 0 and i >= 8 and i <= 10: continue
			instance_asset(garden,"res://neighborhood_assets/models/fence_picket.glb","GardenBoundary",Vector3(-18+i*1.8,0,z),4.5)
	for i in range(13):
		var t: float = float(i)/12
		var stone := instance_asset(garden,"res://neighborhood_assets/models/stepping_stone.glb","GardenStep%02d"%i,Vector3(-.9+10.9*t,.035,7.9-5*t+sin(t*PI)*1.8),2.8)
		stone.rotation.y = i*.63
	for at in [Vector3(-15,0,13),Vector3(-14,0,-13),Vector3(9,0,14),Vector3(-11,0,16),Vector3(5,0,-16)]:
		instance_asset(garden,"res://neighborhood_assets/models/shrub_round.glb","BoundaryShrub",at,8)
	instance_asset(garden,"res://neighborhood_assets/recreation_models/picnic_table.glb","BackyardPicnic",Vector3(8.5,0,8.8),1)
	for at in [Vector3(-6,.02,5),Vector3(5,.02,7),Vector3(-10,.02,-10)]:
		instance_asset(garden,"res://neighborhood_assets/models/flowerbed.glb","GardenFlowers",at,5)
	var cameras := group(scene,"Views")
	var camera := Camera3D.new()
	camera.name = "BackyardCamera"
	cameras.add_child(camera)
	camera.position = Vector3(-9,9.8,24)
	camera.transform = Transform3D(Basis.looking_at(Vector3(0,9,-1)-camera.position),camera.position)
	camera.fov = 60
	camera.near = .1
	camera.far = 4028.7
	camera.current = true
	var aerial := Camera3D.new()
	aerial.name = "NeighborhoodOverview"
	cameras.add_child(aerial)
	aerial.position = Vector3(-43,51,54)
	aerial.transform = Transform3D(Basis.looking_at(Vector3(10,0,-4)-aerial.position),aerial.position)
	aerial.fov = 58
	aerial.far = 4028.7
	save_scene(scene,DEST)
	var report := {"source":SOURCE,"destination":DEST,"copied_categories":counts,"removed_for_expanded_yard":removed,"treehouse_dimensions_m":{"upper_deck_height":6.12,"lower_deck_height":3.2,"cabin_width":5.71,"roof_peak":12.5,"tree_height_approx":22.5,"upper_deck_size":Vector2(12.7,10.4),"ladder_flights":2,"yard":Vector2(32,39)},"lighting":"WorldEnvironment and Sun duplicated directly without property changes","original_house":"House_West_03","original_tree_position":ORIGIN}
	var file := FileAccess.open("res://treehouse_assets/source/build_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("TREEHOUSE BUILT: ",counts)
	scene.free()
	source.free()
	quit()
