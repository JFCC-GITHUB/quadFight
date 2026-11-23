extends Control
## Single-player Tetris: SRS rotation, 7-bag, hold, ghost, DAS/ARR, lock delay,
## plus line-clear / drop / lock animations and sound.

const UI := preload("res://scripts/ui.gd")
const Pieces := preload("res://scripts/pieces.gd")

const COLS := 10
const ROWS := 20
const CELL := 32
const BOARD_POS := Vector2(16, 100)
const SIDE_X := 352.0

const DAS := 0.13
const ARR := 0.035
const LOCK_DELAY := 0.5
const MAX_LOCK_RESETS := 15
const CLEAR_TIME := 0.38

enum State { PLAYING, CLEARING, PAUSED, OVER }

var main: Node

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

var overlay: Control

# Touch buttons: name, label, rect, repeatable (held) or one-shot.
var touch_buttons: Array = []
var touch_map := {} # touch index -> button name


func _ready() -> void:
	var w := 164.0
	var h := 84.0
	var x0 := [16.0, 188.0, 360.0]
	var y0 := [772.0, 868.0]
	touch_buttons = [
		{"name": "move_left", "label": "<", "rect": Rect2(x0[0], y0[0], w, h), "held": true},
		{"name": "rotate_cw", "label": "ROTATE", "rect": Rect2(x0[1], y0[0], w, h), "held": false},
		{"name": "move_right", "label": ">", "rect": Rect2(x0[2], y0[0], w, h), "held": true},
		{"name": "soft_drop", "label": "v", "rect": Rect2(x0[0], y0[1], w, h), "held": true},
		{"name": "hard_drop", "label": "DROP", "rect": Rect2(x0[1], y0[1], w, h), "held": false},
		{"name": "hold", "label": "HOLD", "rect": Rect2(x0[2], y0[1], w, h), "held": false},
	]
	for r in ROWS:
		board.append(_empty_row())
	_spawn()
	Sfx.start_music()


func _exit_tree() -> void:
	Sfx.stop_music()


func _empty_row() -> Array:
	var row: Array = []
	row.resize(COLS)
	row.fill(-1)
	return row


# ---------------------------------------------------------------- input

func _held(action: String) -> bool:
	return Input.is_action_pressed(action) or touch_map.values().has(action)


func _input(event: InputEvent) -> void:
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


func _button_at(p: Vector2) -> Dictionary:
	for b in touch_buttons:
		if b["rect"].has_point(p):
			return b
	return {}


func _touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if Rect2(470, 20, 56, 56).has_point(event.position) and state != State.OVER:
			_toggle_pause()
			return
		if state != State.PLAYING:
			return
		var b := _button_at(event.position)
		if b.is_empty():
			return
		if b["held"]:
			touch_map[event.index] = b["name"]
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
	_update_effects(delta)
	match state:
		State.PLAYING:
			_update_horizontal(delta)
			_update_gravity(delta)
		State.CLEARING:
			clear_timer -= delta
			if clear_timer <= 0.0:
				_finish_clear()
	queue_redraw()


func _update_effects(delta: float) -> void:
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


func _update_horizontal(delta: float) -> void:
	var dir := int(_held("move_right")) - int(_held("move_left"))
	if dir == 0:
		das_dir = 0
		return
	if dir != das_dir:
		das_dir = dir
		das_timer = -DAS
		_move(dir)
		return
	das_timer += delta
	while das_timer >= ARR:
		das_timer -= ARR
		_move(dir)


func gravity_interval() -> float:
	return pow(0.8 - float(level - 1) * 0.007, float(level - 1))


func _current_interval() -> float:
	var interval := gravity_interval()
	if _held("soft_drop"):
		interval = minf(interval, 0.05)
	return interval


func _update_gravity(delta: float) -> void:
	var interval := _current_interval()
	var soft := _held("soft_drop")
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
	Sfx.play("move")
	_on_piece_moved()
	return true


func _rotate(dir: int) -> void:
	var new_rot := (rot + dir + 4) % 4
	for k in Pieces.kicks(kind, rot, new_rot):
		if not _collides(kind, new_rot, pos + k):
			pos += k
			rot = new_rot
			Sfx.play("rotate")
			_on_piece_moved()
			return


func _hard_drop() -> void:
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
				"t": 0.2, "color": Pieces.COLORS[kind]})
	_shake(0.12, 3.0)
	Sfx.play("drop")
	_lock(false)


func _hold() -> void:
	if hold_used:
		return
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
	if _collides(kind, rot, pos):
		_game_over()


func _lock(play_sound := true) -> void:
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
	_spawn()


func _begin_clear(rows: Array) -> void:
	state = State.CLEARING
	clear_rows = rows
	clear_timer = CLEAR_TIME
	var n := rows.size()
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
					"color": Pieces.COLORS[board[y][x]], "size": randf_range(3, 7),
				})
	_popup(["", "SINGLE", "DOUBLE", "TRIPLE", "TETRIS!"][n],
		Color("ffd400") if n == 4 else Color.WHITE)
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


# ---------------------------------------------------------------- pause / game over

func _toggle_pause() -> void:
	if state == State.PLAYING or state == State.CLEARING:
		paused_from = state
		state = State.PAUSED
		touch_map.clear()
		Sfx.pause_music(true)
		_open_overlay("PAUSED", "")
		UI.button(overlay, "RESUME", Rect2(120, 400, 300, 80), _toggle_pause, 32, Color("2f9e55"))
		UI.audio_toggles(overlay, 500)
		UI.button(overlay, "MENU", Rect2(120, 580, 300, 70), func(): main.show_title(), 28)
	elif state == State.PAUSED:
		state = paused_from
		Sfx.pause_music(false)
		_close_overlay()


func _game_over() -> void:
	state = State.OVER
	touch_map.clear()
	Sfx.stop_music()
	Sfx.play("gameover")
	if Scores.qualifies(score):
		_open_name_entry()
	else:
		_show_over(0)


func _show_over(rank: int) -> void:
	entering_name = false
	var info := "Score  %d\nLines  %d   Level  %d" % [score, lines, level]
	if rank == 1:
		info += "\n\nNEW BEST!"
	elif rank > 0:
		info += "\n\nRank #%d" % rank
	_open_overlay("GAME OVER", info)
	UI.button(overlay, "PLAY AGAIN", Rect2(120, 520, 300, 80), func(): main.show_game(), 32, Color("2f9e55"))
	UI.button(overlay, "MENU", Rect2(120, 620, 140, 70), func(): main.show_title(), 26)
	UI.button(overlay, "SCORES", Rect2(280, 620, 140, 70), func(): main.show_leaderboard(), 26)


func _open_name_entry() -> void:
	entering_name = true
	name_cursor = 0
	var saved: String = Scores.last_name.to_upper()
	for i in 3:
		var ch := saved.unicode_at(i) if i < saved.length() else 65
		name_chars[i] = clampi(ch - 65, 0, 25)
	_open_overlay("NEW HIGH SCORE!", "Score  %d\nEnter your initials" % score)
	name_labels.clear()
	for i in 3:
		var cx := 150.0 + i * 120.0
		var idx := i
		UI.button(overlay, "^", Rect2(cx - 40, 420, 80, 56), func(): _step_letter(idx, 1), 28)
		name_labels.append(UI.label(overlay, "A", Rect2(cx - 40, 480, 80, 90), 72))
		UI.button(overlay, "v", Rect2(cx - 40, 575, 80, 56), func(): _step_letter(idx, -1), 24)
	UI.button(overlay, "OK", Rect2(120, 670, 300, 80), _confirm_name, 34, Color("2f9e55"))
	_refresh_name()


func _step_letter(i: int, d: int) -> void:
	name_cursor = i
	name_chars[i] = (name_chars[i] + d + 26) % 26
	_refresh_name()


func _refresh_name() -> void:
	for i in 3:
		name_labels[i].text = char(65 + name_chars[i])
		name_labels[i].add_theme_color_override("font_color",
			Color("ffd400") if i == name_cursor else Color.WHITE)


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
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		_confirm_name()


func _confirm_name() -> void:
	if not entering_name:
		return
	var player := ""
	for c in name_chars:
		player += char(65 + c)
	_show_over(Scores.add(player, score, lines, level))


func _open_overlay(title: String, info: String) -> void:
	_close_overlay()
	overlay = Control.new()
	overlay.size = size
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.size = size
	overlay.add_child(dim)
	UI.label(overlay, title, Rect2(0, 200, 540, 80), 46)
	if info != "":
		UI.label(overlay, info, Rect2(0, 290, 540, 120), 26, Color("ffd400"))


func _close_overlay() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null


# ---------------------------------------------------------------- drawing

func _cell_rect(cx: int, cy: int) -> Rect2:
	return Rect2(BOARD_POS + Vector2(cx, cy) * CELL, Vector2(CELL, CELL))


func _draw_block(r: Rect2, color: Color, alpha := 1.0) -> void:
	color.a = alpha
	draw_rect(r.grow(-1), color)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 4)), Color(1, 1, 1, 0.25 * alpha))


func _draw_mini(k: int, origin: Vector2, scale := 16.0, alpha := 1.0) -> void:
	for c in Pieces.cells(k, 0):
		_draw_block(Rect2(origin + Vector2(c) * scale, Vector2(scale, scale)), Pieces.COLORS[k], alpha)


## Smooth falling: interpolate the active piece between rows.
func _fall_offset() -> float:
	if state != State.PLAYING or _collides(kind, rot, pos + Vector2i(0, 1)):
		return 0.0
	return clampf(gravity_acc / _current_interval(), 0.0, 1.0) * CELL


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1020"))

	# Everything on/over the board shakes together.
	if shake_time > 0.0:
		var m := shake_mag * shake_time / shake_dur
		draw_set_transform(Vector2(randf_range(-m, m), randf_range(-m, m)))

	var board_rect := Rect2(BOARD_POS, Vector2(COLS, ROWS) * CELL)
	draw_rect(board_rect, Color("141a33"))
	for x in range(1, COLS):
		draw_line(BOARD_POS + Vector2(x * CELL, 0), BOARD_POS + Vector2(x * CELL, ROWS * CELL), Color(1, 1, 1, 0.05))
	for y in range(1, ROWS):
		draw_line(BOARD_POS + Vector2(0, y * CELL), BOARD_POS + Vector2(COLS * CELL, y * CELL), Color(1, 1, 1, 0.05))

	var clear_progress := 1.0 - clear_timer / CLEAR_TIME
	for y in ROWS:
		var clearing: bool = clear_rows.has(y)
		for x in COLS:
			var v: int = board[y][x]
			if v < 0:
				continue
			if clearing:
				_draw_block(_cell_rect(x, y), Pieces.COLORS[v], 1.0 - clear_progress)
			else:
				_draw_block(_cell_rect(x, y), Pieces.COLORS[v])
		if clearing:
			var pulse := 0.5 + 0.5 * sin(clear_progress * TAU * 3.0)
			var row_w := COLS * CELL * (1.0 - clear_progress * 0.6)
			var rx := BOARD_POS.x + (COLS * CELL - row_w) * 0.5
			draw_rect(Rect2(rx, BOARD_POS.y + y * CELL, row_w, CELL), Color(1, 1, 1, 0.35 + 0.5 * pulse))

	# Hard-drop trails
	for t in trails:
		var a: float = t["t"] / 0.2
		var c: Color = t["color"]
		c.a = 0.4 * a
		var top: float = BOARD_POS.y + t["y0"] * CELL
		var bottom: float = BOARD_POS.y + t["y1"] * CELL
		draw_rect(Rect2(BOARD_POS.x + t["x"] * CELL + 4, top, CELL - 8, bottom - top), c)

	if state == State.PLAYING or state == State.PAUSED:
		var gp := ghost_pos()
		for c in Pieces.cells(kind, rot):
			if gp.y + c.y >= 0:
				_draw_block(_cell_rect(gp.x + c.x, gp.y + c.y), Pieces.COLORS[kind], 0.22)
		var off := _fall_offset()
		for c in Pieces.cells(kind, rot):
			if pos.y + c.y >= 0:
				var r := _cell_rect(pos.x + c.x, pos.y + c.y)
				r.position.y += off
				_draw_block(r, Pieces.COLORS[kind])

	# Lock flash
	for f in flashes:
		var cell: Vector2i = f["c"]
		draw_rect(_cell_rect(cell.x, cell.y).grow(-1), Color(1, 1, 1, 0.8 * f["t"] / 0.22))

	# Particles
	for p in particles:
		var c: Color = p["color"]
		c.a = clampf(p["life"] / p["max"], 0.0, 1.0)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s, s) * 0.5, Vector2(s, s)), c)

	draw_rect(board_rect, Color(1, 1, 1, 0.25), false, 2.0)

	# Popups
	for i in popups.size():
		var p: Dictionary = popups[i]
		var life: float = p["t"] / p["max"]
		var c: Color = p["color"]
		c.a = minf(1.0, life * 2.5)
		var rise := (1.0 - life) * 40.0
		draw_string(font, Vector2(BOARD_POS.x, 340 - rise + i * 52), p["text"],
			HORIZONTAL_ALIGNMENT_CENTER, COLS * CELL, 44, c)

	draw_set_transform(Vector2.ZERO)

	# Side panel
	var pw := 172.0
	draw_string(font, Vector2(SIDE_X, 118), "HOLD", HORIZONTAL_ALIGNMENT_LEFT, pw, 18, Color("8a93b8"))
	draw_rect(Rect2(SIDE_X, 126, pw, 76), Color("141a33"))
	if hold_kind >= 0:
		_draw_mini(hold_kind, Vector2(SIDE_X + 52, 140), 16.0, 0.4 if hold_used else 1.0)
	draw_string(font, Vector2(SIDE_X, 232), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, pw, 18, Color("8a93b8"))
	draw_rect(Rect2(SIDE_X, 240, pw, 240), Color("141a33"))
	for i in 3:
		_draw_mini(queue[i], Vector2(SIDE_X + 52, 254 + i * 76))
	_stat(font, "SCORE", str(int(round(display_score))), 520)
	_stat(font, "LINES", str(lines), 590)
	_stat(font, "LEVEL", str(level), 660)
	draw_string(font, Vector2(16, 70), "BEST %d" % maxi(Scores.best(), score), HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color("ffd400"))

	# Pause button
	draw_rect(Rect2(470, 20, 56, 56), Color("2b3a6b"))
	draw_rect(Rect2(487, 34, 8, 28), Color.WHITE)
	draw_rect(Rect2(502, 34, 8, 28), Color.WHITE)

	# Touch buttons
	var down := touch_map.values()
	for b in touch_buttons:
		var pressed: bool = down.has(b["name"])
		var col := Color("3d4f8f") if pressed else Color("26335f")
		draw_rect(b["rect"], col)
		draw_rect(b["rect"], Color(1, 1, 1, 0.2), false, 2.0)
		draw_string(font, b["rect"].position + Vector2(0, 54), b["label"], HORIZONTAL_ALIGNMENT_CENTER, b["rect"].size.x, 30, Color.WHITE)


func _stat(font: Font, title: String, value: String, y: float) -> void:
	draw_string(font, Vector2(SIDE_X, y), title, HORIZONTAL_ALIGNMENT_LEFT, 172, 18, Color("8a93b8"))
	draw_string(font, Vector2(SIDE_X, y + 38), value, HORIZONTAL_ALIGNMENT_LEFT, 172, 38, Color.WHITE)
