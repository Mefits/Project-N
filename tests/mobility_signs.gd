extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		push_error(label)
		failures += 1

func key(lab, code: int, down: bool = true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = down
	lab._input(e)

func mouse(lab, down: bool = true) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_RIGHT
	e.pressed = down
	lab._input(e)

func _run() -> void:
	var lab = load("res://lab/mobility_signs/mobility_signs.tscn").instantiate()
	if not lab.has_method("_step"):
		push_error("Sandbox script failed to load")
		quit(1)
		return
	root.add_child(lab)
	lab.set_physics_process(false)
	check(lab.layout == 0 and not lab.latch_mode, "new default: Shift seals, RMB dash, coast")
	key(lab, KEY_SHIFT)
	key(lab, KEY_W)
	key(lab, KEY_D)
	key(lab, KEY_S)
	check(lab.prepared_spell == "Bolt" and not lab.dash_requested, "Shift seals")
	key(lab, KEY_SHIFT, false)
	mouse(lab)
	check(lab.dash_requested and not lab.signing, "RMB dash")
	lab._reset()
	key(lab, KEY_F4)
	check(lab.layout == 1, "F4 cycle")
	mouse(lab)
	key(lab, KEY_A)
	key(lab, KEY_D)
	key(lab, KEY_W)
	check(lab.prepared_spell == "Rush" and lab.signing, "RMB seals")
	mouse(lab, false)
	key(lab, KEY_SHIFT)
	check(not lab.signing and lab.dash_requested, "Shift dash")
	lab._reset()
	key(lab, KEY_F4)
	check(lab.layout == 2, "double tap layout")
	key(lab, KEY_SPACE)
	check(lab.jump_requested and not lab.dash_requested, "first Space jumps")
	lab._step(1.0 / 60.0)
	key(lab, KEY_SPACE, false)
	key(lab, KEY_SPACE)
	check(lab.dash_requested and not lab.jump_requested, "quick second Space dashes")
	lab._reset()
	key(lab, KEY_SPACE)
	lab._step(1.0 / 60.0)
	lab.clock += 0.35
	key(lab, KEY_SPACE, false)
	key(lab, KEY_SPACE)
	check(lab.jump_requested and not lab.dash_requested, "late second Space jumps")
	lab._reset()
	key(lab, KEY_F4)
	mouse(lab)
	check(lab.layout == 3 and lab.signing, "RMB + double tap preset")
	mouse(lab, false)
	key(lab, KEY_F4)
	check(lab.layout == 4, "original Tab preset")
	lab._reset()
	key(lab, KEY_TAB)
	key(lab, KEY_W)
	key(lab, KEY_D)
	key(lab, KEY_S)
	check(lab.prepared_spell == "Bolt", "WDS prepares Bolt")
	check(is_equal_approx(lab.ready_left, 8.0), "ready duration")
	key(lab, KEY_TAB, false)
	check(not lab.signing and lab.prepared_spell == "Bolt", "release modifier preserves prepared spell")
	lab._cast()
	check(lab.shots.size() == 1 and lab.prepared_spell.is_empty(), "cast consumes spell")
	check(lab.casts == 1, "cast counter")
	lab._reset()
	key(lab, KEY_TAB)
	key(lab, KEY_A)
	key(lab, KEY_D)
	key(lab, KEY_W)
	check(lab.prepared_spell == "Rush", "ADW prepares Rush")
	lab.ready_left = 0.01
	lab._step(1.0 / 60.0)
	check(lab.prepared_spell.is_empty(), "expiry")
	key(lab, KEY_TAB, false)
	key(lab, KEY_TAB)
	key(lab, KEY_W)
	key(lab, KEY_W)
	check(lab.sequence.is_empty(), "invalid prefix resets")
	lab._cancel()
	check(not lab.signing and lab.prepared_spell.is_empty(), "cancel")
	lab._reset()
	lab.vel.x = 400
	key(lab, KEY_TAB)
	lab._step(1.0 / 60.0)
	check(lab.vel.x > 390 and lab.pos.x > 800, "coasting preserves motion")
	lab._cancel()
	lab._reset()
	lab.grounded = false
	lab.pos.y = 400
	check(lab._start_dash(Vector2.RIGHT), "air dash")
	check(lab.air_dashes == 1, "air charge consumed")
	lab.dash_left = 0.0
	lab.dash_cooldown = 0.0
	check(lab._start_dash(Vector2.UP), "second air dash")
	lab.dash_left = 0.0
	lab.dash_cooldown = 0.0
	check(not lab._start_dash(Vector2.RIGHT), "third air dash rejected")
	lab.pos.y = 790
	lab.vel = Vector2.ZERO
	lab._step(1.0 / 60.0)
	check(lab.air_dashes == 2 and lab.grounded, "landing restores charges")
	print("Mobility signs smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)
