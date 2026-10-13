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


func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	check_data()
	PlayerProfile.reset()
	Engine.time_scale = 1.0 if capture else 6.0
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work/review"))
	game = GAME.instantiate()
	add_child(game)
	add_child(AUTOPLAY.new(game))
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
	verify(base.flag_material.get_shader_parameter("design") == FlagArt.texture(PlayerProfile.flag_design, PlayerProfile.flag()), "Flag not restored " + moment)
	verify(game.pip.has_hat(), "Pip's hat not returned " + moment)
	var outfit: Vector3 = game.pip.outfit_material.get_shader_parameter("outfit")
	var want := PlayerProfile.pip()
	verify(outfit.is_equal_approx(Vector3(want.r, want.g, want.b)), "Pip colour wrong " + moment)


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
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
	verify(GameState.is_complete(GameState.PROTECT_YOUR_BASE), "Lesson not marked complete")
	verify(game.password == "TreeTopCastle#47", "Unexpected final password " + game.password)
	for key: String in AUTOPLAY.CUSTOM:
		verify(int(PlayerProfile.get(key)) == AUTOPLAY.CUSTOM[key], "Profile choice lost: " + key)
	verify_profile("at the finale")
	print("LESSON FLOW ", "PASS" if failures.is_empty() else "FAIL ", failures, " in %.1fs game time" % clock)
	Engine.time_scale = 1.0
	get_tree().quit(0 if failures.is_empty() else 1)
