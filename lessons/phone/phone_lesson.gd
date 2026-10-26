extends Node3D
## The Glitch's Last Trick: the phone lesson. The neighborhood house party
## has been switched off, and each round the Glitch sends one trick to the
## player's phone. Catching a trick brings back a piece of the party (lights,
## music, decorations, then the celebration) and unmasks more of the Glitch.
## Falling for one glitches that piece and gives the Glitch a point; the player
## rewinds and tries again. The finale is a silent walk-out cutscene.

signal lesson_completed(score: int)

const DATA := preload("res://lessons/phone/round_data.gd")
const LessonExit := preload("res://lessons/phone/lesson_exit.gd")
## Camera shots, as [from, to] in the party's own space, so moving the Party
## node moves every shot with it. Targets sit right of centre to leave the
## party clear of the phone on the right of the screen.
const VIEWS := {
	"arrive": [Vector3(2.8, 2.1, 13.0), Vector3(0.0, 1.7, 3.0)],
	"party": [Vector3(3.3, 2.4, 7.8), Vector3(2.0, 1.15, -2.0)],
	"speaker": [Vector3(0.2, 1.6, 3.4), Vector3(-1.7, 0.85, -1.9)],
	"balloons": [Vector3(5.2, 1.6, 6.4), Vector3(4.4, 1.55, 0.6)],
	"windows": [Vector3(2.3, 2.1, 6.5), Vector3(1.6, 2.5, -2.2)],
	"exit": [Vector3(-3.4, 1.8, -0.8), Vector3(1.2, 0.9, 5.5)],
	"finale": [Vector3(2.6, 1.7, 5.8), Vector3(1.9, 0.95, -0.6)],
}
## How many rows of the Glitch's pixel art each caught trick reveals.
const REVEAL_ROWS := [3, 6, 11]
const REVEAL_CAPTIONS := ["Pointy ears...?", "Big googly eyes...", "THE GLITCH!"]

@export var title_screen := true

var first_try: Array[bool] = []
var round_index := -1
var glitch_points := 0
var finished := false
var exit_started := false
var exit_finished := false
var exit_walking := false
var real_message_answered := false

@onready var party: Node3D = $Party
@onready var camera: Camera3D = $Camera3D
@onready var glitch: Node3D = $Glitch
@onready var ui: Control = $UI/PartyUI
@onready var phone: Control = $UI/Phone
var pause_menu: PauseMenu


func _ready() -> void:
	AudioManager.claim_music(self, "phone", 20)
	first_try.resize(DATA.ROUNDS.size())
	first_try.fill(true)
	if GameState.current_lesson != LessonExit.LESSON_ID:
		GameState.start_lesson(LessonExit.LESSON_ID)
	ui.phone = phone
	phone.hint.connect(ui.tip)
	ui.leave_pressed.connect(leave)
	ui.replay_pressed.connect(func() -> void: SceneLoading.change_scene(scene_file_path, "Glitch's Last Trick"))
	pause_menu = GlobalPause.menu
	glitch.hide()
	camera.global_transform = _view("arrive")
	phone.modulate.a = 0.0
	run()


func run() -> void:
	if title_screen:
		await ui.show_title()
	else:
		ui.title_card.hide()
	_slide_phone_in()
	await _glide("party", 2.6)
	ui.set_piece("lights", "on")
	for i in DATA.OPENING.size():
		if i == DATA.LIGHTS_OUT_LINE:
			party.blackout()
			ui.set_piece("lights", "off")
			AudioManager.play("glitch")
		var line: Array = DATA.OPENING[i]
		await ui.say(line[0], line[1])
	for i in DATA.ROUNDS.size():
		await play_round(i)
		if DATA.ROUNDS[i].piece == "music":
			await _play_real_message()
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
	await get_tree().create_timer(1.1, false).timeout
	phone.go_lock()
	await _restore(index)
	for line: Array in round_.solved:
		await ui.say(line[0], line[1])


func _play_real_message() -> void:
	await ui.say("PIP", "Another message has arrived. Take a look and decide what to do.")
	phone.show_notification(DATA.REAL_MESSAGE)
	ui.tip("Tap the notification to read the message.")
	await phone.opened
	phone.open_real_message()
	ui.tip("Check who sent it and what they want. Not every message is a trick.")
	var outcome: Array = await phone.case_ended
	party.choose_song(String(outcome[1]))
	real_message_answered = true
	await get_tree().create_timer(1.0, false).timeout
	phone.go_lock()
	await ui.say("PIP", "That was a real message! A song choice is fine to share. Enjoy your pick!")


func score() -> int:
	return first_try.count(true)


# ------------------------------------------------------------------ tricks

func _tricked(index: int, why: String) -> void:
	glitch_points += 1
	var piece: String = DATA.ROUNDS[index].piece
	var glitched: Array[String] = [piece]
	for target in glitched:
		party.set_piece(target, "glitched")
		ui.set_piece(target, "glitched")
	await _glitch_laughs(index)
	await ui.say("PIP", why, "Rewind")
	for target in glitched:
		# Pieces caught in earlier rounds come back; this round's piece stays off.
		var restored := "on" if DATA.ROUNDS.slice(0, index).any(func(r: Dictionary) -> bool: return r.piece == target) else "off"
		party.set_piece(target, restored, false)
		ui.set_piece(target, restored)
	phone.rewind()
	ui.tip("Let's try that again. Take your time: real friends can wait.")


## The Glitch pops out, a little bigger with every point, giggles and hides.
func _glitch_laughs(index: int) -> void:
	var spot: Vector3 = party.hideout(["speaker_peek", "speaker_peek", "balloons"][index])
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
			await _fade_phone(0.0)
			await _glide("windows", 1.2)
			AudioManager.play("repair")
			await party.restore_lights()
			await _fade_phone(1.0)
			await _flicker_glitch()
		1:
			party.set_piece("music", "on")
			AudioManager.play("success")
			await _glide("speaker", 1.6)
			await _glitch_peeks()
		2:
			party.set_piece("decorations", "on")
			AudioManager.play("build")
			await _glide("party", 1.6)
			await get_tree().create_timer(1.0, false).timeout
	ui.set_piece(piece, "on")
	ui.reveal_glitch(REVEAL_ROWS[index], REVEAL_CAPTIONS[index])
	if index < DATA.ROUNDS.size() - 1:
		_glide("party", 1.8)


## Round 1: just a flicker by the speaker, gone before you can be sure.
func _flicker_glitch() -> void:
	glitch.scale = Vector3.ONE
	glitch.global_position = party.hideout("speaker")
	glitch.face(camera.global_position)
	for i in 3:
		glitch.show()
		AudioManager.play("glitch")
		await get_tree().create_timer(0.09, false).timeout
		glitch.hide()
		await get_tree().create_timer(0.22, false).timeout


## Round 2: static, then two eyes peek round the speaker.
func _glitch_peeks() -> void:
	glitch.scale = Vector3.ONE
	var hide_spot: Vector3 = party.hideout("speaker")
	glitch.global_position = hide_spot
	glitch.jitter_amount = 3.0
	glitch.show()
	glitch.face(camera.global_position)
	await glitch.hop_to(party.hideout("speaker_peek"), 0.3, 0.12)
	await get_tree().create_timer(0.5, false).timeout
	await glitch.blink_to(hide_spot)
	glitch.hide()
	glitch.jitter_amount = 1.0


# ------------------------------------------------------------------ silent finale

func _walk_glitch_to(target: Vector3, seconds: float) -> void:
	glitch.face(target)
	var start: Vector3 = glitch.global_position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		glitch.global_position = start.lerp(target, t)
		# Small alternating steps rather than the actor's running hops.
		glitch.pixels.rotation.z = sin(t * seconds * 12.0) * 0.07,
		0.0, 1.0, seconds)
	await tween.finished
	glitch.pixels.rotation.z = 0.0


func _finale() -> void:
	exit_started = true
	ui.hide_story()
	ui.portrait.hide()
	ui.hud.hide()
	await _fade_phone(0.0)
	await _glide("finale", 1.2)
	glitch.scale = Vector3.ONE
	glitch.global_position = party.hideout("table")
	glitch.jitter_amount = 0.3
	glitch.show()
	glitch.face(camera.global_position)
	await get_tree().create_timer(0.6, false).timeout
	await _walk_glitch_to(party.hideout("centre"), 1.5)
	await _glide("exit", 1.2)
	exit_walking = true
	await _walk_glitch_to(party.exit_position(), 4.2)
	await glitch.vanish()
	exit_walking = false
	await get_tree().create_timer(0.5, false).timeout
	exit_finished = true
	party.set_piece("celebration", "on")
	ui.set_piece("celebration", "on")
	AudioManager.play("complete")
	await _glide("party", 1.8)
	await _fade_phone(1.0)
	ui.hud.show()
	finished = true
	lesson_completed.emit(score())
	var lessons: Array = []
	for round_: Dictionary in DATA.ROUNDS:
		lessons.append(round_.lesson)
	phone.go_lock()
	ui.show_summary(score(), lessons)


func _fade_phone(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(phone, "modulate:a", alpha, 0.3)
	await tween.finished


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
