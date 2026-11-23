extends Control
## Single-player falling-block puzzle: SRS rotation, 7-bag, hold, ghost, DAS/ARR, lock delay,
## plus line-clear / drop / lock animations and sound.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Pieces := preload("res://scripts/pieces.gd")
const TouchLayout := preload("res://scripts/touch_layout.gd")
const OptionsScreen := preload("res://scripts/options.gd")

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


func _ready() -> void:
	_apply_settings()
	for r in ROWS:
		board.append(_empty_row())
	_spawn()
	Sfx.start_music()


func _exit_tree() -> void:
	Sfx.stop_music()


## (Re)reads options: touch layout, auto-repeat speed. Called at start and after the options screen.
func _apply_settings() -> void:
	touch_buttons = TouchLayout.buttons(Settings.layout, Settings.swap_sides)
	_btn_styles.clear()
	for b in touch_buttons:
		_btn_styles[b["name"]] = [Style.button_box(b["scheme"], false, 20), Style.button_box(b["scheme"], true, 20)]
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
		das_timer = -das
		_move(dir)
		return
	das_timer += delta
	while das_timer >= arr:
		das_timer -= arr
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
				"t": 0.2, "color": Style.piece_color(kind)})
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
					"color": Style.piece_color(board[y][x]), "size": randf_range(3, 7),
				})
	_popup(["", "SINGLE", "DOUBLE", "TRIPLE", "QUAD!"][n],
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
		var c := _open_overlay(Rect2(70, 250, 400, 440))
		UI.label(c, "PAUSED", Rect2(0, 30, 400, 70), 44, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
		UI.button(c, "RESUME", Rect2(40, 116, 320, 92), _toggle_pause, 32, Style.BTN_PRIMARY, "play")
		UI.button(c, "OPTIONS", Rect2(40, 224, 320, 78), _open_options, 26, Style.BTN_GLASS, "gear")
		UI.button(c, "MENU", Rect2(40, 318, 320, 78), func(): main.show_title(), 26, Style.BTN_GLASS, "home")
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
	add_child(o)


func _game_over() -> void:
	state = State.OVER
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
	var tag := ""
	if rank == 1:
		tag = "NEW BEST!"
	elif rank > 0:
		tag = "RANK #%d" % rank
	if tag != "":
		UI.label(c, tag, Rect2(0, 248, 440, 46), 30, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
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
	var c := UI.card(overlay, card_rect)
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
	draw_texture_rect(Style.bg_texture(), Rect2(Vector2.ZERO, size), false)
	_draw_header()
	_draw_side_panels()

	# Everything on/over the board shakes together.
	if shake_time > 0.0:
		var m := shake_mag * shake_time / shake_dur
		draw_set_transform(Vector2(randf_range(-m, m), randf_range(-m, m)))
	_draw_board()
	draw_set_transform(Vector2.ZERO)

	_draw_touch_buttons()


func _draw_header() -> void:
	# Pause button
	var pressed := state == State.PAUSED
	draw_style_box(Style.button_box(Style.BTN_GLASS, pressed, 16), PAUSE_RECT)
	Style.draw_icon(self, "pause", PAUSE_RECT.get_center() + Vector2(0, 2 if pressed else -2), 28)
	# Score
	var cap := Style.caption_font()
	Style.text(self, cap, Vector2(0, 42), "SCORE", 16, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 88), str(int(round(display_score))), 40, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	# Best
	var best := maxi(Scores.best(), score)
	Style.text(self, cap, Vector2(400, 42), "BEST", 16, Style.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 124)
	Style.text(self, Style.FONT_DISPLAY, Vector2(400, 74), str(best), 22, Style.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 124)


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
	var stats := [["LEVEL", str(level), 226.0], ["LINES", str(lines), 322.0]]
	for st in stats:
		var r := Rect2(LEFT_X, st[2], COL_W, 84)
		_side_panel(r, st[0])
		Style.text(self, Style.FONT_DISPLAY, r.position + Vector2(0, 68), st[1], 30, Style.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, COL_W)

	var next_r := Rect2(RIGHT_X, BOARD_POS.y, COL_W, 300)
	_side_panel(next_r, "NEXT")
	var y := next_r.position.y + 76
	for i in 3:
		var cell := 20.0 if i == 0 else 16.0
		Style.draw_piece_centered(self, Pieces.cells(queue[i], 0), queue[i],
			Vector2(RIGHT_X + COL_W * 0.5, y), cell, 1.0 if i == 0 else 0.8)
		y += 86.0 if i == 0 else 72.0


func _draw_board() -> void:
	var board_rect := Rect2(BOARD_POS, Vector2(COLS, ROWS) * CELL)
	var danger := _danger() and state != State.OVER
	var pulse := 0.5 + 0.5 * sin(time * 6.0)
	var border := Color(1, 0.3, 0.4, 0.5 + 0.4 * pulse) if danger else Color(0.55, 0.65, 1, 0.35)
	var glow := Color(1, 0.2, 0.35, 0.35) if danger else Color(0.2, 0.55, 1, 0.28)
	draw_style_box(Style.panel_box(Color(0.02, 0.02, 0.08, 0.86), 12, border, glow, 22), board_rect.grow(6))
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
				Style.draw_block(self, v, _cell_rect(x, y), 1.0 - clear_progress if clearing else 1.0)
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


func _draw_touch_buttons() -> void:
	var down := touch_map.values()
	var playing := state == State.PLAYING
	for b in touch_buttons:
		var pressed: bool = down.has(b["name"]) or (playing and Input.is_action_pressed(b["name"]))
		var r: Rect2 = b["rect"]
		draw_style_box(_btn_styles[b["name"]][1 if pressed else 0], r)
		var center := r.get_center() + Vector2(0, 3 if pressed else -2)
		Style.draw_icon(self, b["icon"], center, 46.0, Color(1, 1, 1, 1.0 if playing else 0.5))
