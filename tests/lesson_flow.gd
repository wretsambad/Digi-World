extends Node
## Plays Protect Your Base from start to finish on its own and checks it.
## Headless: godot --headless --path . res://tests/lesson_flow.tscn
## With screenshots: godot --path . res://tests/lesson_flow.tscn -- --capture

const GAME := preload("res://scenes/monitor_game/monitor_game.tscn")
const AUTOPLAY := preload("res://tests/lesson_autoplay.gd")

var game: ProtectYourBase
var failures: Array[String] = []
var capture := false
var clock := 0.0
var shot_clock := 0.0
var shots := 0
var counts := {"mistake": 0, "repaired": 0, "completed": 0}
var pranks_seen: Dictionary = {}
var done := false
var finale_checked := false
var dialogue_checked := false
var customize_checked := false
var clear_scene_checked := false
var clear_time := 0.0
var floor_boxes: Array[AABB] = []
var floor_clipped := false


func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	check_data()
	PlayerProfile.reset()
	Engine.time_scale = 1.0 if capture else 6.0
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work/review"))
	game = GAME.instantiate()
	add_child(game)
	for deck_name: String in ["UpperWraparound", "LowerLookout"]:
		for plank in game.base.oak.get_node("BranchPlatforms/" + deck_name).get_children():
			if plank is MeshInstance3D and (plank.name.begins_with("RingPlank") or plank.name == "UpperStairLanding"):
				floor_boxes.append(plank.global_transform * plank.get_aabb())
	var stairs := game.base.oak.get_node("BranchPlatforms/LandingToTopDeck")
	var upper := game.base.oak.get_node("BranchPlatforms/UpperWraparound")
	verify(is_equal_approx(float(upper.get_meta("front_extension")), 0.9), "Upper deck was not widened")
	var foot: Vector3 = stairs.get_meta("foot")
	var landing: Vector3 = stairs.get_meta("landing")
	verify(foot.z - landing.z >= 2.0, "Upper ladder must have a usable incline")
	var stair_mouth := AABB(Vector3(1.55, 3.3, 7.9), Vector3(1.5, 1.3, 0.6))
	for railing in game.base.oak.get_node("BranchPlatforms/LowerLookout").get_children():
		if railing is MeshInstance3D and (railing.name.begins_with("PerimeterRail") or railing.name.begins_with("RailingPost")):
			verify(not stair_mouth.intersects(railing.global_transform * railing.get_aabb()), "Lower railing blocks upper ladder: " + str(railing.name))
	game.machine.mistake_made.connect(func(step: int, option: int, _rule: String) -> void:
		counts.mistake += 1
		pranks_seen[String(game.data.steps[step].options[option].prank)] = true)
	game.machine.repaired.connect(func(_step: int) -> void:
		counts.repaired += 1
		await get_tree().create_timer(3.0).timeout
		verify_profile("after repair"))
	game.machine.step_completed.connect(func(_step: int) -> void: counts.completed += 1)
	game.leave_requested.connect(finish)
	await get_tree().create_timer(0.5).timeout
	game.begin()
	await get_tree().create_timer(3.0).timeout
	verify(game.ui.title_card.visible, "Welcome must stay until Play is pressed")
	verify(not game.ui.play_button.disabled, "Welcome Play button must be enabled")
	verify(not game.ui.dialogue.visible, "Intro started before Play was pressed")
	verify(game.ui.frost.visible and game.ui.frost_amount > 0.95, "Welcome must use the opening blur")
	var before := clock
	var original := game.glitch.position
	await game.glitch.run_to(original + Vector3(6, 0, 0), 3.0)
	verify(clock - before < 2.0, "Glitch still pauses between running hops")
	game.glitch.position = original
	add_child(AUTOPLAY.new(game))


func verify(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func check_data() -> void:
	var data := ProtectYourBase.load_data()
	verify(data.steps.size() == 3, "Expected 3 steps")
	var pranks: Dictionary = {}
	for step: Dictionary in data.steps:
		verify(step.options.size() == 4, "Step %s must have exactly 4 options" % step.id)
		var correct := 0
		for option: Dictionary in step.options:
			var result := PasswordRules.check(String(option.text), step.required_rules)
			verify(bool(option.correct) == bool(result.ok), "Data says '%s' correct=%s but PasswordRules says %s (%s)" % [option.text, option.correct, result.ok, result.failed_rule])
			if bool(option.correct):
				correct += 1
			else:
				verify(String(option.get("prank", "")) in ["flag_swap", "paint", "fold_wall", "steal_hat"], "Unknown prank for " + str(option.text))
				verify(String(option.get("tip", "")) != "", "Missing tip for " + str(option.text))
				pranks[option.prank] = true
		verify(correct >= 1, "Step %s needs a correct option" % step.id)
	verify(pranks.size() >= 3, "Need at least 3 different pranks")
	verify(PasswordRules.strength("TreeTopCastle#47") == 4, "Final password should be super strong")
	verify(PasswordRules.check("pip", ["length"]).failed_rule == "length", "Short password should fail length")
	verify(PasswordRules.check("password", ["common"]).failed_rule == "common", "Famous password should fail")
	verify(PasswordRules.check("sam2015", ["personal"]).failed_rule == "personal", "Name+year should fail personal")
	print("DATA CHECK ", "PASS" if failures.is_empty() else "FAIL")


func verify_profile(moment: String) -> void:
	var base := game.base
	verify(base.house_material.albedo_color.is_equal_approx(PlayerProfile.house()), "House colour not restored " + moment)
	for mesh: MeshInstance3D in base.oak.get_node("Cabin/CabinCladding").find_children("*", "MeshInstance3D", true, false):
		verify(mesh.get_active_material(0) == base.house_material, "Visible cabin board is not painted: " + str(mesh.name))
	var deck: Node3D = base.oak.get_node("BranchPlatforms/UpperWraparound")
	verify(absf(game.pip.position.y - float(deck.get_meta("surface_height"))) < 0.05, "Pip must stand on the cabin deck")
	verify(base.flag_material.get_shader_parameter("design") == FlagArt.texture(PlayerProfile.flag_design, PlayerProfile.flag()), "Flag not restored " + moment)
	verify(game.pip.has_hat(), "Pip's hat not returned " + moment)
	var outfit: Vector3 = game.pip.outfit_material.get_shader_parameter("outfit")
	var want := PlayerProfile.pip()
	verify(outfit.is_equal_approx(Vector3(want.r, want.g, want.b)), "Pip colour wrong " + moment)


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
	if game.glitch.visible and not floor_clipped:
		var body: AABB = game.glitch.global_transform * game.glitch.pixels.transform * AABB(Vector3(-0.375, 0.0, -0.1125), Vector3(0.75, 0.825, 0.27))
		for floor_box in floor_boxes:
			if body.intersects(floor_box):
				floor_clipped = true
				verify(false, "Glitch intersects deck floor at " + str(game.glitch.position))
				break
	var ui := game.ui
	var reading := ui.title_card.visible or ui.question.visible or ui.finale_card.visible or (ui.dialogue.visible and ui._dialogue_frosted)
	clear_time = 0.0 if reading else clear_time + delta
	if clear_time > 0.5:
		verify(ui.frost_amount < 0.05, "Blur remained during an in-world scene")
		clear_scene_checked = true
	if not dialogue_checked and ui.dialogue.visible and not ui._dialogue_frosted and clear_time > 0.5:
		dialogue_checked = true
		verify(ui.dialogue.size.y < 300, "Short Pip dialogue has excessive empty space")
	if not customize_checked and ui.customize.visible and ui.customize.modulate.a > 0.95 and clear_time > 0.5:
		customize_checked = true
		verify(ui.customize.size.y < ui.root.size.y - 50, "Customization panel should fit its contents")
	if not finale_checked and game.ui.finale_card.visible and game.ui.finale_card.modulate.a > 0.95:
		finale_checked = true
		var card := game.ui.finale_card
		verify(card.size.x >= 660, "Finale card collapsed horizontally")
		verify(game.ui.root.get_global_rect().encloses(card.get_global_rect()), "Finale card extends off-screen")
		for text: Label in card.find_children("*", "Label", true, false):
			verify(text.size.y < 90, "Finale text wraps into a narrow column: " + text.text)
			verify(card.get_global_rect().encloses(text.get_global_rect()), "Finale text extends outside card: " + text.text)
	if clock > 900.0:
		verify(false, "Lesson did not finish in time (state %s)" % LessonStateMachine.state_name(game.machine.state))
		finish()
		return
	if capture:
		shot_clock += delta
		if shot_clock >= 0.75:
			shot_clock = 0.0
			shots += 1
			var image := get_viewport().get_texture().get_image()
			image.save_png("res://work/review/beat_%03d_%s.png" % [shots, LessonStateMachine.state_name(game.machine.state)])


func finish() -> void:
	if done:
		return
	done = true
	verify(game.machine.state == LessonStateMachine.State.FINALE, "Did not reach the finale")
	verify(counts.completed == 3, "Expected 3 completed steps, got %d" % counts.completed)
	verify(counts.mistake == 4, "Expected 4 mistakes, got %d" % counts.mistake)
	verify(counts.repaired == 3, "Expected 3 repairs (one per step with mistakes), got %d" % counts.repaired)
	verify(pranks_seen.size() == 4, "Expected all 4 pranks, saw %s" % str(pranks_seen.keys()))
	verify(game.base.defense_level == 3, "Defenses should reach level 3")
	verify(not game.base.original_railings.is_empty(), "Original deck railing was not replaced")
	for original in game.base.original_railings:
		verify(not original.visible, "Original railing overlaps its replacement: " + str(original.name))
	verify(game.base.pickets[0].get_active_material(0).resource_name == "Autumn_b3804cfftrue", "Upgraded posts lost their authored timber material")
	verify(game.base.rails[0].get_active_material(0).resource_name == "Autumn_cf9f63fftrue", "Upgraded rails lost their authored timber material")
	verify(game.base.gate.position.is_equal_approx(TreehouseBase.GATE_CENTER), "Gate is not attached to the upper deck")
	verify(game.base.cabin_upgrades.size() >= 13, "Cabin door and window defenses are missing")
	verify(game.base.branch_guards.size() == 3, "Every climbing branch needs a barrier")
	for guard in game.base.branch_guards:
		var blocker: MeshInstance3D = guard.get_node("ClimbBlocker")
		verify((blocker.mesh as CylinderMesh).top_radius > 1.0, "Branch barrier is only a thin sleeve")
		var bounds: AABB = blocker.global_transform * blocker.get_aabb()
		verify(bounds.size.z > 4.35, "Branch shield must be broader than the old shield")
		var jump_top: float = guard.global_position.y + ProtectYourBase.FENCE_JUMP_HEIGHT + GlitchActor.PIXEL * GlitchActor.ART.size()
		verify(bounds.end.y > jump_top + 0.5, "The fence jump should not clear the branch shield")
		for part: MeshInstance3D in guard.get_children():
			var part_bounds: AABB = part.global_transform * part.get_aabb()
			verify(part_bounds.position.y > 0.1, "Branch shield penetrates the ground")
			for floor_box in floor_boxes:
				verify(not part_bounds.intersects(floor_box), "Branch shield penetrates a deck floor")
		verify(guard.has_node("OverhangingLip"), "Branch barrier needs an overhanging lip")
	verify(dialogue_checked and customize_checked and clear_scene_checked, "Clear scene and compact dialogue checks were not exercised")
	verify(GameState.is_complete(GameState.PROTECT_YOUR_BASE), "Lesson not marked complete")
	verify(game.password == "TreeTopCastle#47", "Unexpected final password " + game.password)
	verify(finale_checked, "Finale layout was not checked")
	for key: String in AUTOPLAY.CUSTOM:
		verify(int(PlayerProfile.get(key)) == AUTOPLAY.CUSTOM[key], "Profile choice lost: " + key)
	verify_profile("at the finale")
	print("LESSON FLOW ", "PASS" if failures.is_empty() else "FAIL ", failures, " in %.1fs game time" % clock)
	Engine.time_scale = 1.0
	get_tree().quit(0 if failures.is_empty() else 1)
