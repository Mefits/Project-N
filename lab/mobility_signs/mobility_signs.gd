extends Node2D
## Isolated control experiment, independent of the existing arena and animation rig.
const STEP := 1.0 / 60.0
const WORLD_W := 2700.0
const FLOOR := 790.0
const RUN := 420.0
const GRAVITY := 1250.0
const JUMP := -760.0
const DASH_SPEED := 850.0
const MOTOR_GROUND := 2900.0
const MOTOR_AIR := 1350.0
const READY_TIME := 8.0
const RECIPES := {"ASD": "Bolt", "ADAD": "Orb", "ASDAS": "Spikes"}
const MELEE_RANGE := 76.0
const SPIKE_HEIGHT := 108.0
const SPIKE_WIDTH := 190.0
const MAX_HP := 100
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
var moving_target := true
var hp := MAX_HP
var enemy_hp := MAX_HP
var enemy_vel := Vector2.ZERO
var enemy_grounded := true
var enemy_hurt := 0.0
var hurt := 0.0
var melee_left := 0.0
var enemy_attack_left := 0.0
var enemy_cooldown := 0.0
var enemy_facing := -1.0
var facing := 1.0
var attack_requested := false
var guarding := false
var melee_facing := 1.0
var spikes: Array[Dictionary] = []
var blocks := 0
var show_hitboxes := true
var debug_strikes: Array[Dictionary] = []
const STRIKE_BACK_MARGIN := 10.0
const DEBUG_FLASH := 0.13
const ATTACK_COLOR := Color("#ff7979")
const WINDUP_COLOR := Color("#f2d278")
var shots: Array[Dictionary] = []
var hits := 0
var casts := 0
var message := "Try A S D while holding SHIFT"
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
		signing = true
		sign_done = false
		sequence = ""
	elif not down:
		if signing and not sign_done and RECIPES.has(sequence):
			_prepare(String(RECIPES[sequence]))
		signing = false
		sequence = ""

func _prepare(spell: String) -> void:
	prepared_spell = spell
	ready_left = READY_TIME
	sign_done = true
	_notice(spell + " ready - J to release")

func _seal_key() -> int:
	return KEY_SHIFT

func _aim_from_keys(move: Vector2, arrows: Vector2) -> void:
	if arrows.length_squared() > 0.0:
		aim = arrows.normalized()
	elif not signing and move.length_squared() > 0.0:
		aim = move.normalized()

func _update_aim(down_as_aim: bool = true) -> void:
	var move := Vector2(_axis(), float(int(down_as_aim and Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))))
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
				var longer := false
				for recipe in RECIPES:
					if String(recipe).length() > sequence.length() and String(recipe).begins_with(sequence):
						longer = true
				if RECIPES.has(sequence):
					if not longer:
						_prepare(String(RECIPES[sequence]))
					else:
						_notice("Release SHIFT for Bolt, or continue A S")
				elif not longer:
					_notice("Wrong seal - try again")
					sequence = ""
			return
		match k:
			KEY_SPACE: _space_press()
			KEY_K: dash_requested = true
			KEY_J:
				if signing and not sign_done and RECIPES.has(sequence):
					_prepare(String(RECIPES[sequence]))
				cast_requested = true
			KEY_H: attack_requested = true
			KEY_F3:
				moving_target = not moving_target
				enemy_vel = Vector2.ZERO
				enemy_attack_left = 0.0
			KEY_F1:
				show_hitboxes = not show_hitboxes
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
	spikes.clear()
	debug_strikes.clear()
	hp = MAX_HP
	enemy_hp = MAX_HP
	target = Vector2(1250, FLOOR - 30)
	enemy_vel = Vector2.ZERO
	enemy_grounded = true
	enemy_hurt = 0.0
	hurt = 0.0
	melee_left = 0.0
	enemy_attack_left = 0.0
	enemy_cooldown = 0.0
	enemy_facing = -1.0
	facing = 1.0
	guarding = false
	attack_requested = false
	blocks = 0
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

func _move_horizontal(x: float, dt: float) -> void:
	# Same ordinary M3 motor for acceleration and braking, with or without seals.
	vel.x = move_toward(vel.x, x * RUN, (MOTOR_GROUND if grounded else MOTOR_AIR) * dt)

func _try_jump(x: float) -> bool:
	if not grounded and not air_jump:
		return false
	if not grounded:
		air_jump = false
	grounded = false
	# A new jump discards the previous velocity, including any ongoing dash.
	dash_left = 0.0
	vel = Vector2(x * RUN, JUMP)
	return true

func _guard_intent(s_down: bool) -> bool:
	# S is guard except when it belongs to a seal or a directional action.
	return s_down and not signing and not dash_requested and not cast_requested and hurt <= 0.0 and melee_left <= 0.0 and dash_left <= 0.0

func _melee_contains(origin: Vector2, direction: float, radius: float, point: Vector2) -> bool:
	var delta := point - origin
	return delta.length_squared() <= radius * radius and delta.x * direction >= -STRIKE_BACK_MARGIN

func _spike_hit_area(s: Dictionary) -> Rect2:
	return Rect2(float(s["x"]), FLOOR - SPIKE_HEIGHT, SPIKE_WIDTH, SPIKE_HEIGHT).grow(18.0)

func _remember_strike(origin: Vector2, direction: float, radius: float) -> void:
	# Snapshot the actual instantaneous hit check, not a moving recovery hitbox.
	debug_strikes.append({"origin":origin, "direction":direction, "radius":radius, "life":DEBUG_FLASH})

func _step(dt: float) -> void:
	if hp <= 0 or enemy_hp <= 0:
		queue_redraw()
		return
	clock += dt
	for i in range(debug_strikes.size() - 1, -1, -1):
		debug_strikes[i]["life"] -= dt
		if debug_strikes[i]["life"] <= 0.0:
			debug_strikes.remove_at(i)
	hurt = maxf(0.0, hurt - dt)
	enemy_hurt = maxf(0.0, enemy_hurt - dt)
	melee_left = maxf(0.0, melee_left - dt)
	message_left = maxf(0.0, message_left - dt)
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	if not prepared_spell.is_empty():
		ready_left = maxf(0.0, ready_left - dt)
		if ready_left <= 0.0:
			prepared_spell = ""
			_notice("Technique expired")
	var s_down := Input.is_physical_key_pressed(KEY_S)
	# Holding S alone cannot redirect aim down; S+J/K can.
	_update_aim(not s_down or (not signing and (dash_requested or cast_requested)))
	if absf(aim.x) > 0.05:
		facing = signf(aim.x)
	guarding = _guard_intent(s_down)
	var move_x := 0.0 if signing or guarding or hurt > 0.0 else _axis()
	if attack_requested:
		if not guarding and hurt <= 0.0 and melee_left <= 0.0:
			_melee()
		attack_requested = false
	if jump_requested:
		if hurt <= 0.0 and not guarding:
			_try_jump(move_x)
		jump_requested = false
	if dash_requested:
		if hurt <= 0.0 and not guarding:
			_start_dash(aim)
		dash_requested = false
	if cast_requested:
		if hurt <= 0.0 and not guarding:
			_cast()
		cast_requested = false
	if dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - dt)
		vel = dash_direction * DASH_SPEED
		if dash_left <= 0.0:
			vel *= 0.42
	else:
		_move_horizontal(move_x, dt)
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
	_update_enemy(dt)
	_update_spikes(dt)
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var old: Vector2 = s["p"]
		var next: Vector2 = old + Vector2(s["v"]) * dt
		s["p"] = next
		s["life"] -= dt
		if Geometry2D.get_closest_point_to_segment(target, old, next).distance_to(target) <= float(s["r"]) + 20.0:
			_hit_enemy(int(s["damage"]), Vector2(s["v"]).normalized() * 270.0 + Vector2(0, -65))
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

func _melee() -> void:
	melee_left = 0.32
	melee_facing = facing
	_remember_strike(_center(), melee_facing, MELEE_RANGE)
	if _melee_contains(_center(), melee_facing, MELEE_RANGE, target):
		_hit_enemy(9, Vector2(melee_facing * 300.0, -155.0))
	else:
		_notice("Melee miss")

func _hit_enemy(damage: int, impulse: Vector2) -> void:
	if enemy_hp <= 0:
		return
	enemy_hp = maxi(0, enemy_hp - damage)
	enemy_hurt = 0.24
	enemy_vel = impulse
	enemy_grounded = false
	enemy_attack_left = 0.0
	enemy_cooldown = 0.4
	hits += 1
	_notice("Hit!  " + str(hits))

func _hit_player(damage: int, impulse: Vector2, source: Vector2) -> void:
	if hp <= 0 or hurt > 0.0:
		return
	# Simple frontal guard, including air; no parry or resource cost.
	if guarding and (source.x - pos.x) * facing >= -3.0:
		blocks += 1
		vel.x = impulse.x * 0.22
		_notice("Blocked")
		return
	hp = maxi(0, hp - damage)
	hurt = 0.23
	dash_left = 0.0
	melee_left = 0.0
	vel = impulse
	grounded = false
	# Do not modify signing, sequence, prepared_spell or ready_left.
	_notice("Hit received")

func _update_enemy(dt: float) -> void:
	enemy_cooldown = maxf(0.0, enemy_cooldown - dt)
	var delta := _center() - target
	if enemy_attack_left > 0.0:
		var old := enemy_attack_left
		enemy_attack_left = maxf(0.0, old - dt)
		if old > 0.12 and enemy_attack_left <= 0.12:
			_remember_strike(target, enemy_facing, MELEE_RANGE + 8.0)
			if _melee_contains(target, enemy_facing, MELEE_RANGE + 8.0, _center()):
				_hit_player(8, Vector2(enemy_facing * 330.0, -120.0), target)
	if enemy_hurt <= 0.0:
		if moving_target and enemy_attack_left <= 0.0:
			if absf(delta.x) > 4.0:
				enemy_facing = signf(delta.x)
			if delta.length() <= MELEE_RANGE and enemy_cooldown <= 0.0:
				enemy_attack_left = 0.30
				enemy_cooldown = 0.95
				enemy_vel.x = 0.0
			else:
				var desired := enemy_facing * 345.0 if absf(delta.x) > 42.0 else 0.0
				enemy_vel.x = move_toward(enemy_vel.x, desired, 1700.0 * dt)
				if enemy_grounded and delta.y < -95.0:
					enemy_vel.y = JUMP * 0.94
					enemy_grounded = false
		else:
			enemy_vel.x = move_toward(enemy_vel.x, 0.0, 1300.0 * dt)
	else:
		enemy_vel.x = move_toward(enemy_vel.x, 0.0, 200.0 * dt)
	if not enemy_grounded:
		enemy_vel.y += GRAVITY * dt
	target += enemy_vel * dt
	target.x = clampf(target.x, 24.0, WORLD_W - 24.0)
	if target.y >= FLOOR - 30.0:
		target.y = FLOOR - 30.0
		enemy_vel.y = 0.0
		enemy_grounded = true
	elif target.y < 32.0:
		target.y = 32.0
		enemy_vel.y = maxf(enemy_vel.y, 0.0)

func _update_spikes(dt: float) -> void:
	for i in range(spikes.size() - 1, -1, -1):
		var s: Dictionary = spikes[i]
		s["age"] += dt
		var age: float = s["age"]
		if age >= 0.65:
			spikes.remove_at(i)
			continue
		if age >= 0.22 and age < 0.48 and not s["hit"]:
			if _spike_hit_area(s).has_point(target):
				s["hit"] = true
				_hit_enemy(20, Vector2(float(s["dir"]) * 170.0, -420.0))
		spikes[i] = s

func _start_dash(d: Vector2) -> bool:
	if dash_cooldown > 0.0 or dash_left > 0.0 or (not grounded and air_dashes <= 0):
		return false
	if not grounded:
		air_dashes -= 1
	# Ground dashes cannot point into the ground.
	if grounded and d.y > 0.0:
		d = Vector2(signf(d.x) if absf(d.x) > 0.05 else facing, 0)
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
	if spell == "Spikes":
		var edge := pos.x + (35.0 if facing > 0 else -35.0 - SPIKE_WIDTH)
		spikes.append({"x":clampf(edge, 0.0, WORLD_W - SPIKE_WIDTH), "dir":facing, "age":0.0, "hit":false})
	else:
		var orb := spell == "Orb"
		shots.append({"p":_center() + aim * (40.0 if orb else 28.0), "v":aim * (488.0 if orb else 1250.0), "r":36.0 if orb else 9.0, "life":2.8 if orb else 1.8, "c":GOLD if orb else BLUE, "damage":16 if orb else 8})
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

func _draw_strike_zone(origin: Vector2, direction: float, radius: float, color: Color, solid: bool) -> void:
	# Circle clipped by the same rear margin as _melee_contains.
	var angle := acos(-STRIKE_BACK_MARGIN / radius)
	var polygon := PackedVector2Array()
	for i in range(49):
		var a := lerpf(-angle, angle, float(i) / 48.0)
		polygon.append(origin + Vector2(cos(a) * direction, sin(a)) * radius)
	if solid:
		draw_colored_polygon(polygon, Color(color, 0.18))
	polygon.append(polygon[0])
	draw_polyline(polygon, color, 1.8, true)

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
	_fighter(pos, BLUE.lightened(0.4) if hurt > 0 else BLUE, facing)
	_fighter(target + Vector2(0, 30), RED.lightened(0.4) if enemy_hurt > 0 else RED, enemy_facing)
	if guarding:
		draw_arc(_center(), 34.0, -1.3 if facing > 0 else 1.84, 1.3 if facing > 0 else 4.44, 22, BLUE, 4.0, true)
	if melee_left > 0.20:
		draw_line(_center(), _center() + Vector2(melee_facing * MELEE_RANGE, 0), BLUE, 6.0, true)
	if enemy_attack_left > 0.0:
		draw_arc(target, 32.0, 0.0, TAU, 24, GOLD if enemy_attack_left > 0.12 else RED, 3.0, true)
		if enemy_attack_left <= 0.12:
			draw_line(target, target + Vector2(enemy_facing * MELEE_RANGE, 0), RED, 6.0, true)
	for s in spikes:
		var x: float = s["x"]
		var age: float = s["age"]
		draw_rect(Rect2(x, FLOOR - 5.0, SPIKE_WIDTH, 5.0), GOLD)
		if age >= 0.22:
			var h := SPIKE_HEIGHT * clampf((age - 0.22) / 0.065, 0.0, 1.0) * clampf((0.65 - age) / 0.17, 0.0, 1.0)
			for i in range(5):
				var sx := x + 38.0 * i
				draw_colored_polygon(PackedVector2Array([Vector2(sx, FLOOR), Vector2(sx + 20.0, FLOOR - h * (0.8 + 0.2 * (i % 2))), Vector2(sx + 38.0, FLOOR)]), Color("#b4a087"))
	for s in shots:
		draw_circle(s["p"], s["r"], s["c"])
	if show_hitboxes:
		# The projectile test uses swept projectile radius against the target's 20px circle.
		draw_arc(target, 20.0, 0.0, TAU, 40, Color("#9cddae"), 1.5, true)
		draw_circle(target, 2.5, Color("#9cddae"))
		draw_circle(_center(), 2.5, Color("#9cddae"))
		for s in shots:
			draw_arc(s["p"], s["r"], 0.0, TAU, 40, ATTACK_COLOR, 2.0, true)
		for s in spikes:
			var age: float = s["age"]
			var area := _spike_hit_area(s)
			if age < 0.22:
				draw_rect(area, WINDUP_COLOR, false, 1.8)
			elif age < 0.48 and not s["hit"]:
				draw_rect(area, Color(ATTACK_COLOR, 0.16))
				draw_rect(area, ATTACK_COLOR, false, 1.8)
		if enemy_attack_left > 0.12:
			_draw_strike_zone(target, enemy_facing, MELEE_RANGE + 8.0, WINDUP_COLOR, false)
		for z in debug_strikes:
			_draw_strike_zone(z["origin"], z["direction"], z["radius"], ATTACK_COLOR, true)
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
	_label(Vector2(16, 24), "N / M5.2 combat + seals", 20, BLUE)
	_label(Vector2(16, 47), "WASD aim / A D move   SPACE jump   SHIFT + WASD signs   J cast   " + LAYOUTS[layout], 14)
	_label(Vector2(16, 69), "H melee   S guard   ESC cancel   F1 hitboxes   F3 AI   F4 layout   R reset", 14)
	_label(Vector2(dims.x - 255, 24), ("BOX ON" if show_hitboxes else "BOX OFF") + " / " + ("AI ON" if moving_target else "AI OFF"), 15, GOLD)
	var hp_width := 140.0
	_label(Vector2(16, 86), "P1 %d" % hp, 12, BLUE)
	draw_rect(Rect2(80, 76, hp_width, 9), Color("#34485c"))
	draw_rect(Rect2(80, 76, hp_width * hp / MAX_HP, 9), BLUE)
	_label(Vector2(dims.x - 212, 86), "CPU %d" % enemy_hp, 12, RED)
	draw_rect(Rect2(dims.x - 156, 76, hp_width, 9), Color("#34485c"))
	draw_rect(Rect2(dims.x - 156, 76, hp_width * enemy_hp / MAX_HP, 9), RED)
	if hp <= 0 or enemy_hp <= 0:
		_label(dims * 0.5 - Vector2(90, 0), ("WIN" if enemy_hp <= 0 else "DEFEAT") + " / R reset", 24, GOLD)
	var bottom := dims.y - 86.0
	draw_rect(Rect2(0, bottom, dims.x, 86), Color("#111a27"))
	_label(Vector2(16, bottom + 21), "BOLT: A S D     FIREBALL: A D A D     SPIKES: A S D A S", 16, GOLD)
	_label(Vector2(16, bottom + 44), "Air dashes: %d/2    Double jump: %s    Casts: %d    Hits: %d" % [air_dashes, "ready" if air_jump else "used", casts, hits], 14)
	var status := ("Signs: " + sequence) if signing else "Move freely"
	if layout == 1 and not signing and prepared_spell.is_empty():
		status = "Quick double SPACE: dash / later SPACE: double jump"
	if not prepared_spell.is_empty():
		status += "   |   " + prepared_spell + " %.1fs" % ready_left
	_label(Vector2(16, bottom + 67), status + ("   |   " + message if message_left > 0 else ""), 14, BLUE)
