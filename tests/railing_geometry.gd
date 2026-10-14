extends SceneTree
func _init():
 var scene = load("res://treehouse_assets/autumn/models/treehouse_oak.tscn").instantiate()
 var failures = 0
 var count = 0
 for deck_name in ["LowerLookout", "UpperWraparound"]:
  var deck = scene.get_node("BranchPlatforms/" + deck_name)
  var posts: Array[Vector3] = []
  for n in deck.get_children():
   if str(n.name).begins_with("RailingPost") or str(n.name).begins_with("UpperLadderOpening"):
    posts.append(n.position)
  for n in deck.get_children():
   if not str(n.name).begins_with("PerimeterRail"): continue
   count += 1
   for sign_value in [-1, 1]:
    var endpoint: Vector3 = n.position + n.basis.y * n.mesh.size.y * 0.5 * sign_value
    var nearest = INF
    for p in posts:
     nearest = min(nearest, Vector2(endpoint.x, endpoint.z).distance_to(Vector2(p.x,p.z)))
    if nearest > 0.09:
     failures += 1
     print("DISCONNECTED ", deck_name, "/", n.name, " endpoint ", endpoint, " gap ", nearest)
 print("Rail endpoints checked: ", count * 2, "; disconnected: ", failures)
 scene.free()
 quit(1 if failures else 0)
