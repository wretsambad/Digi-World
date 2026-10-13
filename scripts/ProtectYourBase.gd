class_name ProtectYourBase
extends Node3D
## Lesson 1: Protect Your Base. Runs inside the bedroom computer's screen.
## Drives the story beat by beat, cutting between camera shots, and reports
## progress through LessonStateMachine signals.

signal leave_requested
signal lesson_completed

const DATA_PATH := "res://data/protect_your_base.json"
const TREEHOUSE := preload("res://scenes/treehouse/treehouse.tscn")
const PIP := preload("res://scenes/pip/pip.tscn")
const GLITCH := preload("res://scenes/glitch/glitch.tscn")
const LESSON_UI := preload("res://ui/LessonUI.gd")

## Named camera shots: [eye, target, fov].
const SHOTS: Dictionary = {
	"title": [Vector3(-16, 15, 31), Vector3(0, 8, 0), 48.0],
	"establish": [Vector3(-9, 9.8, 24), Vector3(0, 6.5, 2), 55.0],
	"customize": [Vector3(-12.5, 9, 20), Vector3(2.6, 7.6, 1.5), 50.0],
	"question": [Vector3(-7.5, 7.5, 21), Vector3(0.5, 5.5, 3), 52.0],
	"ladder": [Vector3(3.2, 2.6, 14.5), Vector3(-0.9, 1.9, 6.8), 38.0],
	"gate": [Vector3(1.8, 1.9, 14.8), Vector3(-0.9, 1.0, 8.8), 40.0],
	"fence_wide": [Vector3(5.5, 5.0, 17.5), Vector3(-0.9, 1.3, 7.4), 44.0],
	"branches": [Vector3(-14.5, 3.4, 11.0), Vector3(-5.6, 2.4, 1.8), 44.0],
	"runaway": [Vector3(-15.5, 1.6, 15.0), Vector3(-5.0, 0.5, 12.5), 46.0],
	"roof": [Vector3(0.8, 13.6, 4.4), Vector3(0.2, 13.1, -0.3), 42.0],
	"cabin": [Vector3(1.0, 8.6, 13.5), Vector3(0, 8.4, 2.5), 44.0],
	"repair": [Vector3(-4.5, 8.5, 19), Vector3(-0.5, 7.0, 2.5), 50.0],
}

var data: Dictionary
var machine: LessonStateMachine
var base: TreehouseBase
var pip: PipActor
var glitch: GlitchActor
var camera: CameraDirector
var ui: LessonUI
var password: String = ""
var running: bool = false


func _ready() -> void:
	data = load_data()
	machine = LessonStateMachine.new()
	machine.name = "LessonStateMachine"
	add_child(machine)
	base = TREEHOUSE.instantiate()
	add_child(base)
	pip = PIP.instantiate()
	add_child(pip)
	pip.position = TreehouseBase.PIP_SPOT
	pip.rotation.y = -0.45
	pip.scale = Vector3.ONE * 0.95
	glitch = GLITCH.instantiate()
	add_child(glitch)
	glitch.position = TreehouseBase.HIDEOUT
	glitch.hide()
	camera = CameraDirector.new()
	camera.name = "LessonCamera"
	add_child(camera)
	camera.make_current()
	shot("title")
	ui = LESSON_UI.new()
	add_child(ui)
	PlayerProfile.changed.connect(_on_profile_changed)
	if get_tree().current_scene == self:
		# Run directly for development: skip the desktop and start.
		ui.show_title()
		await get_tree().create_timer(1.2).timeout
		begin()


static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	assert(parsed is Dictionary, "Could not read " + DATA_PATH)
	var lesson: Dictionary = parsed
	for step: Dictionary in lesson.steps:
		assert(step.options.size() == 4, "Each step needs exactly 4 options: " + str(step.id))
		assert(step.options.any(func(o: Dictionary) -> bool: return bool(o.correct)), "Each step needs a correct option: " + str(step.id))
	return lesson


# ---------------------------------------------------------------- camera

func shot(name: String) -> void:
	var s: Array = SHOTS[name]
	camera.cut(s[0], s[1], s[2])


func glide(name: String, seconds: float = 1.4) -> void:
	var s: Array = SHOTS[name]
	await camera.glide(s[0], s[1], s[2], seconds)


## A close-up on Pip's face, from a little to the side.
func glide_pip(seconds: float = 1.1, side: float = 1.0, distance: float = 3.4) -> void:
	var face := pip.global_position + Vector3(0, 1.2, 0)
	var facing := pip.global_basis.z.normalized()
	var eye := face + facing * distance + facing.cross(Vector3.UP) * (1.1 * side) + Vector3.UP * 0.35
	await camera.glide(eye, face, 30.0, seconds)


func glide_glitch(seconds: float = 0.9, distance: float = 2.6) -> void:
	var at := glitch.global_position + Vector3(0, 0.35, 0)
	await camera.glide(at + Vector3(1.0, 0.6, distance), at, 34.0, seconds)


# ---------------------------------------------------------------- monitor hooks

## The computer desktop shown on the bedroom monitor before the game opens.
func show_desktop() -> void:
	ui.desktop.show()
	ui.desktop.modulate.a = 1.0
	shot("title")


func open_from_desktop(click_time: float) -> void:
	ui.desktop.play_open(click_time)
	await ui.desktop.opened
	ui.show_title()


# ---------------------------------------------------------------- flow

func begin() -> void:
	if running:
		return
	running = true
	GameState.start_lesson(GameState.PROTECT_YOUR_BASE)
	await _intro()
	machine.advance()
	await _customize()
	machine.advance()
	await _glitch_arrives()
	for i in data.steps.size():
		await _run_step(i)
		machine.advance()
	await _finale()


func _intro() -> void:
	ui.hide_title()
	pip.set_mood("Wave")
	await glide("establish", 3.0)
	await glide_pip(1.6, -1.0)
	for line: String in data.lines.intro:
		await ui.say(line, "PIP", "Next", "", false)
	pip.set_mood("Happy")


func _customize() -> void:
	glide("customize", 1.6)
	await ui.show_customize()
	pip.set_mood("Cheer")
	base.sparkle_at(TreehouseBase.FLAG_TOP + Vector3(0.6, -0.4, 0))
	AudioManager.play("success")
	glide_pip(1.2)
	await ui.caption(String(data.lines.customize_done), 0.6)
	pip.set_mood("Idle")


func _glitch_arrives() -> void:
	glitch.position = TreehouseBase.HIDEOUT
	glitch.show()
	AudioManager.play("glitch")
	await glide_glitch(1.4, 3.2)
	camera.follow(glitch, Vector3(1.8, 1.0, 2.8), Vector3(0, 0.35, 0), 40.0)
	await glitch.run_to(TreehouseBase.LADDER_FOOT + Vector3(0, 0, 0.35), 3.2)
	glide("ladder", 1.0)
	var steps := base.ladder_climb_points()
	await glitch.climb(steps.slice(0, 5), 0.3)
	pip.set_mood("Worried")
	await glide_pip(0.9)
	await ui.caption(String(data.lines.glitch_spotted), 0.8)
	await glide_glitch(0.8, 2.2)
	await get_tree().create_timer(0.6).timeout
	await ui.say(String(data.lines.alert), "PIP", "Let's go!", "", true)
	# The Glitch scurries back to its hiding spot to plan its next move.
	await glitch.hop_to(TreehouseBase.LADDER_FOOT + Vector3(0.6, 0, 1.0), 0.5, 0.6)
	glide("question", 1.3)
	await glitch.run_to(TreehouseBase.HIDEOUT, 4.0)
	pip.set_mood("Idle")
	ui.show_hud()


func _run_step(index: int) -> void:
	var step: Dictionary = data.steps[index]
	var crossed: Array[int] = []
	var heading := "STEP %d OF 3   %s" % [index + 1, String(step.rule).to_upper()]
	glide("question", 1.2)
	var choice := -1
	while true:
		choice = await ui.ask(step, crossed, heading)
		var option: Dictionary = step.options[choice]
		var result := PasswordRules.check(String(option.text), step.required_rules)
		var correct := bool(option.correct)
		if correct != bool(result.ok):
			push_warning("Lesson data and PasswordRules disagree about '%s'" % option.text)
		machine.report_choice(choice, correct, String(result.failed_rule))
		if correct:
			break
		crossed.append(choice)
		await _mistake(option)
		heading = "FIX IT!   PICK A BETTER PASSWORD"
	if not crossed.is_empty() or base.is_damaged() or not pip.has_hat():
		await _repair()
	var picked: Dictionary = step.options[choice]
	password = String(picked.text)
	AudioManager.play("success")
	await ui.set_password(password)
	await _build_defense(index)
	pip.set_mood("Cheer")
	await glide_pip(0.9, -1.0)
	ui.caption(String(step.cheer), 1.2)
	await get_tree().create_timer(2.2).timeout
	pip.set_mood("Idle")
	await _glitch_event(index)


func _build_defense(index: int) -> void:
	match index:
		0: await glide("gate", 1.2)
		1: await glide("fence_wide", 1.2)
		2: await glide("branches", 1.2)
	await base.build_level(index + 1)
	camera.shake(0.08)
	await get_tree().create_timer(0.5).timeout


# ---------------------------------------------------------------- mistakes

func _mistake(option: Dictionary) -> void:
	AudioManager.play("mistake")
	match String(option.get("prank", "paint")):
		"flag_swap": await _prank_flag()
		"paint": await _prank_paint()
		"fold_wall": await _prank_wall()
		"steal_hat": await _prank_hat()
		_: await _prank_paint()
	pip.set_mood("Sad")
	await glide_pip(0.9)
	await get_tree().create_timer(1.0).timeout
	await ui.say(String(option.explanation), "OOPS!", "Fix it!", String(option.get("tip", "")), true)


func _prank_flag() -> void:
	glide("roof", 1.0)
	await glitch.blink_to(Vector3(-0.05, 12.62, 0.7))
	glitch.face(TreehouseBase.FLAG_TOP)
	await glitch.hop_to(Vector3(0.0, 12.62, 0.1), 0.35, 0.5)
	base.prank_flag()
	AudioManager.play("poof")
	camera.shake(0.05)
	await glitch.dance(1.4)


func _prank_paint() -> void:
	glide("cabin", 1.0)
	await glitch.blink_to(TreehouseBase.PAINT_SPOT + Vector3(1.0, 0, 0.8))
	glitch.face(Vector3(0, 8, 0))
	await glitch.hop_to(TreehouseBase.PAINT_SPOT, 0.35, 0.6)
	base.prank_paint()
	camera.shake(0.06)
	await glitch.dance(1.4)


func _prank_wall() -> void:
	glide("gate", 1.0)
	base.make_plastic_wall()
	await get_tree().create_timer(0.4).timeout
	var wall_z := base.plastic_wall.position.z
	await glitch.blink_to(Vector3(TreehouseBase.LADDER_FOOT.x, 0, wall_z + 1.4))
	glitch.face(TreehouseBase.LADDER_FOOT)
	await glitch.hop_to(Vector3(TreehouseBase.LADDER_FOOT.x, 0, wall_z + 0.45), 0.3, 0.15)
	await base.fold_plastic_wall()
	await glitch.hop_to(Vector3(TreehouseBase.LADDER_FOOT.x, 0.05, wall_z - 0.3), 0.4, 0.4)
	await glitch.dance(1.0)


func _prank_hat() -> void:
	await glide_pip(0.9, 1.0, 4.2)
	await glitch.blink_to(pip.global_position + Vector3(1.0, 0, 0.5))
	glitch.face(pip.global_position)
	pip.set_mood("Startled")
	await glitch.hop_to(pip.global_position + Vector3(0.3, 1.0, 0.3), 0.35, 0.7)
	glitch.wear(pip.hat)
	AudioManager.play("poof")
	await glitch.hop_to(pip.global_position + Vector3(1.1, 0, 0.6), 0.4, 0.5)
	await glitch.dance(1.2)


func _repair() -> void:
	glide("repair", 1.1)
	ui.caption("Fixed! Your base is back to normal.", 1.0)
	AudioManager.play("repair")
	if not pip.has_hat():
		pip.put_hat_on()
	await glitch.blink_to(TreehouseBase.HIDEOUT)
	await base.repair()
	pip.apply_profile()
	pip.set_mood("Happy")
	await get_tree().create_timer(1.2).timeout


# ---------------------------------------------------------------- glitch events

func _glitch_event(index: int) -> void:
	match index:
		0: await _event_jumps_fence()
		1: await _event_climbs_branches()
		2: await _event_runs_away()


func _event_jumps_fence() -> void:
	glide("fence_wide", 1.0)
	glitch.position = TreehouseBase.HIDEOUT
	await glitch.run_to(TreehouseBase.GATE_FRONT, 4.0)
	await glitch.bonk(Vector3(0, 0, -1))
	camera.follow(glitch, Vector3(2.0, 1.2, 3.0), Vector3(0, 0.4, 0), 42.0)
	var outside := Vector3(TreehouseBase.FENCE_LEFT + 0.7, 0, TreehouseBase.FENCE_Z + 0.7)
	await glitch.run_to(outside, 4.0)
	# A big hop clean over the short fence.
	await glitch.hop_to(Vector3(outside.x, 0, TreehouseBase.FENCE_Z - 0.9), 0.7, 1.7)
	await glitch.run_to(TreehouseBase.LADDER_FOOT + Vector3(0, 0, 0.3), 4.0)
	glide("ladder", 0.8)
	await glitch.climb(base.ladder_climb_points().slice(0, 4), 0.28)
	pip.set_mood("Worried")
	await glide_pip(0.8)
	await ui.say(String(data.steps[0].glitch_line), "PIP", "Next", "", false)
	await glitch.blink_to(TreehouseBase.HIDEOUT)
	pip.set_mood("Idle")


func _event_climbs_branches() -> void:
	glide("fence_wide", 1.0)
	var outside := Vector3(TreehouseBase.FENCE_LEFT + 0.7, 0, TreehouseBase.FENCE_Z + 0.75)
	await glitch.run_to(outside, 4.0)
	# Tries the same trick, but the fence is far too tall now.
	await glitch.hop_to(outside + Vector3(0, 1.1, -0.45), 0.35, 0.3)
	await glitch.bonk(Vector3(0, 0, -1))
	await glitch.hop_to(outside + Vector3(0, 0, 0.3), 0.3, 0.1)
	await glitch.dance(0.6)
	camera.follow(glitch, Vector3(-2.2, 1.3, 3.2), Vector3(0, 0.4, 0), 42.0)
	await glitch.run_to(TreehouseBase.BRANCH_FOOT, 4.5)
	glide("branches", 0.9)
	await glitch.climb(base.branch_climb_points(), 0.42)
	pip.set_mood("Worried")
	await glide_pip(0.8, 1.0)
	await ui.say(String(data.steps[1].glitch_line), "PIP", "Next", "", false)
	await glitch.blink_to(TreehouseBase.HIDEOUT)
	pip.set_mood("Idle")


func _event_runs_away() -> void:
	glide("branches", 1.0)
	await glitch.run_to(TreehouseBase.BRANCH_FOOT, 4.5)
	var first: Vector3 = base.branch_climb_points()[0]
	# Slips straight off the smooth metal.
	await glitch.hop_to(first, 0.35, 0.3)
	AudioManager.play("whoosh")
	await glitch.hop_to(TreehouseBase.BRANCH_FOOT + Vector3(-0.4, 0, 0.3), 0.3, 0.1)
	await glitch.bonk(Vector3(1, 0, -1))
	glide("gate", 1.0)
	await glitch.run_to(TreehouseBase.GATE_FRONT + Vector3(0, 0, 0.6), 5.0)
	await glitch.bonk(Vector3(0, 0, -1))
	# BOING: bounced right off the metal gate.
	camera.shake(0.12)
	AudioManager.play("boing")
	await glitch.hop_to(TreehouseBase.GATE_FRONT + Vector3(0.8, 0, 4.0), 0.7, 2.2)
	glide("runaway", 1.0)
	await glitch.run_to(Vector3(-12.0, 0, 12.2), 6.0)
	await glitch.vanish()


func _finale() -> void:
	pip.set_mood("Cheer")
	base.set_flag_wave(1.8, 7.0)
	base.sparkle_at(TreehouseBase.FLAG_TOP + Vector3(0.6, -0.4, 0))
	AudioManager.play("success")
	await glide_pip(1.2)
	await ui.caption(String(data.lines.finale), 0.6)
	await camera.glide(Vector3(-12, 12, 22), Vector3(0, 7, 1), 50.0, 1.8)
	camera.orbit(Vector3(0, 7.0, 1.0), 23.0, 6.5, 6.0, 50.0)
	ui.hide_hud()
	await ui.show_finale(data.summary, password)
	GameState.finish_lesson(GameState.PROTECT_YOUR_BASE)
	lesson_completed.emit()
	leave_requested.emit()


func _on_profile_changed(_key: String) -> void:
	pip.apply_profile()
	if machine.state == LessonStateMachine.State.CUSTOMIZE:
		pip.set_mood("Happy")
		pip.flash()
