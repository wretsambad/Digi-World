extends RefCounted
## Reveal already-shaped text, keeping wrapping, button sizes, and hit areas stable.
const LETTERS_PER_SECOND := 42.0
var jobs: Array[Dictionary] = []

func reveal(label: Label, delay := 0.0, rate := LETTERS_PER_SECOND, pausable := true) -> float:
	cancel(label)
	label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	label.visible_characters = 0
	var count := label.get_total_character_count()
	jobs.append({"target":label, "property":"visible_characters", "count":count, "clock":-delay, "rate":rate, "pausable":pausable})
	return delay + count/rate

func reveal_property(target: Object, property: String, count: int, rate := 55.0) -> void:
	cancel(target)
	target.set(property, 0)
	jobs.append({"target":target, "property":property, "count":count, "clock":0.0, "rate":rate, "pausable":false})

func button_caption(button: Button) -> Label:
	var caption := button.get_node_or_null("TypedCaption") as Label
	if caption == null:
		caption = Label.new()
		caption.name = "TypedCaption"
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color", button.get_theme_color("font_color"))
		button.add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Preserve the button's real text for its native size and accessible name.
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			button.add_theme_color_override(state, Color.TRANSPARENT)
	caption.text = button.text
	caption.horizontal_alignment = button.alignment
	caption.add_theme_font_override("font", button.get_theme_font("font"))
	caption.add_theme_font_size_override("font_size", button.get_theme_font_size("font_size"))
	var style := button.get_theme_stylebox("normal")
	caption.offset_left = style.get_content_margin(SIDE_LEFT)
	caption.offset_right = -style.get_content_margin(SIDE_RIGHT)
	caption.offset_top = style.get_content_margin(SIDE_TOP)
	caption.offset_bottom = -style.get_content_margin(SIDE_BOTTOM)
	return caption

func reveal_button(button: Button, delay := 0.0) -> void:
	reveal(button_caption(button), delay, 55.0, false)

func cancel(target: Object) -> void:
	jobs = jobs.filter(func(job: Dictionary): return is_instance_valid(job.target) and job.target != target)

func clear() -> void:
	jobs.clear()

func is_writing(target: Object) -> bool:
	for job in jobs:
		if job.target == target: return true
	return false

func complete(target: Object) -> void:
	for job in jobs:
		if job.target == target and is_instance_valid(target): target.set(job.property, job.count)
	cancel(target)

func advance(delta: float, paused := false) -> void:
	for i in range(jobs.size()-1, -1, -1):
		var job := jobs[i]
		if not is_instance_valid(job.target):
			jobs.remove_at(i)
			continue
		if paused and job.pausable: continue
		job.clock += delta
		var visible := clampi(int(maxf(0.0, job.clock)*job.rate), 0, job.count)
		job.target.set(job.property, visible)
		if visible == job.count: jobs.remove_at(i)
