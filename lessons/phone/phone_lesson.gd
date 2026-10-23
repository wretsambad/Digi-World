extends Node3D
## The Glitch's Last Trick: the phone lesson. The Digi-World party in Willow
## Park has been switched off, and each round the Glitch sends one trick to the
## player's phone. Catching a trick brings back a piece of the party (lights,
## music, decorations, then the celebration) and unmasks more of the Glitch.
## Falling for one glitches that piece and gives the Glitch a point; the player
## rewinds and tries again. Rounds caught first try decide the ending.

signal lesson_completed(score: int)

const DATA := preload("res://lessons/phone/round_data.gd")
const LessonExit := preload("res://lessons/phone/lesson_exit.gd")
## Camera shots, as [from, to] in the party's own space, so moving the Party
## node moves every shot with it. Targets sit right of centre to leave the
## party clear of the phone on the right of the screen.
const VIEWS := {
	"arrive": [Vector3(8.0, 6.5, 18.0), Vector3(3.5, 1.0, -1.5)],
	"party": [Vector3(3.3, 2.4, 7.8), Vector3(2.0, 1.15, -2.0)],
	"speaker": [Vector3(0.2, 1.6, 3.4), Vector3(-1.7, 0.85, -1.9)],
	"balloons": [Vector3(5.2, 1.6, 6.4), Vector3(4.4, 1.55, 0.6)],
	"finale": [Vector3(2.6, 1.7, 5.8), Vector3(1.9, 0.95, -0.6)],
}
## How many rows of the Glitch's pixel art each caught trick reveals.
const REVEAL_ROWS := [3, 6, 9, 11]
const REVEAL_CAPTIONS := ["Pointy ears...?", "Big googly eyes...", "A toothy grin...", "THE GLITCH!"]

@export var title_screen := true

var first_try: Array[bool] = [true, true, true, true]
var round_index := -1
var glitch_points := 0
var finished := false

@onready var party: Node3D = $Party
@onready var camera: Camera3D = $Camera3D
@onready var pip: Node3D = $Pip
@onready var glitch: Node3D = $Glitch
@onready var ui: Control = $UI/PartyUI
@onready var phone: Control = $UI/Phone
var pause_menu: PauseMenu


func _ready() -> void:
	if GameState.current_lesson != LessonExit.LESSON_ID:
		GameState.start_lesson(LessonExit.LESSON_ID)
	ui.phone = phone
	phone.hint.connect(ui.tip)
	phone.chat_sent.connect(_on_chat_sent)
	ui.leave_pressed.connect(leave)
	ui.replay_pressed.connect(func() -> void: get_tree().reload_current_scene())
	pause_menu = PauseMenu.new()
	$UI.add_child(pause_menu)
	pause_menu.quit_button.text = "Back to my room"
	pause_menu.quit_requested.connect(leave)
	pip.hide()
	glitch.hide()
	camera.global_transform = _view("arrive")
	phone.modulate.a = 0.0
	run()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		pause_menu.open()
		get_viewport().set_input_as_handled()


func run() -> void:
	if title_screen:
		await ui.show_title()
	else:
		ui.title_card.hide()
	_slide_phone_in()
	await _glide("party", 2.6)
	for line: Array in DATA.OPENING:
		await ui.say(line[0], line[1])
	for i in DATA.ROUNDS.size():
		await play_round(i)
	await _finale()


func play_round(index: int) -> void:
	round_index = index
	var round_: Dictionary = DATA.ROUNDS[index]
	for line: Array in round_.intro:
		await ui.say(line[0], line[1])
	phone.show_notification(round_)
	ui.tip("Your phone is buzzing! Tap the notification to open it." if index == 0 else "Another one! Tap the notification to open it.")
	await phone.opened
	phone.open_case(index)
	while true:
		var outcome: Array = await phone.case_ended
		if not bool(outcome[0]):
			break
		first_try[index] = false
		await _tricked(index, String(outcome[1]))
	ui.tip("Trick caught!")
	await get_tree().create_timer(1.1).timeout
	phone.go_lock()
	await _restore(index)
	for line: Array in round_.solved:
		await ui.say(line[0], line[1])


func score() -> int:
	return first_try.count(true)


# ------------------------------------------------------------------ tricks

func _tricked(index: int, why: String) -> void:
	glitch_points += 1
	var piece: String = DATA.ROUNDS[index].piece
	var glitched: Array[String] = _pieces_hit(piece)
	for target in glitched:
		party.set_piece(target, "glitched")
		ui.set_piece(target, "glitched")
	await _glitch_laughs(index)
	await ui.say("THE GLITCH", "Hee hee! Gotcha! That's %d point%s for me!" % [glitch_points, "" if glitch_points == 1 else "s"])
	await ui.say("PIP", why, "Rewind")
	for target in glitched:
		# Pieces caught in earlier rounds come back; this round's piece stays off.
		var restored := "on" if DATA.ROUNDS.slice(0, index).any(func(r: Dictionary) -> bool: return r.piece == target) else "off"
		party.set_piece(target, restored, false)
		ui.set_piece(target, restored)
	phone.rewind()
	ui.tip("Let's try that again. Take your time: real friends can wait.")


## A trick glitches this round's piece. The celebration has nothing to show
## yet, so a trick in the last round glitches the lights and music instead.
func _pieces_hit(piece: String) -> Array[String]:
	if piece == "celebration":
		return ["lights", "music"]
	return [piece]


## The Glitch pops out, a little bigger with every point, giggles and hides.
func _glitch_laughs(index: int) -> void:
	var spot: Vector3 = party.hideout(["speaker_peek", "speaker_peek", "balloons", "table"][index])
	glitch.scale = Vector3.ONE * (1.0 + 0.15 * glitch_points)
	glitch.global_position = spot
	glitch.show()
	glitch.face(camera.global_position)
	glitch.jitter_amount = 2.5
	AudioManager.play("glitch")
	await glitch.dance(1.0)
	glitch.hide()
	glitch.jitter_amount = 1.0


# ------------------------------------------------------------------ restoring the party

func _restore(index: int) -> void:
	var piece: String = DATA.ROUNDS[index].piece
	# Keep the card out of the way while the Glitch shows itself.
	ui.hide_story()
	match index:
		0:
			party.set_piece("lights", "on")
			AudioManager.play("repair")
			await _glide("speaker", 1.6)
			await _flicker_glitch()
		1:
			party.set_piece("music", "on")
			AudioManager.play("success")
			await _glide("speaker", 1.6)
			await _glitch_peeks()
		2:
			party.set_piece("decorations", "on")
			AudioManager.play("build")
			await _glide("balloons", 1.6)
			await _glitch_shadow()
		3:
			party.set_piece("celebration", "on")
			pip.set_mood("Cheer")
			AudioManager.play("success")
	ui.set_piece(piece, "on")
	ui.reveal_glitch(REVEAL_ROWS[index], REVEAL_CAPTIONS[index])
	if index < 3:
		_glide("party", 1.8)


## Round 1: just a flicker by the speaker, gone before you can be sure.
func _flicker_glitch() -> void:
	glitch.scale = Vector3.ONE
	glitch.global_position = party.hideout("speaker")
	glitch.face(camera.global_position)
	for i in 3:
		glitch.show()
		AudioManager.play("glitch")
		await get_tree().create_timer(0.09).timeout
		glitch.hide()
		await get_tree().create_timer(0.22).timeout


## Round 2: static, then two eyes peek round the speaker.
func _glitch_peeks() -> void:
	glitch.scale = Vector3.ONE
	var hide_spot: Vector3 = party.hideout("speaker")
	glitch.global_position = hide_spot
	glitch.jitter_amount = 3.0
	glitch.show()
	glitch.face(camera.global_position)
	await glitch.hop_to(party.hideout("speaker_peek"), 0.3, 0.12)
	await get_tree().create_timer(0.5).timeout
	await glitch.blink_to(hide_spot)
	glitch.hide()
	glitch.jitter_amount = 1.0


## Round 3: a shape bobbing among the balloons, then a poof.
func _glitch_shadow() -> void:
	glitch.scale = Vector3.ONE
	glitch.global_position = party.hideout("balloons")
	glitch.show()
	glitch.face(camera.global_position)
	await glitch.dance(0.8)
	await glitch.vanish()


# ------------------------------------------------------------------ Pip and the finale

## Checking with the real Pip in round 4 brings Pip strolling into the party.
func _on_chat_sent(contact: String) -> void:
	if contact != "pip" or pip.visible:
		return
	var start: Vector3 = party.pip_entry()
	var spot: Vector3 = party.pip_spot()
	pip.global_position = start
	pip.rotation.y = atan2(spot.x - start.x, spot.z - start.z)
	pip.show()
	pip.set_mood("Walk")
	var tween := create_tween()
	tween.tween_property(pip, "global_position", spot, 3.2)
	await tween.finished
	pip.rotation.y = atan2(camera.global_position.x - spot.x, camera.global_position.z - spot.z)
	pip.set_mood("Wave")


func _finale() -> void:
	if not pip.visible:
		_on_chat_sent("pip")
	await _glide("finale", 1.8)
	glitch.scale = Vector3.ONE * (1.0 + 0.15 * glitch_points)
	glitch.global_position = party.hideout("table")
	glitch.show()
	await glitch.blink_to(party.hideout("centre"))
	glitch.face(camera.global_position)
	for line: Array in DATA.GLITCH_CAUGHT:
		await ui.say(line[0], line[1])
	var spark := score() >= DATA.SPARK_SCORE
	var ending: Array = DATA.ENDING_SPARK if spark else DATA.ENDING_ESCAPE
	if spark:
		# With nobody falling for its tricks, the Glitch shrinks to a spark.
		var tween := create_tween()
		tween.tween_property(glitch, "scale", Vector3.ONE * 0.4, 1.2).set_trans(Tween.TRANS_BACK)
		glitch.jitter_amount = 0.2
		AudioManager.play("poof")
	for i in ending.size():
		await ui.say(ending[i][0], ending[i][1])
		if i == 0 and not spark:
			await glitch.run_to(party.pip_entry() + Vector3(4, 0, 4), 6.0)
			await glitch.vanish()
	pip.set_mood("Celebrate")
	party.set_piece("celebration", "on")
	AudioManager.play("success")
	if spark:
		glitch.hop_to(party.hideout("centre") + Vector3(-0.6, 0, 0.3), 0.5, 0.3)
	await _glide("party", 2.0)
	finished = true
	lesson_completed.emit(score())
	var lessons: Array = []
	for round_: Dictionary in DATA.ROUNDS:
		lessons.append(round_.lesson)
	phone.go_lock()
	ui.show_summary(score(), lessons)


func leave() -> void:
	LessonExit.back_to_room(get_tree(), finished)


# ------------------------------------------------------------------ camera

func _view(name_: String) -> Transform3D:
	var shot: Array = VIEWS[name_]
	var from: Vector3 = party.to_global(shot[0])
	var to: Vector3 = party.to_global(shot[1])
	return Transform3D(Basis.looking_at(to - from), from)


func _glide(name_: String, seconds: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_transform", _view(name_), seconds)
	await tween.finished


func _slide_phone_in() -> void:
	phone.position.x = 260.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(phone, "modulate:a", 1.0, 0.4)
	tween.tween_property(phone, "position:x", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
