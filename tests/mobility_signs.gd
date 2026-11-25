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

func _run() -> void:
	var lab = load("res://lab/mobility_signs/mobility_signs.tscn").instantiate()
	if not lab.has_method("_step"):
		push_error("Sandbox script failed to load")
		quit(1)
		return
	root.add_child(lab)
	lab.set_physics_process(false)
	check(not lab.moving_target, "AI starts disabled")
	lab.moving_target = false
	check(lab.layout == 0, "keyboard default coast")
	lab._aim_from_keys(Vector2(1, -1), Vector2.ZERO)
	check(lab.aim.is_equal_approx(Vector2(1, -1).normalized()), "diagonal aim")
	key(lab, KEY_SHIFT)
	lab._aim_from_keys(Vector2(-1, 0), Vector2.ZERO)
	check(lab.aim.is_equal_approx(Vector2(1, -1).normalized()), "seal input does not redirect aim")
	lab._aim_from_keys(Vector2.ZERO, Vector2.UP)
	check(lab.aim == Vector2.UP, "arrow override during seals")
	key(lab, KEY_A)
	key(lab, KEY_S)
	key(lab, KEY_D)
	check(lab.sequence == "ASD" and lab.prepared_spell.is_empty(), "ASD is pending longer prefix")
	key(lab, KEY_SHIFT, false)
	check(lab.prepared_spell == "Bolt" and not lab.dash_requested, "release confirms Bolt")
	key(lab, KEY_K)
	check(lab.cast_requested, "K casts")
	lab._step(1.0 / 60.0)
	check(lab.casts == 1 and lab.prepared_spell.is_empty(), "keyboard cast consumed")
	key(lab, KEY_J)
	check(lab.dash_requested, "J dash")
	lab._reset()
	key(lab, KEY_F4)
	check(lab.layout == 1, "double tap layout")
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
	check(lab.layout == 0, "restore standard keyboard")
	key(lab, KEY_SHIFT)
	key(lab, KEY_A)
	key(lab, KEY_S)
	key(lab, KEY_D)
	key(lab, KEY_SHIFT, false)
	check(lab.prepared_spell == "Bolt", "ASD release prepares Bolt")
	check(is_equal_approx(lab.ready_left, 8.0), "ready duration")
	check(not lab.signing and lab.prepared_spell == "Bolt", "release modifier preserves prepared spell")
	lab._cast()
	check(lab.shots.size() == 1 and lab.prepared_spell.is_empty(), "cast consumes spell")
	check(lab.casts == 1, "cast counter")
	lab._reset()
	key(lab, KEY_SHIFT)
	key(lab, KEY_A)
	key(lab, KEY_D)
	key(lab, KEY_A)
	key(lab, KEY_D)
	check(lab.prepared_spell == "Orb", "ADAD prepares Orb")
	lab.ready_left = 0.01
	lab._step(1.0 / 60.0)
	check(lab.prepared_spell.is_empty(), "expiry")
	key(lab, KEY_SHIFT, false)
	key(lab, KEY_SHIFT)
	key(lab, KEY_W)
	key(lab, KEY_W)
	check(lab.sequence.is_empty(), "invalid prefix resets")
	lab._cancel()
	check(not lab.signing and lab.prepared_spell.is_empty(), "cancel")
	lab._reset()
	lab.vel.x = 400
	key(lab, KEY_SHIFT)
	lab._step(1.0 / 60.0)
	check(is_equal_approx(lab.vel.x, 389.0) and lab.pos.x > 800, "M4 light coast during seals")
	key(lab, KEY_SHIFT, false)
	lab.vel.x = 400.0
	lab._step(1.0 / 60.0)
	check(is_equal_approx(lab.vel.x, 389.0), "identical M4 light coast without seals")
	lab.grounded = false
	lab.pos.y = 400.0
	lab.vel.x = 400.0
	lab._move_horizontal(0.0, 1.0 / 60.0)
	check(is_equal_approx(lab.vel.x, 398.0), "M4 light air coast")
	lab.vel = Vector2(850, 140)
	lab.dash_left = 0.1
	check(lab._try_jump(-1.0), "jump cancels ongoing dash")
	check(lab.vel == Vector2(-420, -760) and lab.dash_left == 0.0 and not lab.air_jump, "jump resets both axes and reverses")
	check(not lab._try_jump(1.0), "no extra jump without landing")
	lab._cancel()
	lab._reset()
	lab.grounded = false
	lab.pos.y = 400
	check(lab._start_dash(Vector2.RIGHT), "air dash")
	check(lab.air_dashes == 1, "air charge consumed")
	lab._step(1.0 / 60.0)
	check(is_equal_approx(lab.vel.length(), 850.0), "dash speed halved")
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
	lab._reset()
	key(lab, KEY_SHIFT)
	key(lab, KEY_A)
	key(lab, KEY_S)
	key(lab, KEY_D)
	key(lab, KEY_A)
	key(lab, KEY_S)
	check(lab.prepared_spell == "Spikes", "ASDAS longer sequence reachable")
	key(lab, KEY_SHIFT, false)
	lab.target = Vector2(lab.pos.x + 100.0, 760.0)
	lab._cast()
	check(lab.shots.is_empty() and lab.spikes.size() == 1, "spikes are ground hazard")
	lab._update_spikes(0.23)
	check(is_equal_approx(lab.enemy_hp, 100.0 - 20.0 / 3.0) and lab.enemy_vel.y < 0.0, "spike damage and launch")
	lab._update_spikes(0.10)
	check(is_equal_approx(lab.enemy_hp, 100.0 - 20.0 / 3.0), "spikes single hit")
	lab._reset()
	lab.prepared_spell = "Orb"
	lab._cast()
	check(lab.shots.size() == 1 and is_equal_approx(float(lab.shots[0]["r"]), 36.0) and is_equal_approx(Vector2(lab.shots[0]["v"]).length(), 488.0), "fireball size and speed")
	lab._reset()
	key(lab, KEY_SHIFT)
	key(lab, KEY_A)
	key(lab, KEY_S)
	lab._hit_player(8, Vector2(-330,-120), lab.pos + Vector2(40,0))
	check(is_equal_approx(lab.hp, 100.0 - 8.0 / 3.0) and lab.signing and lab.sequence == "AS" and lab.hurt > 0.0, "damage preserves signs")
	key(lab, KEY_D)
	key(lab, KEY_SHIFT, false)
	check(lab.prepared_spell == "Bolt", "finish signs during hurt")
	lab._reset()
	lab.guarding = true
	lab._hit_player(8, Vector2(-330,-120), lab.pos + Vector2(40,0))
	check(lab.hp == 100 and lab.blocks == 1, "frontal guard")
	lab._hit_player(8, Vector2(330,-120), lab.pos - Vector2(40,0))
	check(is_equal_approx(lab.hp, 100.0 - 8.0 / 3.0), "rear hit")
	lab._reset()
	lab.target = lab._center() + Vector2(50,0)
	key(lab, KEY_H)
	lab._step(1.0 / 60.0)
	check(lab.enemy_hp == 97 and lab.melee_left > 0.0, "melee contact")
	lab._reset()
	lab.moving_target = true
	lab.target = lab._center() + Vector2(50,0)
	for i in range(25):
		lab._step(1.0 / 60.0)
	check(is_equal_approx(lab.hp, 100.0 - 8.0 / 3.0), "AI telegraphed melee hits")
	lab._reset()
	lab.moving_target = false
	check(lab._guard_intent(true) and not lab._guard_intent(false), "S alone guards")
	key(lab, KEY_SHIFT)
	key(lab, KEY_S)
	check(lab.sequence == "" and not lab._guard_intent(true), "Shift+S is seal input not guard")
	key(lab, KEY_SHIFT, false)
	key(lab, KEY_J)
	check(not lab._guard_intent(true), "S+J prioritizes dash")
	lab.dash_requested = false
	key(lab, KEY_K)
	check(not lab._guard_intent(true), "S+K prioritizes cast")
	lab.cast_requested = false
	check(lab._guard_intent(true), "guard resumes after action")
	lab.dash_left = 0.1
	check(not lab._guard_intent(true), "no guard during dash")
	lab._reset()
	lab.facing = -1.0
	check(lab._start_dash(Vector2.DOWN) and lab.dash_direction == Vector2.LEFT, "ground down dash follows facing")
	lab._reset()
	lab.target = lab._center() + Vector2(50,0)
	lab._melee()
	check(lab.debug_strikes.size() == 1 and lab.debug_strikes[0]["origin"] == lab._center(), "debug snapshot matches melee origin")
	check(lab._melee_contains(Vector2.ZERO, 1.0, 76.0, Vector2(76,0)), "front edge included")
	check(not lab._melee_contains(Vector2.ZERO, 1.0, 76.0, Vector2(-11,0)), "rear margin excluded")
	check(not lab._melee_contains(Vector2.ZERO, 1.0, 76.0, Vector2(77,0)), "range boundary excluded")
	check(lab._spike_hit_area({"x":100.0}) == Rect2(82,664,226,144), "spike overlay matches effective area")
	check(lab.show_hitboxes, "hitbox display default on")
	key(lab, KEY_F1)
	check(not lab.show_hitboxes, "F1 hides hitboxes")
	key(lab, KEY_F1)
	check(lab.show_hitboxes, "F1 shows hitboxes")
	# Buffered light-light-finisher with actual simulated ticks and CPU defense.
	lab._reset()
	lab.moving_target = true
	lab.clock = 1.40
	lab.target = lab._center() + Vector2(60, 0)
	lab.enemy_grounded = true
	lab.enemy_attack_left = 0.0
	key(lab, KEY_H)
	lab._step(1.0 / 60.0)
	check(lab.combo_stage == 1 and lab.enemy_hp == 97 and lab.enemy_hurt > 0.28, "first light hit confirms")
	lab._queue_melee(Vector2.RIGHT)
	lab._queue_melee(Vector2.UP)
	for i in range(8):
		lab._step(1.0 / 60.0)
	check(lab.combo_stage == 2 and lab.enemy_hp == 94 and lab.enemy_hurt > 0.27, "second light inside first stun")
	check(not lab.enemy_guarding, "CPU cannot guard between light hits")
	for i in range(8):
		lab._step(1.0 / 60.0)
	check(lab.combo_stage == 0 and lab.enemy_hp == 88 and lab.enemy_vel.y < -600.0, "buffered upward finisher launches")
	check(lab.melee_left > 0.30 and lab.melee_queue.is_empty(), "finisher ends chain and recovers")
	lab._queue_melee(Vector2.RIGHT)
	check(lab.melee_queue.is_empty(), "no fourth hit during recovery")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1,-1).normalized()]:
		lab._reset()
		lab.moving_target = false
		lab.target = lab._center() + Vector2(50, 0)
		lab._melee()
		lab._melee()
		lab._melee(direction)
		check(lab.enemy_hp == 88 and lab.enemy_vel.is_equal_approx(direction * 680.0), "finisher independent launch vector " + str(direction))
	lab._reset()
	lab.moving_target = false
	lab.target = lab._center() + Vector2(110,0)
	lab._queue_melee(Vector2.RIGHT)
	lab._queue_melee(Vector2.RIGHT)
	lab._step(1.0 / 60.0)
	check(lab.enemy_hp == 100 and lab.combo_stage == 0 and lab.melee_queue.is_empty(), "miss ends buffered chain")
	lab._reset()
	lab.moving_target = true
	lab.clock = 1.8
	lab.target = lab._center() + Vector2(50,0)
	lab._queue_melee(Vector2.RIGHT)
	lab._step(1.0 / 60.0)
	check(lab.enemy_guarding and lab.enemy_hp == 100 and lab.combo_stage == 0, "CPU neutral guard blocks opener")
	lab._reset()
	lab.moving_target = false
	lab.target = lab._center() + Vector2(50,0)
	lab._melee()
	for i in range(18):
		lab._step(1.0 / 60.0)
	check(lab.combo_stage == 0, "late follow-up resets combo")
	lab._reset()
	lab.target = lab._center() + Vector2(50,0)
	lab._melee()
	lab._queue_melee(Vector2.RIGHT)
	lab._hit_player(8, Vector2.ZERO, lab.target)
	check(lab.combo_stage == 0 and lab.melee_queue.is_empty(), "player hit interrupts melee chain only")
	lab._reset()
	lab.moving_target = false
	lab.target = lab._center() + Vector2(50,0)
	lab.vel = Vector2(420,0)
	lab.dash_left = 0.1
	var start_x: float = lab.pos.x
	lab._melee()
	check(lab.vel == Vector2.ZERO and lab.dash_left == 0.0, "melee cancels run and dash momentum")
	for i in range(6):
		lab._advance_player_motion(1.0, 1.0 / 60.0)
	check(is_equal_approx(lab.pos.x, start_x), "held forward cannot move during attack")
	lab._advance_player_motion(-1.0, 1.0 / 60.0)
	check(is_equal_approx(lab.pos.x, start_x), "held back cannot move during attack")
	lab._queue_melee(Vector2.RIGHT)
	lab.jump_requested = true
	lab.dash_requested = true
	lab._step(1.0 / 60.0)
	check(lab.grounded and lab.dash_left == 0.0, "jump and dash do not override strike recovery")
	lab._reset()
	lab.grounded = false
	lab.pos.y = 400.0
	lab.target = lab._center() + Vector2(50,0)
	lab.enemy_grounded = false
	lab.vel = Vector2(-420,-350)
	lab._melee()
	check(lab.vel == Vector2.ZERO, "air attack stops old flight impulse")
	lab._advance_player_motion(1.0, 1.0 / 60.0)
	check(is_zero_approx(lab.vel.x) and lab.vel.y > 0.0, "air attack retains gravity")
	lab._reset()
	lab.vel = Vector2(420,0)
	lab.dash_left = 0.1
	lab._hit_player(8, Vector2(-330,-120), lab.target)
	check(lab.vel == Vector2(-330,-120) and lab.dash_left == 0.0, "damage replaces previous velocity with knockback")
	lab._advance_player_motion(1.0, 1.0 / 60.0)
	check(lab.vel.x < 0.0, "held movement cannot override knockback during stun")
	lab.hurt = 0.0
	lab.melee_left = 0.0
	lab.vel = Vector2.ZERO
	lab._advance_player_motion(1.0, 1.0 / 60.0)
	check(lab.vel.x > 0.0, "normal control resumes after recovery")
	lab._reset()
	lab.moving_target = false
	var dummy_start: Vector2 = lab.target
	for i in range(60):
		lab._step(1.0 / 60.0)
	check(lab.target == dummy_start and lab.hp == 100, "disabled AI stands still")
	key(lab, KEY_F3)
	check(lab.moving_target, "F3 enables AI")
	lab._reset()
	lab.vel.x = 420.0
	for i in range(12):
		lab._advance_player_motion(0.0, 1.0 / 60.0)
	check(is_equal_approx(lab.vel.x, 288.0), "accepted M4 ground glide over twelve ticks")
	lab._reset()
	lab.grounded = false
	lab.pos.y = 400.0
	lab.vel.x = 420.0
	for i in range(12):
		lab._advance_player_motion(0.0, 1.0 / 60.0)
	check(is_equal_approx(lab.vel.x, 396.0), "accepted M4 air glide over twelve ticks")
	lab._reset()
	lab._hit_enemy(16, Vector2.ZERO)
	check(is_equal_approx(lab.enemy_hp, 100.0 - 16.0 / 3.0), "fireball damage exactly one third")
	lab._hit_enemy(8, Vector2.ZERO)
	check(is_equal_approx(lab.enemy_hp, 92.0), "bolt and fireball exactly one third")
	print("Mobility signs smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)
