extends Control
## Sharing Board, Round 1: "Who should see it?"
## A knitted board with four felt pockets. The next patch waits in a mitten;
## the player drags it into a pocket (or presses 1 to 4) and it stitches on.
## "Check my board" sews safe patches down in gold thread and pops the stitches
## on unsafe ones, which go back to the mitten with the snowman's reason.

signal sorting_finished(results: Dictionary)
signal park_board_requested
signal finish_pressed
signal next_round_requested
signal home_requested

const Cards := preload("res://lessons/sharing_board/round1_cards.gd")
const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const StitchedPanel := preload("res://lessons/sharing_board/ui/stitched_panel.gd")
const SewnButton := preload("res://lessons/sharing_board/ui/sewn_button.gd")
const SnowBuddy := preload("res://lessons/sharing_board/ui/snow_buddy.gd")
const Pieces := preload("res://lessons/sharing_board/ui/knit_pieces.gd")

const PLACED_LINES := ["Sewn on!", "Nice stitch!", "Got it!", "In it goes!"]

var _cards := {}  # card id -> card data
var _zones := {}  # zone id -> zone data
var _deck: Array[String] = []
var _placement := {}  # card id -> zone id, in the order cards were placed
var _locked := {}  # card id -> true once it was checked and is safe
var _came_loose := {}  # card id -> true while it waits for another try
var _flipped := {}  # card id -> showing its back
var _first_try := {}  # card id -> was it safe the first time it was checked?
var _public_slips: Array[String] = []  # unsafe cards that were put on the public board
var _patches := {}  # card id -> its patch on the board
var _checking := false
var _reviewing := false
var _review_return: Callable

var _pockets := {}  # zone id -> StitchedPanel
var _pocket_lists := {}  # zone id -> PatchStack

var _dragging := ""
var _drag_source: Control
var _ghost: Control
var _hover_zone := ""

var _sorting_view: Control
var _scarf: Pieces.Scarf
var _count_label: Label
var _mitten: Pieces.Mitten
var _buddy: SnowBuddy
var _check_button: SewnButton
var _caption: Control
var _overlay: Control
var _sheet_box: VBoxContainer


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = Kit.theme()
	for card in Cards.CARDS:
		_cards[card.id] = card
	for zone in Cards.ZONES:
		_zones[zone.id] = zone
	_build_sorting_view()
	_build_caption()
	_build_overlay()
	hide()


## Deals a fresh, shuffled deck and shows the intro.
func begin() -> void:
	_deck.clear()
	for card in Cards.CARDS:
		_deck.append(card.id)
	_deck.shuffle()
	for state in [_placement, _locked, _came_loose, _flipped, _first_try]:
		state.clear()
	_public_slips.clear()
	_refresh()
	_buddy.say("Drag the patch into a pocket, or just tap a pocket. Who should see it?", "happy")
	_caption.hide()
	_sorting_view.show()
	show()
	_show_sheet("Snow day at Willow Park!",
		"The neighborhood put up a board by the park. Anything pinned there can be seen by [b]everyone[/b] who walks by, even people you don't know.\n\nSew each patch into the pocket for [b]who should see it[/b].",
		[["Let's sew!", Kit.CRANBERRY, _close_sheet]])


## The cards the player put on the public board, as {"id", "text"}.
func get_public_cards() -> Array:
	var cards := []
	for id in _placement:
		if _placement[id] == "everyone":
			cards.append({"id": id, "text": _cards[id].text})
	return cards


## Shown while the camera looks at the real park board.
func show_board_caption() -> void:
	_sorting_view.hide()
	_caption.show()
	show()


func show_complete(can_continue: bool) -> void:
	_caption.hide()
	_sorting_view.hide()
	var buttons := []
	if can_continue:
		buttons.append(["Play again", Kit.PINE, func(): get_tree().reload_current_scene()])
		buttons.append(["Continue", Kit.CRANBERRY, func(): next_round_requested.emit()])
	_show_sheet("Great Work!",
		"Before you share something, stop and ask: [b]who will see it?[/b]", buttons)


func _review_patches(on_back: Callable) -> void:
	_reviewing = true
	_review_return = on_back
	_flipped.clear()
	_close_sheet()
	_caption.hide()
	_sorting_view.show()
	_refresh()
	_mitten.hide()
	_check_button.text = "Back"
	_buddy.say("Tap any patch to read its explanation. Press Back when you're done.", "happy")
	show()


func _finish_review() -> void:
	_reviewing = false
	_mitten.show()
	_check_button.text = "Check my board"
	_sorting_view.hide()
	_refresh()
	_review_return.call()


func _show_patch_explanation(card_id: String) -> void:
	var card: Dictionary = _cards[card_id]
	_show_sheet("Why this patch?", "[b]%s[/b]\n\n%s" % [card.text, card.why],
		[["Back to patches", Kit.CRANBERRY, _close_sheet]])


# --- Building the board -------------------------------------------------------

func _build_sorting_view() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	_sorting_view = margin

	var column := VBoxContainer.new()
	column.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	# Title tag and the scarf that counts patches
	var top := HBoxContainer.new()
	top.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(top)
	var title := _fabric(StitchedPanel.Fabric.FELT, Kit.CRANBERRY, 14, 6, Color(Kit.YARN, 0.85))
	title.set_padding(22, 6)
	title.add_child(Kit.label("Who should see it?", 30, true, Kit.YARN))
	top.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	spacer.mouse_filter = MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var progress := _fabric(StitchedPanel.Fabric.KNIT, Kit.PINE, 14, 6, Color(Kit.YARN, 0.45))
	progress.set_padding(20, 4)
	top.add_child(progress)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 16)
	progress.add_child(progress_row)
	_scarf = Pieces.Scarf.new()
	_scarf.size_flags_vertical = SIZE_SHRINK_CENTER
	progress_row.add_child(_scarf)
	_count_label = Kit.label("", 19, true, Kit.YARN)
	_count_label.custom_minimum_size.x = 112
	_count_label.size_flags_vertical = SIZE_SHRINK_CENTER
	var count_patch := _fabric(StitchedPanel.Fabric.FELT, Kit.PINE, 10, 0, Color(Kit.YARN, 0.45))
	count_patch.set_padding(8, 3)
	count_patch.size_flags_vertical = SIZE_SHRINK_CENTER
	count_patch.add_child(_count_label)
	progress_row.add_child(count_patch)

	# The knitted board with four felt pockets
	var board := _fabric(StitchedPanel.Fabric.KNIT, Kit.PINE, 24, 10, Color(Kit.YARN, 0.5))
	board.stitch_inset = 8.0
	board.set_padding(16, 16)
	board.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(board)
	var pockets := HBoxContainer.new()
	pockets.add_theme_constant_override("separation", 14)
	pockets.mouse_filter = MOUSE_FILTER_IGNORE
	board.add_child(pockets)
	for i in Cards.ZONES.size():
		pockets.add_child(_build_pocket(Cards.ZONES[i], i + 1))

	# Snowman, mitten with the next patch, and the check button
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 18)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(bottom)
	_buddy = SnowBuddy.new()
	_buddy.set_bubble_width(270)
	bottom.add_child(_buddy)
	_mitten = Pieces.Mitten.new()
	bottom.add_child(_mitten)
	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	actions.mouse_filter = MOUSE_FILTER_IGNORE
	bottom.add_child(actions)
	_check_button = SewnButton.new("Check my board", Kit.CRANBERRY)
	_check_button.pressed.connect(_on_check_pressed)
	actions.add_child(_check_button)


func _build_pocket(zone: Dictionary, number: int) -> Control:
	var color: Color = zone.color
	var pocket := _fabric(StitchedPanel.Fabric.FELT, color, 16, 4, Color(Kit.INK, 0.35))
	pocket.set_padding(10, 10)
	pocket.size_flags_horizontal = SIZE_EXPAND_FILL
	_pockets[zone.id] = pocket

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	pocket.add_child(column)

	var band := Pieces.HeaderBand.new(color.darkened(0.42), color.lightened(0.35))
	column.add_child(band)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 9)
	header.mouse_filter = MOUSE_FILTER_IGNORE
	band.add_child(header)
	var button := Pieces.NumberButton.new(number, Kit.SNOW)
	button.size_flags_vertical = SIZE_SHRINK_CENTER
	header.add_child(button)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -3)
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.mouse_filter = MOUSE_FILTER_IGNORE
	header.add_child(titles)
	var title := Kit.label(zone.title, 21, true, Kit.SNOW)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(title)
	var subtitle := Kit.label(zone.subtitle, 13, false, Kit.SNOW)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)

	var stack := PatchStack.new()
	stack.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(stack)
	_pocket_lists[zone.id] = stack
	# Tapping a pocket sews the patch from the mitten into it.
	pocket.mouse_filter = MOUSE_FILTER_STOP
	pocket.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	pocket.gui_input.connect(_on_pocket_gui_input.bind(zone.id))
	return pocket


func _build_caption() -> void:
	var holder := MarginContainer.new()
	holder.set_anchors_preset(PRESET_FULL_RECT)
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("margin_top", 16)
	add_child(holder)
	_caption = holder

	var tag := _fabric(StitchedPanel.Fabric.FELT, Kit.ICE, 18, 8, Color(Kit.PINE, 0.5))
	tag.set_padding(24, 14)
	tag.size_flags_horizontal = SIZE_SHRINK_CENTER
	tag.size_flags_vertical = SIZE_SHRINK_BEGIN
	holder.add_child(tag)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	tag.add_child(row)
	var text := Kit.label("These patches are on the park board now. Anyone who walks by can read them, even people you don't know.", 18)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 470
	text.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(text)
	var finish := SewnButton.new("Finish round", Kit.CRANBERRY)
	finish.size_flags_vertical = SIZE_SHRINK_CENTER
	finish.pressed.connect(func(): finish_pressed.emit())
	row.add_child(finish)
	holder.hide()


func _build_overlay() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.13, 0.42)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	add_child(dim)
	_overlay = dim

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var sheet := _fabric(StitchedPanel.Fabric.FELT, Kit.ICE, 24, 14, Color(Kit.PINE, 0.55))
	sheet.stitch_inset = 9.0
	sheet.set_padding(38, 30)
	center.add_child(sheet)
	_sheet_box = VBoxContainer.new()
	_sheet_box.custom_minimum_size.x = 560
	_sheet_box.add_theme_constant_override("separation", 16)
	sheet.add_child(_sheet_box)
	dim.hide()


# --- Patches --------------------------------------------------------------------

func _refresh() -> void:
	_patches.clear()
	for zone_id in _pocket_lists:
		_clear(_pocket_lists[zone_id])
	for card_id in _placement:
		var patch := _make_patch(card_id, false)
		_patches[card_id] = patch
		_pocket_lists[_placement[card_id]].add_child(patch)

	_clear(_mitten)
	var total := _cards.size()
	var sewn := total - _deck.size()
	_scarf.progress = float(sewn) / total
	_count_label.text = "%d of %d" % [sewn, total]
	if _deck.is_empty():
		var done := _fabric(StitchedPanel.Fabric.FELT, Kit.SNOW, 16, 6, Color(Kit.INK, 0.3))
		done.set_padding(20, 18)
		done.add_child(Kit.label("All patches are sewn on!", 21, true, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER))
		_mitten.add_child(done)
	else:
		_mitten.add_child(_make_patch(_deck[0], true))
	_check_button.disabled = not _reviewing and (not _deck.is_empty() or _locked.size() == total or _checking)


func _make_patch(card_id: String, big: bool) -> StitchedPanel:
	var card: Dictionary = _cards[card_id]
	var locked := _locked.has(card_id)
	var loose := big and _came_loose.has(card_id)

	var patch := _fabric(StitchedPanel.Fabric.FELT, Kit.patch_color(card_id), 16 if big else 11, 8 if big else 3,
			Color(Kit.INK_SOFT, 0.6))
	patch.stitch_inset = 6.0 if big else 4.5
	patch.thread_width = 2.4 if big else 1.9
	patch.set_padding(22 if big else 11, 14 if big else 8)
	if locked:
		patch.thread_color = Kit.GOLD_THREAD
		patch.thread_width = 2.6
		# The kind tag hangs off the top-right corner, beside the words, never above them.
		patch.corner_tag = card.kind
		var pad := StyleBoxEmpty.new()
		pad.content_margin_left = 11
		pad.content_margin_right = 11
		pad.content_margin_top = 15
		pad.content_margin_bottom = 8
		patch.add_theme_stylebox_override("panel", pad)
		patch.set_meta("text_top", 15.0)
	if big:
		patch.custom_minimum_size = Vector2(340, 104)
	patch.mouse_filter = MOUSE_FILTER_STOP
	patch.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	patch.gui_input.connect(_on_patch_gui_input.bind(card_id, patch))
	if not big:
		# A hovered patch lifts above the ones it overlaps.
		patch.mouse_entered.connect(func(): patch.z_index = 4)
		patch.mouse_exited.connect(func(): patch.z_index = 0)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	patch.add_child(column)

	if locked and _flipped.has(card_id):
		# A flipped patch keeps its full height in the pocket, so its reason
		# reads in full without covering the patch below.
		patch.set_meta("keep_whole", true)
		var why := Kit.label(card.why, 16)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		patch.set_meta("line_height", ceilf(Kit.body_font().get_height(16)))
		column.add_child(why)
		return patch

	if loose:
		patch.frayed = true
		patch.thread_color = Kit.LOOSE
		patch.thread_width = 2.8
	var text := Kit.label(card.text, 22 if big else 15, false, Kit.INK,
			HORIZONTAL_ALIGNMENT_CENTER if big else HORIZONTAL_ALIGNMENT_LEFT)
	patch.set_meta("line_height", ceilf(Kit.body_font().get_height(15)))
	patch.set_meta("text_top", 15.0 if locked else 8.0)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if big:
		text.custom_minimum_size.x = 296
	column.add_child(text)
	return patch


func _on_patch_gui_input(event: InputEvent, card_id: String, source: Control) -> void:
	var press := event as InputEventMouseButton
	if press == null or press.button_index != MOUSE_BUTTON_LEFT or not press.pressed or not _dragging.is_empty():
		return
	accept_event()
	if _checking:
		return
	if _reviewing:
		_show_patch_explanation(card_id)
		return
	if _locked.has(card_id):
		_flip(card_id, source)
	else:
		_start_drag(card_id, source)


func _on_pocket_gui_input(event: InputEvent, zone_id: String) -> void:
	var press := event as InputEventMouseButton
	if press == null or press.button_index != MOUSE_BUTTON_LEFT or not press.pressed:
		return
	if _dragging.is_empty() and not _checking and not _deck.is_empty() and not _overlay.visible:
		accept_event()
		_place(_deck[0], zone_id)


func _flip(card_id: String, patch: Control) -> void:
	patch.pivot_offset = patch.size * 0.5
	var tween := create_tween()
	tween.tween_property(patch, "scale:x", 0.0, 0.1).set_ease(Tween.EASE_IN)
	if not _flipped.has(card_id):
		_buddy.say(_cards[card_id].why, "happy")
	tween.tween_callback(func():
		if _flipped.has(card_id):
			_flipped.erase(card_id)
		else:
			_flipped[card_id] = true
		_refresh()
		var fresh: Control = _patches.get(card_id)
		if fresh:
			fresh.scale.x = 0.0
			await get_tree().process_frame
			fresh.pivot_offset = fresh.size * 0.5
			create_tween().tween_property(fresh, "scale:x", 1.0, 0.14).set_ease(Tween.EASE_OUT))


# --- Dragging -------------------------------------------------------------------

func _start_drag(card_id: String, source: Control) -> void:
	_dragging = card_id
	_drag_source = source
	source.modulate.a = 0.3
	_ghost = _make_patch(card_id, false)
	_ghost.mouse_filter = MOUSE_FILTER_IGNORE
	_ghost.rotation_degrees = -4.0
	_ghost.scale = Vector2(1.06, 1.06)
	_ghost.surface = Kit.surface(Kit.patch_color(card_id), 11, 12)
	for label in _ghost.find_children("*", "Label", true, false):
		label.custom_minimum_size.x = 200
	add_child(_ghost)
	_move_ghost()


func _input(event: InputEvent) -> void:
	if _dragging.is_empty():
		return
	if event is InputEventMouseMotion:
		_move_ghost()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var card_id := _dragging
		var target := _hover_zone
		_end_drag()
		if not target.is_empty():
			_place(card_id, target)
		get_viewport().set_input_as_handled()


func _move_ghost() -> void:
	var mouse := get_global_mouse_position()
	# Wrapped labels only know their height after a layout pass, so keep
	# shrinking the ghost to fit while it moves.
	_ghost.reset_size()
	_ghost.pivot_offset = _ghost.size * 0.5
	_ghost.global_position = mouse - _ghost.size * 0.5
	var hovered := ""
	for zone_id in _pockets:
		if _pockets[zone_id].get_global_rect().has_point(mouse):
			hovered = zone_id
	_set_hover_zone(hovered)


func _end_drag() -> void:
	_dragging = ""
	_set_hover_zone("")
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	if is_instance_valid(_drag_source):
		_drag_source.modulate.a = 1.0


func _set_hover_zone(zone_id: String) -> void:
	if zone_id == _hover_zone:
		return
	if _pockets.has(_hover_zone):
		var old: StitchedPanel = _pockets[_hover_zone]
		old.thread_color = Color(Kit.INK, 0.35)
		old.thread_width = 2.2
		old.surface = Kit.surface(_zones[_hover_zone].color, 16, 4)
	_hover_zone = zone_id
	if _pockets.has(zone_id):
		var pocket: StitchedPanel = _pockets[zone_id]
		pocket.thread_color = Kit.SNOW
		pocket.thread_width = 3.4
		pocket.surface = Kit.surface(_zones[zone_id].color.lightened(0.12), 16, 10)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or _overlay.visible or _deck.is_empty() or not _sorting_view.visible or _checking:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var index := key.keycode - KEY_1
		if index >= 0 and index < Cards.ZONES.size():
			_place(_deck[0], Cards.ZONES[index].id)
			get_viewport().set_input_as_handled()


func _place(card_id: String, zone_id: String) -> void:
	_deck.erase(card_id)
	_placement.erase(card_id)
	_placement[card_id] = zone_id
	_came_loose.erase(card_id)
	_refresh()
	_sew_on(_patches[card_id])
	if _deck.is_empty():
		_buddy.say("All sewn! Press Check my board when you're ready.", "think")
	elif _came_loose.has(_deck[0]):
		_say_loose_reason(_deck[0])
	else:
		_buddy.say("%s Who should see the next one?" % PLACED_LINES.pick_random(), "happy")


## The signature moment: thread runs around a patch stitch by stitch.
func _sew_on(patch: StitchedPanel) -> void:
	patch.stitch_progress = 0.0
	patch.pivot_offset = patch.custom_minimum_size * 0.5
	patch.scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(patch, "scale", Vector2.ONE, 0.25)
	tween.tween_property(patch, "stitch_progress", 1.0, 0.5)


# --- Checking -----------------------------------------------------------------

func _on_check_pressed() -> void:
	if _reviewing:
		_finish_review()
		return
	_checking = true
	_check_button.disabled = true
	_buddy.say("Let's check every stitch...", "think")
	var loose: Array[String] = []
	for card_id in _placement:
		if _locked.has(card_id):
			continue
		var zone_id: String = _placement[card_id]
		var safe: bool = _cards[card_id].ok.has(zone_id)
		if not _first_try.has(card_id):
			_first_try[card_id] = safe
		var patch: StitchedPanel = _patches[card_id]
		var tween := create_tween()
		if safe:
			_locked[card_id] = true
			patch.thread_color = Kit.GOLD_THREAD
			patch.thread_width = 2.6
			patch.stitch_progress = 0.0
			tween.tween_property(patch, "stitch_progress", 1.0, 0.2).set_ease(Tween.EASE_OUT)
		else:
			loose.append(card_id)
			if zone_id == "everyone" and not _public_slips.has(card_id):
				_public_slips.append(card_id)
			patch.thread_color = Kit.LOOSE
			patch.pivot_offset = patch.size * 0.5
			tween.set_parallel()
			tween.tween_property(patch, "loosen", 1.0, 0.5).set_ease(Tween.EASE_IN)
			tween.tween_property(patch, "rotation_degrees", 5.0, 0.08)
			tween.chain().tween_property(patch, "rotation_degrees", -4.0, 0.1)
			tween.chain().tween_property(patch, "rotation_degrees", 0.0, 0.1)
		await tween.finished

	await get_tree().create_timer(0.35).timeout
	_checking = false
	if loose.is_empty():
		_refresh()
		_show_results()
		return

	for card_id in loose:
		_placement.erase(card_id)
		_came_loose[card_id] = true
	# Loose patches go to the front of the mitten pile, in board order.
	loose.reverse()
	for card_id in loose:
		_deck.push_front(card_id)
	_refresh()
	_say_loose_reason(_deck[0], loose.size())


func _say_loose_reason(card_id: String, count := 0) -> void:
	var opening := ""
	if count > 1:
		opening = "Oops, %d patches came loose! " % count
	elif count == 1:
		opening = "Oops, one patch came loose! "
	_buddy.say(opening + _cards[card_id].why + " Try a different pocket.", "oops")


func _show_results() -> void:
	var total := _cards.size()
	var first_try_right := 0
	for card_id in _first_try:
		if _first_try[card_id]:
			first_try_right += 1
	var stars := 3 if first_try_right == total else (2 if first_try_right >= total - 2 else 1)
	_buddy.say("Every patch is sewn in the right pocket!", "wow")

	sorting_finished.emit({
		"stars": stars,
		"first_try": _first_try.duplicate(),
		"public_slips": _public_slips.duplicate(),
		"placement": _placement.duplicate(),
	})
	_show_sorting_summary(first_try_right, stars)


func _show_sorting_summary(first_try_right: int, stars: int) -> void:
	_sorting_view.show()
	_show_sheet("Board complete!",
		"You sewed [b]%d of %d[/b] patches in a safe pocket on your first try.\n\nFun facts are fine for everyone. Things that show [b]who you are or where to find you[/b] need a grown-up's OK, and passwords stay secret.\n\nChoose Review patches to click each patch and read its explanation." % [first_try_right, _cards.size()],
		[["Review patches", Kit.PINE, _review_patches.bind(_show_sorting_summary.bind(first_try_right, stars))],
		["See the park board", Kit.CRANBERRY, _on_see_board_pressed]], FeltStars.new(stars))


func _on_see_board_pressed() -> void:
	_close_sheet()
	hide()
	park_board_requested.emit()


# --- Sheets and helpers ---------------------------------------------------------

func _show_sheet(title: String, body: String, buttons: Array, extra: Control = null) -> void:
	_clear(_sheet_box)
	_sheet_box.add_child(Kit.label(title, 34, true, Kit.CRANBERRY, HORIZONTAL_ALIGNMENT_CENTER))
	if extra:
		_sheet_box.add_child(extra)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.text = body
	text.add_theme_font_size_override("normal_font_size", 19)
	text.add_theme_font_size_override("bold_font_size", 19)
	_sheet_box.add_child(text)
	if not buttons.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		_sheet_box.add_child(row)
		for spec in buttons:
			var button := SewnButton.new(spec[0], spec[1])
			button.pressed.connect(spec[2])
			row.add_child(button)
		row.get_child(row.get_child_count() - 1).call_deferred("grab_focus")
	_overlay.show()
	show()


func _close_sheet() -> void:
	_overlay.hide()


func _fabric(fabric: int, color: Color, radius: int, shadow: int, thread: Color) -> StitchedPanel:
	var panel := StitchedPanel.new()
	panel.fabric = fabric
	panel.surface = Kit.surface(color, radius, shadow)
	panel.thread_color = thread
	return panel


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## Holds a pocket's patches. While they fit, they stack with a gap; once the
## pocket is full they overlap, but every patch keeps at least its first line
## of words showing. The newest patch and any flipped patch are shown whole.
class PatchStack extends Container:
	const TOP := 12.0  # room for the first patch's hanging tag
	const GAP := 8.0
	const STRIP := 48.0  # smallest slice of an overlapped patch: its first line

	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		clip_contents = true

	func _get_minimum_size() -> Vector2:
		return Vector2.ZERO

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			_stack()

	func _stack() -> void:
		var patches: Array[Control] = []
		for child in get_children():
			if child is Control and child.visible:
				patches.append(child)
		var count := patches.size()
		if count == 0:
			return
		var heights: Array[float] = []
		for patch in patches:
			heights.append(patch.get_combined_minimum_size().y)
		# First try keeping flipped patches whole; if that squeezes the others
		# below their first line, trim the flipped ones too (the snowman reads
		# their reason aloud anyway).
		var steps := _steps(patches, heights, true)
		if steps.is_empty():
			steps = _steps(patches, heights, false)
		if steps.is_empty():
			steps = _even_steps(heights)
		var y := TOP
		for i in count:
			fit_child_in_rect(patches[i], Rect2(0.0, y, size.x, heights[i]))
			y += steps[i]

	## Distances from each patch's top to the next, or [] if some patch would
	## show less than its first line.
	func _steps(patches: Array[Control], heights: Array[float], keep_flipped: bool) -> Array[float]:
		var count := patches.size()
		var steps: Array[float] = []
		var whole: Array[bool] = []
		for i in count:
			steps.append(heights[i] + GAP)
			whole.append(i == count - 1 or (keep_flipped and patches[i].get_meta("keep_whole", false)))
		var budget := size.y - TOP - heights[count - 1]
		var natural := 0.0
		var trimmable := 0
		for i in count - 1:
			if whole[i]:
				budget -= steps[i]
			else:
				natural += steps[i]
				trimmable += 1
		if natural <= budget:
			return steps
		if trimmable == 0 or budget < STRIP * trimmable:
			return []
		# Trim the tallest patches first, never below the first-line strip.
		var low := STRIP
		var high := 0.0
		for step in steps:
			high = maxf(high, step)
		for pass_index in 24:
			var cap := (low + high) * 0.5
			if _used(steps, whole, cap) > budget:
				high = cap
			else:
				low = cap
		for i in count - 1:
			if not whole[i] and steps[i] > low:
				steps[i] = _whole_lines(patches[i], low)
		return steps

	## Rounds a trimmed slice down to whole lines of text, so the patch below
	## never cuts a line of words in half.
	func _whole_lines(patch: Control, slice: float) -> float:
		var top: float = patch.get_meta("text_top", 15.0)
		var line: float = patch.get_meta("line_height", 28.0)
		# Cut 5px past the last whole line: below its letters, above the next line's.
		var lines := maxi(1, int((slice - top - 5.0) / line))
		return top + lines * line + 5.0

	func _used(steps: Array[float], whole: Array[bool], cap: float) -> float:
		var used := 0.0
		for i in steps.size() - 1:
			if not whole[i]:
				used += minf(steps[i], cap)
		return used

	## Last resort when a pocket holds more patches than fit at one line each.
	func _even_steps(heights: Array[float]) -> Array[float]:
		var count := heights.size()
		var steps: Array[float] = []
		var share := maxf(size.y - TOP - heights[count - 1], 0.0) / maxf(count - 1, 1)
		for i in count:
			steps.append(minf(heights[i] + GAP, share))
		return steps


## Three felt stars for the results sheet, gold up to the player's score.
class FeltStars extends Control:
	var filled := 0

	func _init(count: int) -> void:
		filled = count
		custom_minimum_size = Vector2(0, 70)
		material = Kit.felt_material()

	func _draw() -> void:
		var radius := 29.0
		var gap := 22.0
		var first_x := size.x * 0.5 - (radius * 2.0 + gap)
		for i in 3:
			var center := Vector2(first_x + i * (radius * 2.0 + gap), size.y * 0.5)
			var points := PackedVector2Array()
			for k in 10:
				var angle := -PI * 0.5 + k * PI / 5.0
				points.append(center + Vector2(cos(angle), sin(angle)) * (radius if k % 2 == 0 else radius * 0.48))
			var shadow := PackedVector2Array()
			for p in points:
				shadow.append(p + Vector2(0, 3))
			draw_colored_polygon(shadow, Color(0, 0, 0, 0.18))
			draw_colored_polygon(points, Kit.MUSTARD if i < filled else Color("#C9D3DC"))
			var inner := PackedVector2Array()
			for p in points:
				inner.append(center + (p - center) * 0.8)
			inner.append(inner[0])
			for j in inner.size() - 1:
				var a: Vector2 = inner[j]
				var b: Vector2 = inner[j + 1]
				draw_line(a.lerp(b, 0.15), a.lerp(b, 0.55), Color(Kit.INK, 0.35), 1.6, true)
