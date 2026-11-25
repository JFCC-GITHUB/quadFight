extends Control
## Falling-block puzzle: SRS rotation, 7-bag, hold, ghost, DAS/ARR, lock delay,
## line-clear / drop / lock animations and sound. Also runs VS CPU mode (see `vs`).

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Pieces := preload("res://scripts/pieces.gd")
const Skill := preload("res://scripts/skill.gd")
const TouchLayout := preload("res://scripts/touch_layout.gd")
const OptionsScreen := preload("res://scripts/options.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")
const Characters := preload("res://scripts/characters.gd")
const Portrait := preload("res://scripts/portrait.gd")
const FxLayer := preload("res://scripts/fx_layer.gd")
const Fullscreen := preload("res://scripts/fullscreen.gd")

const COLS := 10
const ROWS := 20
const CELL := 30
const BOARD_POS := Vector2(120, 112)
const LEFT_X := 12.0
const RIGHT_X := 428.0
const COL_W := 100.0
const PAUSE_RECT := Rect2(16, 24, 56, 56)

const LOCK_DELAY := 0.5
const MAX_LOCK_RESETS := 15
const CLEAR_TIME := 0.38
const VS_MAX_GRAVITY_LEVEL := 7
const GARBAGE := 7

enum State { PLAYING, CLEARING, PAUSED, OVER }

var main: Node

# VS CPU mode: set by Main before the screen is added.
var vs := false
var cpu_level := 3
var cpu: RefCounted
var incoming := 0          # garbage blocks that will drop on the player
var combo := 0
var fall_fx := {}          # Vector2i(board cell) -> {t, dur}: landing animation of garbage blocks
var projectiles: Array = []
var char_id := "bastion"    # player's fighter (special attack, see characters.gd)
var cpu_char := ""            # the opponent fighter (Main passes it; empty = random)
var mode := "ladder"           # "ladder" | "tournament"
var round_no := 1              # tournament: which fight this is, of round_total
var round_total := 0
var st := {"sent": 0, "taken": 0, "blocked": 0, "combo": 0, "quads": 0, "specials": 0, "time": 0.0}  # VS fight stats
var last_fight := {}
var sk := {"pieces": 0, "time": 0.0, "keys": 0, "delay": 0.0, "delay_n": 0, "holes": 0}  # play record for the skill estimate
var play_t := 0.0
var spawn_t := 0.0
var got_key := false
var prev_holes := 0
var sk_saved := false
var last_est := -1.0
var have: Dictionary = {}      # line-clear sizes collected toward the player's special attack
var cpu_have: Dictionary = {}
var special_in: Array = []     # special attacks (character ids) waiting to land on the player's board
var fx_layer: Control
var special_flash := 0.0
var cont_label: Label          # the tournament continue countdown (null when not shown)
var cont_time := 0.0
var landscape := false          # 960x540: the portrait layout is scaled and centred, controls sit in the corners
var view_scale := 1.0
var view_off := Vector2.ZERO
var touch_on := true            # on-screen buttons (phones) or keyboard hints (computers)
var cpu_rect := Rect2()          # the computer's board panel, screen coordinates (never scaled)
var cpu_cell := 10.0
var cpu_pad := 0.0
var cpu_portrait_rect := Rect2()
var player_portrait: Control
var cpu_portrait: Control

var board: Array = []
var bag: Array = []
var queue: Array = []
var kind := 0
var rot := 0
var pos := Vector2i.ZERO
var hold_kind := -1
var hold_used := false

var score := 0
var lines := 0
var level := 1
var state := State.PLAYING
var paused_from := State.PLAYING

var gravity_acc := 0.0
var lock_timer := 0.0
var lock_resets := 0
var das_dir := 0
var das_timer := 0.0

# Animation / effects
var clear_rows: Array = []
var clear_timer := 0.0
var pending_levelup := false
var display_score := 0.0
var particles: Array = []
var flashes: Array = []
var trails: Array = []
var popups: Array = []
var shake_time := 0.0
var shake_dur := 0.1
var shake_mag := 0.0

# Name entry
var entering_name := false
var name_chars: Array = [0, 0, 0]
var name_cursor := 0
var name_labels: Array = []
var name_slots: Array = []
var time := 0.0
var _btn_styles := {}

var overlay: Control
var options_open := false
var das := 0.13
var arr := 0.035

# Touch buttons: name, label, rect, repeatable (held) or one-shot.
var touch_buttons: Array = []
var touch_map := {} # touch index -> button name
var soft_lock := false  # soft drop held through a lock: ignored until released, so it can't slam the next piece


func _ready() -> void:
	_layout()
	_apply_settings()
	for r in ROWS:
		board.append(_empty_row())
	if vs:
		cpu = CpuPlayer.new(cpu_level)
		cpu.on_clear = _on_cpu_clear
		if cpu_char == "":
			cpu_char = Characters.random_other(char_id)
		cpu.aim = Settings.cpu_special == 2 or (Settings.cpu_special == 1 and Characters.is_dark(cpu_char))  # the boss plays for it
		cpu.want = _cpu_want()
		cpu.on_special = _on_cpu_special
		player_portrait = Portrait.new()
		player_portrait.set_char(char_id)
		add_child(player_portrait)
		cpu_portrait = Portrait.new()
		cpu_portrait.set_char(cpu_char)
		cpu_portrait.flip_h = true  # the busts face right: the opponent on the right looks at the board
		add_child(cpu_portrait)
		fx_layer = FxLayer.new()
		fx_layer.size = size
		add_child(fx_layer)
		_place_nodes()
	_spawn()
	# each tournament opponent has its own theme; the dark boss plays yours, slower and lower
	var theme := Characters.base(cpu_char) if vs and mode == "tournament" else ""
	Sfx.start_music(theme, 0.86 if Characters.is_dark(cpu_char) else 1.0)


func _exit_tree() -> void:
	Sfx.stop_music()


## Portrait content (x 12..528, y 112..712) is drawn through a transform: as is in portrait, centred and
## shrunk to fit the height in landscape.
func _layout() -> void:
	landscape = size.x > size.y
	view_scale = 0.86 if landscape else 1.0
	view_off = Vector2((size.x - 540.0 * view_scale) * 0.5, (size.y - 600.0 * view_scale) * 0.5 - 112.0 * view_scale) if landscape else Vector2.ZERO
	touch_on = Settings.use_touch()
	if not landscape:       # right column: the board is as wide as the column
		cpu_cell = 10.0
		cpu_pad = 0.0
		cpu_portrait_rect = Rect2(430, 606, 96, 96)
	elif touch_on:          # top right, above the buttons
		cpu_cell = 10.0
		cpu_pad = 10.0
		cpu_portrait_rect = Rect2(858, 16, 88, 88)
	else:                   # no buttons: a big panel on the right
		cpu_cell = 16.0
		cpu_pad = 10.0
		cpu_portrait_rect = Rect2(790, 424, 80, 80)
	var cw := cpu_cell * COLS + cpu_pad * 2.0
	var cx := 428.0 if not landscape else (724.0 if touch_on else 742.0)
	cpu_rect = Rect2(cx, 316.0 if not landscape else 12.0, cw, 40.0 + cpu_cell * ROWS + 44.0)


func _view_xf(shake: Vector2 = Vector2.ZERO) -> Transform2D:
	return Transform2D(Vector2(view_scale, 0), Vector2(0, view_scale), view_off + shake)


## A rect in portrait-layout coordinates -> screen coordinates.
func _to_screen(r: Rect2) -> Rect2:
	return Rect2(view_off + r.position * view_scale, r.size * view_scale)


func _place_nodes() -> void:
	if not vs:
		return
	var pr := _to_screen(Rect2(14, 428, 96, 96))
	player_portrait.position = pr.position
	player_portrait.size = pr.size
	cpu_portrait.position = cpu_portrait_rect.position
	cpu_portrait.size = cpu_portrait_rect.size


func _play_fx(tex: Texture2D, rect: Rect2, fps: float) -> void:
	fx_layer.play(tex, _to_screen(rect), fps)


## Called by Main when the window is rotated while playing.
func relayout() -> void:
	_layout()
	_apply_settings()
	if vs:
		fx_layer.size = size
		fx_layer.clear()
		_place_nodes()
	if state == State.PAUSED and overlay != null:
		state = paused_from
		_toggle_pause()


## (Re)reads options: touch layout, auto-repeat speed. Called at start and after the options screen.
func _apply_settings() -> void:
	touch_buttons = TouchLayout.buttons(Settings.layout, Settings.swap_sides, landscape) if touch_on else []
	_btn_styles.clear()
	for b in touch_buttons:
		_btn_styles[b["rect"].position] = [Style.button_box(b["scheme"], false, b["radius"]), Style.button_box(b["scheme"], true, b["radius"])]
	das = Settings.DAS[Settings.move_speed]
	arr = Settings.ARR[Settings.move_speed]
	touch_map.clear()


func _empty_row() -> Array:
	var row: Array = []
	row.resize(COLS)
	row.fill(-1)
	return row


# ---------------------------------------------------------------- input

func _held(action: String) -> bool:
	return Input.is_action_pressed(action) or touch_map.values().has(action)


func _input(event: InputEvent) -> void:
	if options_open:
		return
	if event is InputEventScreenTouch:
		_touch(event)
		return
	if event is InputEventScreenDrag:
		_drag(event)
		return
	if state == State.OVER:
		if entering_name:
			_name_input(event)
		elif event.is_action_pressed("confirm"):
			if vs and mode == "tournament":
				if cont_label != null:
					main.continue_fight()  # Enter = CONTINUE; a finished fight is left to the buttons
			elif vs:
				main.show_match()
			else:
				main.show_game()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		return
	if state == State.PAUSED:
		if event.is_action_pressed("confirm"):
			_toggle_pause()
		return
	if state != State.PLAYING:
		return
	for a in ["rotate_cw", "rotate_ccw", "hard_drop", "hold"]:
		if event.is_action_pressed(a):
			_one_shot(a)


const TOUCH_SLOP := 40.0  # fingers miss small targets: gaps and edges snap to the nearest button


func _button_at(p: Vector2) -> Dictionary:
	var pad := _dpad_at(p)
	if not pad.is_empty():
		return pad
	var best := {}
	var best_d := TOUCH_SLOP
	for b in touch_buttons:
		var r: Rect2 = b["rect"]
		var d := p.distance_to(p.clamp(r.position, r.end))  # 0 inside the rect
		if d < best_d:
			best = b
			best_d = d
	return best


## Direction pad: any touch near the pad picks a direction by angle (left/right favoured),
## so the thumb doesn't have to hit a small arm exactly.
func _dpad_at(p: Vector2) -> Dictionary:
	for b in touch_buttons:
		if b.has("pad_center") and p.distance_to(b["pad_center"]) < 155.0 and absf(p.x - b["pad_center"].x) < 132.0:
			var v: Vector2 = p - b["pad_center"]
			var want := ""
			# hard drop only from deep in the up arm, so a sloppy down/side press never slams the piece
			if absf(v.x) >= absf(v.y) * 0.8 or (v.y < 0.0 and v.y > -40.0):
				want = "move_right" if v.x > 0 else "move_left"
			else:
				want = "soft_drop" if v.y > 0 else "hard_drop"
			for d in touch_buttons:
				if d.has("pad_center") and d["name"] == want:
					return d
	return {}


func _touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if PAUSE_RECT.has_point(event.position) and state != State.OVER:
			_toggle_pause()
			return
		if state != State.PLAYING:
			return
		var b := _button_at(event.position)
		if b.is_empty():
			return
		if b["held"]:
			touch_map[event.index] = b["name"]
			if b["name"] != "soft_drop":
				var dir := 1 if b["name"] == "move_right" else -1
				das_dir = dir
				das_timer = -das
				_move(dir)
		else:
			_one_shot(b["name"])
	else:
		touch_map.erase(event.index)


func _drag(event: InputEventScreenDrag) -> void:
	if state != State.PLAYING or not touch_map.has(event.index):
		return
	var b := _button_at(event.position)
	if b.is_empty():
		touch_map.erase(event.index)
	elif b["held"]:
		touch_map[event.index] = b["name"]


func _one_shot(action: String) -> void:
	match action:
		"rotate_cw": _rotate(1)
		"rotate_ccw": _rotate(-1)
		"hard_drop": _hard_drop()
		"hold": _hold()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if state == State.PLAYING or state == State.CLEARING:
			_toggle_pause()


# ---------------------------------------------------------------- game loop

func _process(delta: float) -> void:
	time += delta
	if state == State.PLAYING or state == State.CLEARING:
		play_t += delta
		sk["time"] = play_t
		if vs:
			st["time"] += delta
	if cont_label != null:
		cont_time -= delta
		cont_label.text = str(maxi(ceili(cont_time), 0))
		if cont_time <= 0.0:
			cont_label = null
			_vs_result(false)
	_update_effects(delta)
	match state:
		State.PLAYING:
			_update_horizontal(delta)
			_update_gravity(delta)
		State.CLEARING:
			clear_timer -= delta
			if clear_timer <= 0.0:
				_finish_clear()
	if vs and (state == State.PLAYING or state == State.CLEARING):
		cpu.step(minf(delta, 0.1))  # a lag spike must not make the CPU play a burst of moves at once
		if not cpu.alive:
			_vs_end(true)
	queue_redraw()


func _update_effects(delta: float) -> void:
	special_flash = maxf(0.0, special_flash - delta * 1.5)
	if state == State.PAUSED:
		return
	display_score = lerpf(display_score, float(score), minf(1.0, delta * 10.0))
	if absf(display_score - score) < 1.0:
		display_score = score
	shake_time = maxf(0.0, shake_time - delta)
	for p in popups:
		p["t"] -= delta
	popups = popups.filter(func(p): return p["t"] > 0.0)
	for f in flashes:
		f["t"] -= delta
	flashes = flashes.filter(func(f): return f["t"] > 0.0)
	for t in trails:
		t["t"] -= delta
	trails = trails.filter(func(t): return t["t"] > 0.0)
	for p in particles:
		p["life"] -= delta
		p["vel"].y += 900.0 * delta
		p["pos"] += p["vel"] * delta
	particles = particles.filter(func(p): return p["life"] > 0.0)
	for pr in projectiles:
		pr["t"] += delta
	projectiles = projectiles.filter(func(pr): return pr["t"] < pr["dur"])
	for k in fall_fx.keys():
		fall_fx[k]["t"] -= delta
		if fall_fx[k]["t"] <= 0.0:
			fall_fx.erase(k)


func _update_horizontal(delta: float) -> void:
	var dir := int(_held("move_right")) - int(_held("move_left"))
	if dir == 0:
		das_dir = 0
		return
	if dir != das_dir:
		das_dir = dir
		das_timer = -das
		_move(dir)
		return
	das_timer += delta
	while das_timer >= arr:
		das_timer -= arr
		_move(dir)


func gravity_interval() -> float:
	var lv := mini(level, VS_MAX_GRAVITY_LEVEL) if vs else level
	return pow(0.8 - float(lv - 1) * 0.007, float(lv - 1))


func _soft() -> bool:
	if not _held("soft_drop"):
		soft_lock = false
	return _held("soft_drop") and not soft_lock


func _current_interval() -> float:
	var interval := gravity_interval()
	if _soft():
		interval = minf(interval, 0.05)
	return interval


func _update_gravity(delta: float) -> void:
	var interval := _current_interval()
	var soft := _soft()
	if _collides(kind, rot, pos + Vector2i(0, 1)):
		gravity_acc = 0.0
		lock_timer += delta
		if lock_timer >= LOCK_DELAY:
			_lock()
		return
	lock_timer = 0.0
	gravity_acc += delta
	while gravity_acc >= interval:
		gravity_acc -= interval
		if _collides(kind, rot, pos + Vector2i(0, 1)):
			break
		pos.y += 1
		if soft:
			score += 1


# ---------------------------------------------------------------- piece logic

func _collides(k: int, r: int, p: Vector2i) -> bool:
	for c in Pieces.cells(k, r):
		var x: int = p.x + c.x
		var y: int = p.y + c.y
		if x < 0 or x >= COLS or y >= ROWS:
			return true
		if y >= 0 and board[y][x] != -1:
			return true
	return false


func _on_piece_moved() -> void:
	if _collides(kind, rot, pos + Vector2i(0, 1)) and lock_resets < MAX_LOCK_RESETS:
		lock_timer = 0.0
		lock_resets += 1


func _move(dx: int) -> bool:
	if _collides(kind, rot, pos + Vector2i(dx, 0)):
		return false
	pos.x += dx
	_key_pressed()
	Sfx.play("move")
	_on_piece_moved()
	return true


func _rotate(dir: int) -> void:
	var new_rot := (rot + dir + 4) % 4
	for k in Pieces.kicks(kind, rot, new_rot):
		if not _collides(kind, new_rot, pos + k):
			pos += k
			rot = new_rot
			_key_pressed()
			Sfx.play("rotate")
			_on_piece_moved()
			return


func _hard_drop() -> void:
	_key_pressed()
	var start := pos
	while not _collides(kind, rot, pos + Vector2i(0, 1)):
		pos.y += 1
		score += 2
	# Trail: one streak per column from the piece's original top to its landing top.
	var tops := {}
	for c in Pieces.cells(kind, rot):
		if not tops.has(c.x) or c.y < tops[c.x]:
			tops[c.x] = c.y
	if pos.y > start.y:
		for cx in tops:
			trails.append({"x": pos.x + cx, "y0": start.y + tops[cx], "y1": pos.y + tops[cx],
				"t": 0.2, "color": Style.piece_color(kind)})
	_shake(0.12, 3.0)
	Sfx.play("drop")
	_lock(false)


func _hold() -> void:
	if hold_used:
		return
	_key_pressed()
	var current := kind
	if hold_kind == -1:
		hold_kind = current
		_spawn()
	else:
		var swap := hold_kind
		hold_kind = current
		_spawn(swap)
	hold_used = true
	Sfx.play("hold")


func ghost_pos() -> Vector2i:
	var p := pos
	while not _collides(kind, rot, p + Vector2i(0, 1)):
		p.y += 1
	return p


func _refill() -> void:
	while queue.size() < 7:
		if bag.is_empty():
			bag = [0, 1, 2, 3, 4, 5, 6]
			bag.shuffle()
		queue.append(bag.pop_back())


func _spawn(forced := -1) -> void:
	_refill()
	kind = forced if forced >= 0 else queue.pop_front()
	_refill()
	rot = 0
	pos = Vector2i(3, -1)
	gravity_acc = 0.0
	lock_timer = 0.0
	lock_resets = 0
	if forced < 0:
		hold_used = false
	spawn_t = play_t
	got_key = false
	var holes := _count_holes()
	sk["holes"] += maxi(0, holes - prev_holes)
	prev_holes = holes
	if _collides(kind, rot, pos):
		_game_over()


## Skill record: the first key of a piece also gives the reaction delay since it appeared.
func _key_pressed() -> void:
	sk["keys"] += 1
	if not got_key:
		got_key = true
		sk["delay"] += play_t - spawn_t
		sk["delay_n"] += 1


func _count_holes() -> int:
	var n := 0
	for x in COLS:
		var seen := false
		for y in ROWS:
			if board[y][x] != -1:
				seen = true
			elif seen:
				n += 1
	return n


## Hands the finished game's record to the lifetime profile (once) and returns its skill estimate.
func _finish_record() -> float:
	if not sk_saved:
		sk_saved = true
		Settings.add_profile(sk)
		if mode == "tournament":
			Skill.add(main.run["sk"], sk)
	return Skill.estimate(sk)


func _lock(play_sound := true) -> void:
	sk["pieces"] += 1
	soft_lock = _held("soft_drop")
	var topped_out := true
	for c in Pieces.cells(kind, rot):
		var p: Vector2i = pos + c
		if p.y >= 0:
			board[p.y][p.x] = kind
			topped_out = false
			flashes.append({"c": p, "t": 0.22})
	var full: Array = []
	for y in ROWS:
		if not board[y].has(-1):
			full.append(y)
	if not full.is_empty():
		_begin_clear(full)
		return
	if play_sound:
		Sfx.play("lock")
	if topped_out:
		_game_over()
		return
	combo = 0
	if vs and not _apply_incoming():
		return
	_spawn()


func _begin_clear(rows: Array) -> void:
	state = State.CLEARING
	clear_rows = rows
	clear_timer = CLEAR_TIME
	var n := mini(rows.size(), 4)
	var table := [0, 100, 300, 500, 800]
	score += table[n] * level
	lines += n
	var new_level := lines / 10 + 1
	pending_levelup = new_level > level
	level = new_level
	for y in rows:
		for x in COLS:
			var center := BOARD_POS + Vector2(x + 0.5, y + 0.5) * CELL
			for i in 2:
				particles.append({
					"pos": center + Vector2(randf_range(-8, 8), randf_range(-8, 8)),
					"vel": Vector2(randf_range(-160, 160), randf_range(-320, -40)),
					"life": randf_range(0.4, 0.8), "max": 0.8,
					"color": Style.piece_color(board[y][x]), "size": randf_range(3, 7),
				})
	_popup(["", "SINGLE", "DOUBLE", "TRIPLE", "QUAD!"][n],
		Color("ffd400") if n == 4 else Color.WHITE)
	if vs:
		combo += 1
		st["combo"] = maxi(st["combo"], combo)
		if n == 4:
			st["quads"] += 1
		_send_attack(_attack_power(n, combo), true, rows)
		if cpu.special_in.is_empty() and Characters.add_clear(char_id, have, n):  # one special at a time on a board
			_fire_special(true)
	_shake(0.3 if n == 4 else 0.15, 7.0 if n == 4 else 3.0)
	Sfx.play("clear%d" % n)


func _finish_clear() -> void:
	clear_rows.sort()
	for y in clear_rows:
		board.remove_at(y)
		board.insert(0, _empty_row())
	clear_rows = []
	state = State.PLAYING
	if pending_levelup:
		pending_levelup = false
		_popup("LEVEL %d" % level, Color("4dd0ff"))
		Sfx.play("levelup")
	_spawn()


func _popup(text: String, color: Color) -> void:
	popups.append({"text": text, "color": color, "t": 1.1, "max": 1.1})


func _shake(duration: float, mag: float) -> void:
	shake_dur = duration
	shake_time = duration
	shake_mag = mag


# ---------------------------------------------------------------- VS mode

## Garbage blocks sent for clearing `n` lines (random within a range, +1 per combo step), 1..10.
func _attack_power(n: int, combo_count: int) -> int:
	var ranges := {1: [1, 2], 2: [3, 4], 3: [5, 7], 4: [8, 10]}
	var r: Array = ranges[clampi(n, 1, 4)]
	var bonus := clampi(combo_count - 1, 0, 3)
	return mini(randi_range(r[0], r[1]) + bonus, 10)


## Attack power first cancels the sender's own pending garbage; the rest hits the opponent.
func _send_attack(power: int, from_player: bool, rows: Array) -> void:
	var cancelled := 0
	if from_player:
		cancelled = mini(incoming, power)
		incoming -= cancelled
	else:
		cancelled = mini(cpu.incoming, power)
		cpu.incoming -= cancelled
	power -= cancelled
	if cancelled > 0 and from_player:
		st["blocked"] += cancelled
		_popup("BLOCKED %d" % cancelled, Style.CYAN)
	if power <= 0:
		return
	st["sent" if from_player else "taken"] += power
	if from_player:
		cpu.incoming += power
		_popup("ATTACK +%d" % power, Color("ff7a4d"))
		var row_y: float = BOARD_POS.y + (float(rows[0]) + 0.5) * CELL if not rows.is_empty() else BOARD_POS.y + 300.0
		_spawn_projectiles(power, Vector2(BOARD_POS.x + COLS * CELL * 0.5, row_y), _cpu_center())
	else:
		incoming += power
		_popup("INCOMING +%d" % power, Color("ff4d6d"))
		_spawn_projectiles(power, _cpu_center(), Vector2(BOARD_POS.x + COLS * CELL * 0.5, BOARD_POS.y + 10.0))
	Sfx.play("attack")


func _on_cpu_clear(n: int, combo_count: int) -> void:
	_send_attack(_attack_power(n, combo_count), false, [])
	if Settings.cpu_special != 0 and special_in.is_empty() and Characters.add_clear(cpu_char, cpu_have, n):
		_fire_special(false)
	cpu.want = _cpu_want()


## Clears the CPU's special attack still needs (used when the CPU aims for it).
func _cpu_want() -> Dictionary:
	var out := {}
	var need: Dictionary = Characters.def(cpu_char)["need"]
	for k in need:
		if need[k] - cpu_have.get(k, 0) > 0:
			out[k] = need[k] - cpu_have.get(k, 0)
	return out


## A full recipe: play the charge-up on the attacker and queue the special on the opponent's board.
func _fire_special(from_player: bool) -> void:
	var id := char_id if from_player else cpu_char
	var d := Characters.def(id)
	if from_player:
		_play_fx(Characters.fx_cast(id), Rect2(-6, 410, 124, 124), 14.0)
	else:
		fx_layer.play(Characters.fx_cast(id), cpu_portrait_rect.grow(14.0), 14.0)
	_popup(d["skill"] + "!", Color(d["color"]))
	special_flash = 1.0
	Sfx.play("levelup")
	if from_player:
		st["specials"] += 1
		cpu.special_in.append(id)
	else:
		special_in.append(id)


## The player's special landed on the CPU board: hit animation over its mini board.
func _on_cpu_special(id: String) -> void:
	var w := cpu_cell * COLS * 1.33   # the hit sprite is drawn over the mini board, ground line at its bottom
	var bottom := cpu_rect.position.y + 40.0 + cpu_cell * ROWS
	fx_layer.play(Characters.fx_hit(id), Rect2(cpu_rect.get_center().x - w * 0.5, bottom - w * 0.875, w, w), 12.0)
	_shake(0.2, 3.0)
	Sfx.play("hit")


func _cpu_center() -> Vector2:
	var screen_pt := Vector2(cpu_rect.get_center().x, cpu_rect.position.y + 40.0 + cpu_cell * ROWS * 0.5)
	return (screen_pt - view_off) / view_scale  # projectiles are drawn in view coordinates


func _spawn_projectiles(count: int, from: Vector2, to: Vector2) -> void:
	for i in count:
		projectiles.append({"from": from + Vector2(randf_range(-30, 30), randf_range(-10, 10)),
			"to": to + Vector2(randf_range(-6, 6), randf_range(-6, 6)),
			"t": -0.04 * i, "dur": 0.55})


## Drops the pending garbage onto random columns of the player's board.
## Returns false if it overflowed the board (the player loses).
func _apply_incoming() -> bool:
	if not special_in.is_empty():
		for sid in special_in:
			var ok := Characters.apply(sid, board)  # first: the lightning picks its side here
			_play_fx(Characters.fx_hit(sid), Rect2(BOARD_POS.x, BOARD_POS.y + ROWS * CELL - 262.0, 300, 300), 12.0)
			if not ok:
				special_in.clear()
				_game_over()
				return false
		special_in.clear()
		Sfx.play("hit")
		_shake(0.35, 7.0)
	if incoming <= 0:
		return true
	var n := incoming
	incoming = 0
	for i in n:
		var x := randi_range(0, COLS - 1)
		var top := ROWS
		for yy in ROWS:
			if board[yy][x] != -1:
				top = yy
				break
		if top - 1 < 0:
			_game_over()
			return false
		board[top - 1][x] = GARBAGE
		fall_fx[Vector2i(x, top - 1)] = {"t": 0.4, "dur": 0.4}
	Sfx.play("hit")
	_shake(0.25, 5.0)
	_popup("-%d" % n, Color("ff4d6d"))
	return true


func _vs_end(won: bool) -> void:
	if state == State.OVER:
		return
	state = State.OVER
	touch_map.clear()
	Sfx.stop_music()
	Sfx.play("win" if won else "lose")
	_shake(0.4, 6.0)
	last_est = _finish_record()
	last_fight = {"foe": cpu_char, "lv": cpu_level, "won": won, "score": score, "lines": lines, "cpu_lines": cpu.lines}
	last_fight.merge(st)
	if mode == "tournament":
		main.run["log"].append(last_fight)
	if mode == "tournament" and not won and main.run.get("credits", 0) > 0:
		_continue_prompt()
		return
	_vs_result(won)


## Tournament, lost with continues left: a 10 second countdown like an arcade cabinet.
func _continue_prompt() -> void:
	var c := _open_overlay(Rect2(50, 230, 440, 480))
	UI.label(c, "CONTINUE?", Rect2(0, 30, 440, 70), 46, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	cont_time = 10.0
	cont_label = UI.label(c, "10", Rect2(0, 100, 440, 130), 110, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	var foe: String = Characters.def(cpu_char)["name"]
	UI.label(c, "Fight %d of %d   vs %s" % [round_no, round_total, foe], Rect2(0, 236, 440, 34), 18, Style.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_SEMI)
	UI.button(c, "CONTINUE  (%d left)" % main.run["credits"], Rect2(40, 290, 360, 88), func(): main.continue_fight(), 28,
		Style.BTN_PRIMARY, "retry")
	UI.button(c, "GIVE UP", Rect2(40, 392, 360, 70), func():
		cont_label = null
		_vs_result(false), 22, Style.BTN_GLASS, "home")


func _vs_result(won: bool) -> void:
	var tour := mode == "tournament"
	if not tour:
		Settings.add_vs_result(cpu_level, won)
	var rec: Array = Settings.record(cpu_level)
	var last := tour and round_no >= round_total
	var has_next := won and (tour or cpu_level < CpuPlayer.MAX_LEVEL)
	var card_h := 372.0 + 102.0 + (92.0 if has_next else 0.0) + 70.0 + 36.0
	var c := _open_overlay(Rect2(50, (960.0 - card_h) * 0.5 - 40.0, 440, card_h))
	var title := "YOU WIN!" if won else "YOU LOSE"
	if tour:
		title = ("CHAMPION!" if last else "ROUND CLEAR") if won else "ELIMINATED"
	UI.label(c, title, Rect2(0, 26, 440, 70), 42 if tour else 46,
		Style.GOLD if won else Color("ff6f8e"), HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	var foe: String = Characters.def(cpu_char)["name"]
	UI.label(c, "vs %s  (CPU Lv %d  %s)" % [foe, cpu_level, CpuPlayer.NAMES[cpu_level - 1]], Rect2(0, 100, 440, 34), 18,
		Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_SEMI)
	var cells := [["SCORE", str(score)], ["LINES  YOU / CPU", "%d / %d" % [lines, cpu.lines]],
		["ATTACK SENT", str(st["sent"])], ["ATTACK TAKEN", str(st["taken"])],
		["BEST COMBO", str(st["combo"])], ["SPECIALS", str(st["specials"])],
		["YOUR LEVEL (EST.)", "Lv %d" % roundi(last_est) if last_est >= 0.0 else "-"], ["TIME", "%d:%02d" % [int(st["time"]) / 60, int(st["time"]) % 60]]]
	for i in cells.size():
		var cx := 24.0 + (i % 2) * 204.0
		var cy := 142.0 + (i / 2) * 46.0
		UI.label(c, cells[i][0], Rect2(cx, cy, 190, 18), 12, Style.MUTED, HORIZONTAL_ALIGNMENT_LEFT, Style.FONT_SEMI)
		UI.label(c, cells[i][1], Rect2(cx, cy + 14, 190, 30), 24, Style.TEXT, HORIZONTAL_ALIGNMENT_LEFT, Style.FONT_BOLD)
	var info := "Round %d of %d" % [round_no, round_total] if tour else "Record at this level:  %d W  /  %d L" % [rec[0], rec[1]]
	UI.label(c, info, Rect2(0, 330, 440, 28), 18, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_SEMI)
	var y := 372.0
	if tour:
		if won:
			var nxt := "FINISH" if last else "NEXT FIGHT"
			UI.button(c, nxt, Rect2(40, y, 360, 88), func(): main.next_fight(), 30, Style.BTN_PRIMARY, "swords")
		else:
			UI.button(c, "SUMMARY", Rect2(40, y, 360, 88), func(): main.show_summary(), 30, Style.BTN_PRIMARY, "retry")
		y += 102.0
		UI.button(c, "MENU", Rect2(40, y, 360, 70), func(): main.show_title(), 22, Style.BTN_GLASS, "home")
		return
	UI.button(c, "REMATCH", Rect2(40, y, 360, 88), func(): main.show_match(), 30, Style.BTN_PRIMARY, "retry")
	y += 102.0
	if has_next:
		UI.button(c, "NEXT LEVEL  (Lv %d)" % (cpu_level + 1), Rect2(40, y, 360, 78), func(): main.next_fight(), 22,
			Style.BTN_ACCENT, "swords")
		y += 92.0
	UI.button(c, "LEVELS", Rect2(40, y, 170, 70), func(): main.show_vs_select("ladder"), 20, Style.BTN_GLASS, "up")
	UI.button(c, "MENU", Rect2(230, y, 170, 70), func(): main.show_title(), 20, Style.BTN_GLASS, "home")


# ---------------------------------------------------------------- pause / game over

func _toggle_pause() -> void:
	if state == State.PLAYING or state == State.CLEARING:
		paused_from = state
		state = State.PAUSED
		touch_map.clear()
		Sfx.pause_music(true)
		var c := _open_overlay(Rect2(70, 250, 400, 440))
		UI.label(c, "PAUSED", Rect2(0, 30, 400, 70), 44, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
		UI.button(c, "RESUME", Rect2(40, 116, 320, 92), _toggle_pause, 32, Style.BTN_PRIMARY, "play")
		UI.button(c, "OPTIONS", Rect2(40, 224, 320, 78), _open_options, 26, Style.BTN_GLASS, "gear")
		UI.button(c, "MENU", Rect2(40, 318, 320, 78), func(): main.show_title(), 26, Style.BTN_GLASS, "home")
		UI.icon_button(c, "fullscreen_exit" if Fullscreen.active() else "fullscreen", Rect2(340, 18, 48, 48),
			func(): Fullscreen.toggle(self), Style.BTN_GLASS)
	elif state == State.PAUSED:
		state = paused_from
		Sfx.pause_music(false)
		_close_overlay()


func _open_options() -> void:
	options_open = true
	var o := OptionsScreen.new()
	o.on_close = func():
		options_open = false
		_apply_settings()
	if landscape:  # the options screen is a 540x960 portrait page: fit it to the height
		var s := size.y / 960.0
		o.scale = Vector2(s, s)
		o.position = Vector2((size.x - 540.0 * s) * 0.5, 0)
	add_child(o)


func _game_over() -> void:
	if vs:
		_vs_end(false)
		return
	state = State.OVER
	last_est = _finish_record()
	touch_map.clear()
	Sfx.stop_music()
	Sfx.play("gameover")
	_shake(0.4, 6.0)
	if Scores.qualifies(score):
		_open_name_entry()
	else:
		_show_over(0)


func _show_over(rank: int) -> void:
	entering_name = false
	var c := _open_overlay(Rect2(50, 200, 440, 540))
	UI.label(c, "GAME OVER", Rect2(0, 26, 440, 70), 44, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	UI.label(c, "SCORE", Rect2(0, 100, 440, 30), 18, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, Style.caption_font())
	UI.label(c, str(score), Rect2(0, 126, 440, 76), 60, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	UI.label(c, "LINES  %d      LEVEL  %d" % [lines, level], Rect2(0, 206, 440, 36), 22, Style.TEXT)
	UI.label(c, "SKILL  " + Skill.text(last_est), Rect2(0, 240, 440, 28), 18, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_SEMI)
	var tag := ""
	if rank == 1:
		tag = "NEW BEST!"
	elif rank > 0:
		tag = "RANK #%d" % rank
	if tag != "":
		UI.label(c, tag, Rect2(0, 266, 440, 46), 30, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	UI.button(c, "PLAY AGAIN", Rect2(40, 316, 360, 92), func(): main.show_game(), 30, Style.BTN_PRIMARY, "retry")
	UI.button(c, "MENU", Rect2(40, 428, 170, 74), func(): main.show_title(), 20, Style.BTN_GLASS, "home")
	UI.button(c, "RANKING", Rect2(230, 428, 170, 74), func(): main.show_leaderboard(), 20, Style.BTN_GLASS, "trophy")


func _open_name_entry() -> void:
	entering_name = true
	name_cursor = 0
	var saved: String = Scores.last_name.to_upper()
	for i in 3:
		var ch := saved.unicode_at(i) if i < saved.length() else 65
		name_chars[i] = clampi(ch - 65, 0, 25)
	var c := _open_overlay(Rect2(50, 170, 440, 620))
	UI.label(c, "NEW HIGH SCORE!", Rect2(0, 26, 440, 60), 34, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	UI.label(c, str(score), Rect2(0, 86, 440, 64), 50, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	UI.label(c, "ENTER YOUR NAME", Rect2(0, 150, 440, 34), 18, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, Style.caption_font())
	name_labels.clear()
	name_slots.clear()
	for i in 3:
		var cx := 100.0 + i * 120.0
		var idx := i
		UI.icon_button(c, "up", Rect2(cx - 40, 196, 80, 60), func(): _step_letter(idx, 1))
		var slot := Panel.new()
		slot.position = Vector2(cx - 48, 270)
		slot.size = Vector2(96, 116)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed:
				name_cursor = idx
				_refresh_name())
		c.add_child(slot)
		name_slots.append(slot)
		name_labels.append(UI.label(slot, "A", Rect2(0, 0, 96, 116), 64, Style.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY))
		UI.icon_button(c, "down", Rect2(cx - 40, 400, 80, 60), func(): _step_letter(idx, -1))
	UI.button(c, "OK", Rect2(40, 500, 360, 90), _confirm_name, 34, Style.BTN_PRIMARY)
	_refresh_name()


func _step_letter(i: int, d: int) -> void:
	name_cursor = i
	name_chars[i] = (name_chars[i] + d + 26) % 26
	_refresh_name()


func _refresh_name() -> void:
	for i in 3:
		name_labels[i].text = char(65 + name_chars[i])
		var active := i == name_cursor
		name_labels[i].add_theme_color_override("font_color", Style.CYAN if active else Style.TEXT)
		name_slots[i].add_theme_stylebox_override("panel", Style.panel_box(
			Color(0, 0, 0, 0.35), 16,
			Style.CYAN if active else Color(1, 1, 1, 0.15),
			Color(0.2, 0.8, 1, 0.35) if active else Color(0, 0, 0, 0), 14 if active else 0))


func _name_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_A and k <= KEY_Z:
			name_chars[name_cursor] = k - KEY_A
			name_cursor = mini(name_cursor + 1, 2)
			_refresh_name()
		elif k == KEY_BACKSPACE or k == KEY_LEFT:
			name_cursor = maxi(name_cursor - 1, 0)
			_refresh_name()
		elif k == KEY_RIGHT:
			name_cursor = mini(name_cursor + 1, 2)
			_refresh_name()
		elif k == KEY_UP:
			_step_letter(name_cursor, 1)
		elif k == KEY_DOWN:
			_step_letter(name_cursor, -1)
		elif k == KEY_ENTER or k == KEY_KP_ENTER:
			_confirm_name()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A: _confirm_name()
			JOY_BUTTON_DPAD_UP: _step_letter(name_cursor, 1)
			JOY_BUTTON_DPAD_DOWN: _step_letter(name_cursor, -1)
			JOY_BUTTON_DPAD_LEFT:
				name_cursor = maxi(name_cursor - 1, 0)
				_refresh_name()
			JOY_BUTTON_DPAD_RIGHT:
				name_cursor = mini(name_cursor + 1, 2)
				_refresh_name()


func _confirm_name() -> void:
	if not entering_name:
		return
	var player := ""
	for c in name_chars:
		player += char(65 + c)
	_show_over(Scores.add(player, score, lines, level))


## Dimmed overlay + animated card. Returns the card to add content to.
func _open_overlay(card_rect: Rect2) -> Panel:
	_close_overlay()
	overlay = Control.new()
	overlay.size = size
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.08, 0.7)
	dim.size = size
	overlay.add_child(dim)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
	var holder: Node = overlay
	if landscape:  # centre the card and shrink it to fit the lower screen
		var s := minf(1.0, (size.y - 20.0) / card_rect.size.y)
		var h := Control.new()
		h.scale = Vector2(s, s)
		h.position = (size - card_rect.size * s) * 0.5
		overlay.add_child(h)
		holder = h
		card_rect.position = Vector2.ZERO
	var c := UI.card(holder, card_rect)
	UI.pop_in(c)
	return c


func _close_overlay() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null


# ---------------------------------------------------------------- drawing

func _cell_rect(cx: int, cy: int) -> Rect2:
	return Rect2(BOARD_POS + Vector2(cx, cy) * CELL, Vector2(CELL, CELL))


## Smooth falling: interpolate the active piece between rows.
func _fall_offset() -> float:
	if state != State.PLAYING or _collides(kind, rot, pos + Vector2i(0, 1)):
		return 0.0
	return clampf(gravity_acc / _current_interval(), 0.0, 1.0) * CELL


func _danger() -> bool:
	for y in 4:
		for x in COLS:
			if board[y][x] != -1:
				return true
	return false


func _draw() -> void:
	Style.draw_bg(self, size)
	_draw_header()
	draw_set_transform_matrix(_view_xf())
	_draw_side_panels()

	# Everything on/over the board shakes together.
	if shake_time > 0.0:
		var m := shake_mag * shake_time / shake_dur
		draw_set_transform_matrix(_view_xf(Vector2(randf_range(-m, m), randf_range(-m, m))))
	_draw_board()
	draw_set_transform_matrix(_view_xf())
	_draw_projectiles()
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if vs:
		_draw_cpu_panel()
	if touch_on:
		_draw_touch_buttons()
	else:
		_draw_key_hints()


func _draw_header() -> void:
	# Pause button
	var pressed := state == State.PAUSED
	draw_style_box(Style.button_box(Style.BTN_GLASS, pressed, 16), PAUSE_RECT)
	Style.draw_icon(self, "pause", PAUSE_RECT.get_center() + Vector2(0, 2 if pressed else -2), 28)
	# Score
	var cap := Style.caption_font()
	var sx := 80.0 if landscape else 0.0   # score block: centred in portrait, beside the pause button in landscape
	var sw := 170.0 if landscape else size.x
	var al := HORIZONTAL_ALIGNMENT_LEFT if landscape else HORIZONTAL_ALIGNMENT_CENTER
	var rx := size.x - 140.0
	Style.text(self, cap, Vector2(sx, 42), "SCORE", 16, Style.MUTED, al, sw)
	Style.text(self, Style.FONT_DISPLAY, Vector2(sx, 88), str(int(round(display_score))), 40, Style.TEXT, al, sw, 8)
	var vs_label := "LADDER" if mode == "ladder" else "ROUND %d / %d" % [round_no, round_total]
	if vs and landscape:
		Style.text(self, cap, Vector2(sx, 124), vs_label, 16, Style.MUTED, al, sw)
		Style.text(self, Style.FONT_DISPLAY, Vector2(sx, 152), "Lv %d" % cpu_level, 22, Style.CYAN, al, sw)
	elif vs:
		Style.text(self, cap, Vector2(rx - 40.0, 42), vs_label, 16, Style.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 164)
		Style.text(self, Style.FONT_DISPLAY, Vector2(rx, 74), "Lv %d" % cpu_level, 22, Style.CYAN,
			HORIZONTAL_ALIGNMENT_RIGHT, 124)
	else:
		var best := maxi(Scores.best(), score)
		Style.text(self, cap, Vector2(rx, 42), "BEST", 16, Style.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 124)
		Style.text(self, Style.FONT_DISPLAY, Vector2(rx, 74), str(best), 22, Style.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 124)


func _side_panel(rect: Rect2, title: String) -> void:
	draw_style_box(Style.panel_box(Style.PANEL, 16), rect)
	Style.text(self, Style.caption_font(), rect.position + Vector2(0, 26), title, 15, Style.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


func _draw_side_panels() -> void:
	var hold_r := Rect2(LEFT_X, BOARD_POS.y, COL_W, 100)
	_side_panel(hold_r, "HOLD")
	if hold_kind >= 0:
		Style.draw_piece_centered(self, Pieces.cells(hold_kind, 0), hold_kind,
			hold_r.position + Vector2(COL_W * 0.5, 62), 18.0, 0.35 if hold_used else 1.0)
	var stats := [["LEVEL", str(level), 226.0, Style.TEXT], ["LINES", str(lines), 322.0, Style.TEXT]]
	if vs:
		var warn := incoming > 0
		stats[0] = ["INCOMING", str(incoming), 226.0, Color("ff4d6d") if warn else Style.MUTED]
	for st in stats:
		var r := Rect2(LEFT_X, st[2], COL_W, 84)
		_side_panel(r, st[0])
		Style.text(self, Style.FONT_DISPLAY, r.position + Vector2(0, 68), st[1], 30, st[3],
			HORIZONTAL_ALIGNMENT_CENTER, COL_W)

	var next_r := Rect2(RIGHT_X, BOARD_POS.y, COL_W, 190 if vs else 300)
	_side_panel(next_r, "NEXT")
	var y := next_r.position.y + 76
	for i in (2 if vs else 3):
		var cell := 20.0 if i == 0 else 16.0
		Style.draw_piece_centered(self, Pieces.cells(queue[i], 0), queue[i],
			Vector2(RIGHT_X + COL_W * 0.5, y), cell, 1.0 if i == 0 else 0.8)
		y += 86.0 if i == 0 else 72.0
	if vs:
		_draw_fighters()


## Fighter cards: portrait, special-attack name and a gauge of the recipe's clears.
func _draw_fighters() -> void:
	var d := Characters.def(char_id)
	var col := Color(d["color"])
	var flash := special_flash * (0.5 + 0.5 * sin(time * 30.0))
	var r := Rect2(LEFT_X, 418, COL_W, 188)
	draw_style_box(Style.panel_box(Style.PANEL, 16, col.lerp(Color.WHITE, flash), Color(col, 0.25 + 0.5 * flash), 14), r)
	Style.text(self, Style.FONT_BOLD, Vector2(r.position.x, 548), d["name"], 15, col, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Style.text(self, Style.caption_font(), Vector2(r.position.x, 566), d["skill"], 11, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var used := {}
	var pips := Characters.pips(char_id)
	var x0 := r.position.x + (r.size.x - (pips.size() * 28.0 - 4.0)) * 0.5
	for i in pips.size():
		var n: int = pips[i]
		var got: bool = have.get(n, 0) > used.get(n, 0)
		used[n] = used.get(n, 0) + 1
		var pr := Rect2(x0 + i * 28.0, 576, 24, 24)
		draw_style_box(Style.panel_box(col if got else Color(0.12, 0.1, 0.25), 6, col.lightened(0.4) if got else Color(col, 0.35)), pr)
		Style.text(self, Style.FONT_BOLD, pr.position + Vector2(0, 18), str(n), 16,
			Color(0.06, 0.04, 0.14) if got else Color(col, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 24)


## Mini view of the computer's board (VS mode), its fighter and special-attack gauge.
func _draw_cpu_panel() -> void:
	var r := cpu_rect
	var cap := Style.caption_font()
	draw_style_box(Style.panel_box(Style.PANEL, 16, Color(1, 0.45, 0.55, 0.35) if cpu.incoming > 0 else Style.PANEL_BORDER), r)
	Style.text(self, cap, r.position + Vector2(0, 26), "CPU  LV %d" % cpu_level, 15, Style.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var o := r.position + Vector2(cpu_pad, 40)
	var cell := Vector2(cpu_cell, cpu_cell)
	draw_rect(Rect2(o, Vector2(COLS, ROWS) * cpu_cell), Color(0, 0, 0, 0.4))
	for yy in ROWS:
		for xx in COLS:
			var v: int = cpu.board[yy][xx]
			if v >= 0:
				Style.draw_block(self, v, Rect2(o + Vector2(xx, yy) * cpu_cell, cell))
	if cpu.alive:
		for c in Pieces.cells(cpu.kind, cpu.rot):
			var q: Vector2i = cpu.pos + c
			if q.y >= 0:
				Style.draw_block(self, cpu.kind, Rect2(o + Vector2(q) * cpu_cell, cell))
	else:
		draw_rect(Rect2(o, Vector2(COLS, ROWS) * cpu_cell), Color(0, 0, 0, 0.55))
		Style.text(self, Style.FONT_DISPLAY, o + Vector2(0, ROWS * cpu_cell * 0.5), "OUT", 22, Style.GOLD,
			HORIZONTAL_ALIGNMENT_CENTER, COLS * cpu_cell)
	var by := o.y + ROWS * cpu_cell + 20
	Style.text(self, Style.FONT_BOLD, Vector2(r.position.x, by), "LINES %d" % cpu.lines, 14, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var warn: bool = cpu.incoming > 0
	Style.text(self, Style.FONT_BOLD, Vector2(r.position.x, by + 17), "INCOMING %d" % cpu.incoming, 14,
		Color("ff4d6d") if warn else Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	# fighter: name and gauge under its portrait
	var cd := Characters.def(cpu_char)
	var cc := Color(cd["color"])
	var pr := cpu_portrait_rect
	var bar := Rect2(pr.position.x + 4, pr.end.y + 4, pr.size.x - 8, 4)
	draw_rect(bar, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * Characters.progress(cpu_char, cpu_have), bar.size.y)), cc)
	Style.text(self, Style.FONT_BOLD, Vector2(pr.position.x, pr.end.y + 20), cd["name"], 15, cc,
		HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)


## Computers have no on-screen buttons: show the keys instead (they follow Options -> KEYS).
func _draw_key_hints() -> void:
	var acts: Array = Settings.ACTIONS
	if landscape:
		_hint_rows(Rect2(12, 176, 232, 336), acts, 42.0)
	else:
		_hint_rows(Rect2(12, 740, 252, 192), acts.slice(0, 4), 48.0)
		_hint_rows(Rect2(276, 740, 252, 192), acts.slice(4), 48.0)


func _hint_rows(r: Rect2, acts: Array, row_h: float) -> void:
	draw_style_box(Style.panel_box(Color(0, 0, 0, 0.3), 14, Color(1, 1, 1, 0.1)), r.grow(6))
	for i in acts.size():
		var y := r.position.y + i * row_h
		Style.text(self, Style.caption_font(), Vector2(r.position.x + 6, y + row_h * 0.62), acts[i][1], 13, Style.MUTED)
		var x := r.end.x - 6.0
		var codes: Array = Settings.key_slots(acts[i][0]).filter(func(c): return c != 0).slice(0, 2)
		codes.reverse()
		for code in codes:
			var label: String = Settings.key_name(code)
			var w := maxf(32.0, Style.FONT_BOLD.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 18.0)
			var keycap := Rect2(x - w, y + row_h * 0.5 - 15.0, w, 30.0)
			draw_style_box(Style.panel_box(Color(0.2, 0.2, 0.36), 7, Color(1, 1, 1, 0.45)), keycap)
			Style.text(self, Style.FONT_BOLD, keycap.position + Vector2(0, 21), label, 15, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, w)
			x -= w + 6.0


func _draw_board() -> void:
	var board_rect := Rect2(BOARD_POS, Vector2(COLS, ROWS) * CELL)
	var danger := _danger() and state != State.OVER
	var pulse := 0.5 + 0.5 * sin(time * 6.0)
	var border := Color(1, 0.3, 0.4, 0.5 + 0.4 * pulse) if danger else Color(0.55, 0.65, 1, 0.35)
	var glow := Color(1, 0.2, 0.35, 0.35) if danger else Color(0.2, 0.55, 1, 0.28)
	draw_style_box(Style.panel_box(Color(0.02, 0.02, 0.08, 0.86), 12, border, glow, 22), board_rect.grow(6))
	if vs and incoming > 0:  # warning gauge: how many garbage blocks are about to land
		var h := minf(incoming, 10.0) / 10.0 * ROWS * CELL
		var a := 0.65 + 0.3 * sin(time * 8.0)
		draw_rect(Rect2(BOARD_POS.x - 13, BOARD_POS.y + ROWS * CELL - h, 6, h), Color(1, 0.3, 0.4, a))
	for x in COLS:
		if x % 2 == 0:
			draw_rect(Rect2(BOARD_POS + Vector2(x * CELL, 0), Vector2(CELL, ROWS * CELL)), Color(1, 1, 1, 0.022))
	for y in range(1, ROWS):
		for x in range(1, COLS):
			draw_rect(Rect2(BOARD_POS + Vector2(x * CELL - 1, y * CELL - 1), Vector2(2, 2)), Color(1, 1, 1, 0.12))

	var clear_progress := 1.0 - clear_timer / CLEAR_TIME
	for y in ROWS:
		var clearing: bool = clear_rows.has(y)
		for x in COLS:
			var v: int = board[y][x]
			if v >= 0:
				var cr := _cell_rect(x, y)
				var fx = fall_fx.get(Vector2i(x, y))
				if fx != null:
					cr.position.y -= (y + 2.0) * CELL * (fx["t"] / fx["dur"])
				Style.draw_block(self, v, cr, 1.0 - clear_progress if clearing else 1.0)
		if clearing:
			var flash := 0.5 + 0.5 * sin(clear_progress * TAU * 3.0)
			var row_w := COLS * CELL * (1.0 - clear_progress * 0.7)
			var rx := BOARD_POS.x + (COLS * CELL - row_w) * 0.5
			draw_rect(Rect2(rx, BOARD_POS.y + y * CELL + 2, row_w, CELL - 4), Color(1, 1, 1, 0.35 + 0.5 * flash))

	# Hard-drop trails
	for t in trails:
		var a: float = t["t"] / 0.2
		var c: Color = t["color"]
		var top: float = BOARD_POS.y + t["y0"] * CELL
		var bottom: float = BOARD_POS.y + t["y1"] * CELL
		var steps := 8
		for i in steps:
			var k := float(i) / steps
			c.a = 0.45 * a * k
			var y0 := lerpf(top, bottom, k)
			draw_rect(Rect2(BOARD_POS.x + t["x"] * CELL + 5, y0, CELL - 10, (bottom - top) / steps + 1), c)

	if state == State.PLAYING or state == State.PAUSED:
		if Settings.ghost:
			var gp := ghost_pos()
			for c in Pieces.cells(kind, rot):
				if gp.y + c.y >= 0:
					Style.draw_ghost(self, kind, _cell_rect(gp.x + c.x, gp.y + c.y))
		var off := _fall_offset()
		for c in Pieces.cells(kind, rot):
			if pos.y + c.y >= 0:
				var r := _cell_rect(pos.x + c.x, pos.y + c.y)
				r.position.y += off
				Style.draw_block(self, kind, r)

	# Lock flash
	for f in flashes:
		var cell: Vector2i = f["c"]
		var fs := StyleBoxFlat.new()
		fs.bg_color = Color(1, 1, 1, 0.75 * f["t"] / 0.22)
		fs.set_corner_radius_all(5)
		draw_style_box(fs, _cell_rect(cell.x, cell.y).grow(-2))

	# Particles
	for p in particles:
		var c: Color = p["color"]
		c.a = clampf(p["life"] / p["max"], 0.0, 1.0)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s, s) * 0.5, Vector2(s, s)), c)

	# Popups
	for i in popups.size():
		var p: Dictionary = popups[i]
		var life: float = p["t"] / p["max"]
		var c: Color = p["color"]
		c.a = minf(1.0, life * 2.5)
		var rise := (1.0 - life) * 40.0
		var grow := 1.0 + maxf(0.0, life - 0.85) * 2.0
		Style.text(self, Style.FONT_DISPLAY, Vector2(BOARD_POS.x, 360 - rise + i * 54), p["text"],
			int(42 * grow), c, HORIZONTAL_ALIGNMENT_CENTER, COLS * CELL, 10, Color(0.05, 0.02, 0.15, c.a))


## Attack "bullets" flying between the boards.
func _draw_projectiles() -> void:
	for pr in projectiles:
		if pr["t"] < 0.0:
			continue
		var k: float = pr["t"] / pr["dur"]
		var e := k * k * (3.0 - 2.0 * k)
		var p: Vector2 = pr["from"].lerp(pr["to"], e) + Vector2(0, -50.0 * sin(PI * k))
		draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), Color(1, 0.45, 0.3, 0.25))
		Style.draw_block(self, GARBAGE, Rect2(p - Vector2(6, 6), Vector2(12, 12)), 1.0 - 0.3 * k)


func _draw_touch_buttons() -> void:
	var down := touch_map.values()
	var playing := state == State.PLAYING
	for b in touch_buttons:
		var pressed: bool = down.has(b["name"]) or (playing and Input.is_action_pressed(b["name"]))
		var r: Rect2 = b["rect"]
		draw_style_box(_btn_styles[b["rect"].position][1 if pressed else 0], r)
		var center := r.get_center() + Vector2(0, 3 if pressed else -2)
		Style.draw_icon(self, b["icon"], center, 46.0, Color(1, 1, 1, 1.0 if playing else 0.5))
