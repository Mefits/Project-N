extends Node2D
## Isolated control experiment, independent of the existing arena and animation rig.
const STEP := 1.0 / 60.0
const WORLD_W := 2700.0
const FLOOR := 790.0
const RUN := 420.0
const GRAVITY := 1250.0
const JUMP := -760.0
const DASH_SPEED := 1700.0
const READY_TIME := 8.0
const RECIPES := {"WDS": "Bolt", "SWDW": "Orb", "ADW": "Rush"}
const BLUE := Color("#83baf2")
const GOLD := Color("#efc276")
const RED := Color("#ec8879")
var pos := Vector2(800, FLOOR)
var vel := Vector2.ZERO
var aim := Vector2.RIGHT
var target := Vector2(1250, FLOOR - 30)
var clock := 0.0
var accumulator := 0.0
var dash_left := 0.0
var dash_cooldown := 0.0
var air_dashes := 2
var air_jump := true
var grounded := true
var signing := false
var sign_done := false
var sequence := ""
var prepared_spell := ""
var ready_left := 0.0
var latched := 0.0
var latch_mode := false
var moving_target := true
var shots: Array[Dictionary] = []
var hits := 0
var casts := 0
var message := "Try W D S while holding SHIFT"
var message_left := 4.0
var camera := Vector2(1030, 590)
var zoom := 0.8
var jump_requested := false
var dash_requested := false
var cast_requested := false
var dash_direction := Vector2.RIGHT
# Keyboard-only experiment: F4 toggles optional double-space dash.
const LAYOUTS := ["K dash", "K / double SPACE dash"]
const DOUBLE_TAP := 0.26
var layout := 0
var last_space := -10.0

func _ready() -> void:
	queue_redraw()

func _axis() -> float:
	return float(int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)))

func _seal_modifier(down: bool) -> void:
	if down and not signing:
		latched = _axis()
		signing = true
		sign_done = false
		sequence = ""
	elif not down:
		signing = false
		sequence = ""

func _seal_key() -> int:
	return KEY_SHIFT

func _aim_from_keys(move: Vector2, arrows: Vector2) -> void:
	if arrows.length_squared() > 0.0:
		aim = arrows.normalized()
	elif not signing and move.length_squared() > 0.0:
		aim = move.normalized()

func _update_aim() -> void:
	var move := Vector2(_axis(), float(int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))))
	var arrows := Vector2(float(int(Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_LEFT))), float(int(Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_UP))))
	_aim_from_keys(move, arrows)

func _space_press() -> void:
	if layout == 1 and clock - last_space <= DOUBLE_TAP:
		dash_requested = true
		last_space = -10.0
	else:
		jump_requested = true
		last_space = clock

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: int = event.physical_keycode
		if k == _seal_key() and k != 0:
			if not event.echo:
				_seal_modifier(event.pressed)
			get_viewport().set_input_as_handled()
			return
		if not event.pressed or event.echo:
			return
		if signing and k in [KEY_W, KEY_A, KEY_S, KEY_D]:
			if not sign_done:
				var letter: String = {KEY_W:"W", KEY_A:"A", KEY_S:"S", KEY_D:"D"}[k]
				if sequence.is_empty():
					prepared_spell = ""
					ready_left = 0.0
				sequence += letter
				if RECIPES.has(sequence):
					prepared_spell = RECIPES[sequence]
					ready_left = READY_TIME
					sign_done = true
					_notice(prepared_spell + " ready - J to release")
				else:
					var prefix := false
					for recipe in RECIPES:
						if String(recipe).begins_with(sequence):
							prefix = true
					if not prefix:
						_notice("Wrong seal - try again")
						sequence = ""
			return
		match k:
			KEY_SPACE: _space_press()
			KEY_K: dash_requested = true
			KEY_J: cast_requested = true
			KEY_L: _cancel()
			KEY_F2:
				latch_mode = not latch_mode
				_notice("Latched movement" if latch_mode else "Coast on inertia")
			KEY_F3:
				moving_target = not moving_target
			KEY_F4:
				layout = (layout + 1) % LAYOUTS.size()
				_seal_modifier(false)
				last_space = -10.0
				_notice("Controls: " + LAYOUTS[layout])
			KEY_R:
				_reset()
			KEY_ESCAPE:
				_cancel()

func _notice(s: String) -> void:
	message = s
	message_left = 2.5

func _cancel() -> void:
	signing = false
	sign_done = false
	sequence = ""
	prepared_spell = ""
	ready_left = 0.0
	_notice("Preparation canceled")

func _reset() -> void:
	pos = Vector2(800, FLOOR)
	vel = Vector2.ZERO
	aim = Vector2.RIGHT
	dash_left = 0.0
	dash_cooldown = 0.0
	grounded = true
	air_dashes = 2
	air_jump = true
	shots.clear()
	hits = 0
	casts = 0
	clock = 0.0
	last_space = -10.0
	jump_requested = false
	dash_requested = false
	cast_requested = false
	_cancel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		last_space = -10.0
		signing = false
		sequence = ""
		jump_requested = false
		dash_requested = false
		cast_requested = false

func _center() -> Vector2:
	return pos - Vector2(0, 28)

func _screen_origin() -> Vector2:
	return get_viewport_rect().size * 0.5 - camera * zoom

func _physics_process(delta: float) -> void:
	accumulator += delta
	while accumulator >= STEP - 0.0000001:
		accumulator -= STEP
		_step(STEP)

func _step(dt: float) -> void:
	clock += dt
	message_left = maxf(0.0, message_left - dt)
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	if not prepared_spell.is_empty():
		ready_left = maxf(0.0, ready_left - dt)
		if ready_left <= 0.0:
			prepared_spell = ""
			_notice("Technique expired")
	_update_aim()
	if jump_requested:
		if dash_left <= 0.0 and (grounded or air_jump):
			if not grounded:
				air_jump = false
			grounded = false
			vel.y = JUMP
		jump_requested = false
	if dash_requested:
		_start_dash(aim)
		dash_requested = false
	if cast_requested:
		_cast()
		cast_requested = false
	if dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - dt)
		vel = dash_direction * DASH_SPEED
		if dash_left <= 0.0:
			vel *= 0.42
	else:
		if signing and not latch_mode:
			# Maintain momentum; ground friction gently slows coasting.
			vel.x = move_toward(vel.x, 0.0, (330.0 if grounded else 60.0) * dt)
		else:
			var x := latched if signing else _axis()
			vel.x = move_toward(vel.x, x * RUN, (2900.0 if grounded else 1350.0) * dt)
		if not grounded:
			vel.y += GRAVITY * dt
		elif vel.y > 0:
			vel.y = 0
	pos += vel * dt
	pos.x = clampf(pos.x, 24.0, WORLD_W - 24.0)
	if pos.y < 62.0:
		pos.y = 62.0
		vel.y = maxf(vel.y, 0.0)
		dash_left = 0.0
	if pos.y >= FLOOR:
		if not grounded:
			air_jump = true
			air_dashes = 2
		pos.y = FLOOR
		grounded = true
		vel.y = 0.0
		if dash_direction.y > 0.05:
			dash_left = 0.0
	else:
		grounded = false
	if moving_target:
		target = Vector2(1350.0 + sin(clock * 0.73) * 520.0, FLOOR - 30.0 - pow(maxf(0.0, sin(clock * 1.3)), 1.5) * 245.0)
	else:
		target = Vector2(1350, FLOOR - 30)
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var old: Vector2 = s["p"]
		var next: Vector2 = old + Vector2(s["v"]) * dt
		s["p"] = next
		s["life"] -= dt
		if Geometry2D.get_closest_point_to_segment(target, old, next).distance_to(target) <= float(s["r"]) + 20.0:
			hits += 1
			_notice("Hit!  " + str(hits))
			shots.remove_at(i)
		elif s["life"] <= 0.0 or next.x < 0 or next.x > WORLD_W or next.y < 0 or next.y > FLOOR:
			shots.remove_at(i)
		else:
			shots[i] = s
	var focus := (pos + target) * 0.5 - Vector2(0, 65)
	var dims := get_viewport_rect().size
	var wanted_zoom := clampf(minf((dims.x - 180.0) / (absf(pos.x - target.x) + 200.0), (dims.y - 170.0) / (absf(pos.y - target.y) + 170.0)), 0.33, 1.15)
	zoom = lerpf(zoom, wanted_zoom, minf(dt * 5.0, 1.0))
	camera = camera.lerp(focus, minf(dt * 6.0, 1.0))
	queue_redraw()

func _start_dash(d: Vector2, free: bool = false) -> bool:
	if not free and (dash_cooldown > 0.0 or dash_left > 0.0 or (not grounded and air_dashes <= 0)):
		return false
	if not free and not grounded:
		air_dashes -= 1
	# Ground dashes cannot point into the ground.
	if grounded and d.y > 0.0:
		d = Vector2(signf(d.x) if absf(d.x) > 0.05 else 1.0, 0)
	dash_direction = d.normalized()
	dash_left = 0.18
	dash_cooldown = 0.32
	if dash_direction.y < -0.05:
		grounded = false
	return true

func _cast() -> void:
	if prepared_spell.is_empty():
		return
	var spell := prepared_spell
	prepared_spell = ""
	ready_left = 0.0
	casts += 1
	if spell == "Rush":
		_start_dash(aim, true)
		_notice("Rush released")
	else:
		var orb := spell == "Orb"
		shots.append({"p":_center() + aim * 28.0, "v":aim * (610.0 if orb else 1250.0), "r":24.0 if orb else 9.0, "life":2.8 if orb else 1.8, "c":GOLD if orb else BLUE})
		_notice(spell + " released")

func _label(at: Vector2, value: String, size: int = 14, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _fighter(p: Vector2, color: Color, facing: float) -> void:
	# Diagnostic silhouette only, not a candidate animation.
	draw_circle(p - Vector2(0, 48), 10, color)
	draw_line(p - Vector2(0, 36), p - Vector2(0, 16), color, 6.0, true)
	draw_line(p - Vector2(0, 31), p + Vector2(facing * 17, -26), color, 5.0, true)
	draw_line(p - Vector2(0, 30), p + Vector2(-facing * 13, -22), color.darkened(0.2), 5.0, true)
	draw_line(p - Vector2(0, 16), p + Vector2(-10, 0), color, 5.0, true)
	draw_line(p - Vector2(0, 16), p + Vector2(10, 0), color, 5.0, true)

func _draw() -> void:
	var dims := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, dims), Color("#101a28"))
	draw_set_transform(_screen_origin(), 0.0, Vector2(zoom, zoom))
	for x in range(0, int(WORLD_W)+1, 100):
		draw_line(Vector2(x, 0), Vector2(x, FLOOR), Color("#26384b"), 1.0)
	for y in range(0, int(FLOOR), 100):
		draw_line(Vector2(0, y), Vector2(WORLD_W, y), Color("#26384b"), 1.0)
	draw_rect(Rect2(0, FLOOR, WORLD_W, 100), Color("#29394a"))
	draw_line(Vector2(0, FLOOR), Vector2(WORLD_W, FLOOR), Color("#7890a7"), 2.0)
	draw_rect(Rect2(0, 0, WORLD_W, FLOOR), Color("#526477"), false, 2.0)
	draw_line(_center(), _center() + aim * 105.0, Color(BLUE, 0.55), 2.0)
	_fighter(pos, BLUE, 1.0 if aim.x >= 0 else -1.0)
	_fighter(target + Vector2(0, 30), RED, -1.0 if pos.x < target.x else 1.0)
	draw_circle(target, 20, Color(RED, 0.15))
	for s in shots:
		draw_circle(s["p"], s["r"], s["c"])
	var above := pos - Vector2(0, 88)
	if signing and not sequence.is_empty():
		for i in range(sequence.length()):
			var q := above + Vector2((float(i) - float(sequence.length() - 1) * 0.5) * 25.0, 0)
			draw_rect(Rect2(q - Vector2(11, 19), Vector2(22, 23)), Color("#36465b"))
			_label(q + Vector2(-6, -2), sequence[i], 18, GOLD)
	if not prepared_spell.is_empty():
		var bar := above + Vector2(-42, -35 if signing else 0)
		_label(bar + Vector2(0, -5), prepared_spell, 18, GOLD)
		draw_rect(Rect2(bar, Vector2(84, 5)), Color("#3e4f60"))
		draw_rect(Rect2(bar, Vector2(84.0 * ready_left / READY_TIME, 5)), GOLD)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0, 0, dims.x, 90), Color("#111a27"))
	_label(Vector2(16, 24), "N / mobility + hand signs   |   60 Hz sandbox", 20, BLUE)
	_label(Vector2(16, 47), "WASD aim / A D move   SPACE jump   SHIFT + WASD signs   J cast   " + LAYOUTS[layout], 14)
	_label(Vector2(16, 69), "Arrows: optional independent aim   L / ESC cancel   F2 coast/latch   F3 target   F4 layout   R reset", 14)
	_label(Vector2(dims.x - 230, 24), "Mode: " + ("LATCH" if latch_mode else "COAST"), 15, GOLD)
	var bottom := dims.y - 86.0
	draw_rect(Rect2(0, bottom, dims.x, 86), Color("#111a27"))
	_label(Vector2(16, bottom + 21), "BOLT: W D S     ORB: S W D W     RUSH: A D W", 16, GOLD)
	_label(Vector2(16, bottom + 44), "Air dashes: %d/2    Double jump: %s    Casts: %d    Hits: %d" % [air_dashes, "ready" if air_jump else "used", casts, hits], 14)
	var status := ("Signs: " + sequence) if signing else "Move freely"
	if layout == 1 and not signing and prepared_spell.is_empty():
		status = "Quick double SPACE: dash / later SPACE: double jump"
	if not prepared_spell.is_empty():
		status += "   |   " + prepared_spell + " %.1fs" % ready_left
	_label(Vector2(16, bottom + 67), status + ("   |   " + message if message_left > 0 else ""), 14, BLUE)
