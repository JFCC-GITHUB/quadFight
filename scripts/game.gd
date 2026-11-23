extends Control
## Single-player Tetris: SRS rotation, 7-bag, hold, ghost, DAS/ARR, lock delay.

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

enum State { PLAYING, PAUSED, OVER }

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

var gravity_acc := 0.0
var lock_timer := 0.0
var lock_resets := 0
var das_dir := 0
var das_timer := 0.0

var popup_text := ""
var popup_time := 0.0

var overlay: Control
var rng := RandomNumberGenerator.new()

# Touch buttons: name, label, rect, repeatable (held) or one-shot.
var touch_buttons: Array = []
var touch_map := {} # touch index -> button name


func _ready() -> void:
	rng.randomize()
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
		if event.is_action_pressed("confirm"):
			main.show_game()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		return
	if state != State.PLAYING:
		if state == State.PAUSED and event.is_action_pressed("confirm"):
			_toggle_pause()
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
		if state == State.PLAYING:
			_toggle_pause()


# ---------------------------------------------------------------- game loop

func _process(delta: float) -> void:
	popup_time = maxf(0.0, popup_time - delta)
	if state == State.PLAYING:
		_update_horizontal(delta)
		_update_gravity(delta)
	queue_redraw()


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


func _update_gravity(delta: float) -> void:
	var interval := gravity_interval()
	var soft := _held("soft_drop")
	if soft:
		interval = minf(interval, 0.05)
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
	_on_piece_moved()
	return true


func _rotate(dir: int) -> void:
	var new_rot := (rot + dir + 4) % 4
	for k in Pieces.kicks(kind, rot, new_rot):
		if not _collides(kind, new_rot, pos + k):
			pos += k
			rot = new_rot
			_on_piece_moved()
			return


func _hard_drop() -> void:
	while not _collides(kind, rot, pos + Vector2i(0, 1)):
		pos.y += 1
		score += 2
	_lock()


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


func ghost_pos() -> Vector2i:
	var p := pos
	while not _collides(kind, rot, p + Vector2i(0, 1)):
		p.y += 1
	return p


func _next_kind() -> int:
	while queue.size() < 7:
		if bag.is_empty():
			bag = [0, 1, 2, 3, 4, 5, 6]
			bag.shuffle()
		queue.append(bag.pop_back())
	return queue.pop_front()


func _spawn(forced := -1) -> void:
	kind = forced if forced >= 0 else _next_kind()
	while queue.size() < 7:
		if bag.is_empty():
			bag = [0, 1, 2, 3, 4, 5, 6]
			bag.shuffle()
		queue.append(bag.pop_back())
	rot = 0
	pos = Vector2i(3, -1)
	gravity_acc = 0.0
	lock_timer = 0.0
	lock_resets = 0
	if forced < 0:
		hold_used = false
	if _collides(kind, rot, pos):
		_game_over()


func _lock() -> void:
	var topped_out := true
	for c in Pieces.cells(kind, rot):
		var p: Vector2i = pos + c
		if p.y >= 0:
			board[p.y][p.x] = kind
			topped_out = false
	_clear_lines()
	if topped_out:
		_game_over()
		return
	_spawn()


func _clear_lines() -> void:
	var cleared := 0
	var y := ROWS - 1
	while y >= 0:
		if not board[y].has(-1):
			board.remove_at(y)
			board.insert(0, _empty_row())
			cleared += 1
		else:
			y -= 1
	if cleared == 0:
		return
	var table := [0, 100, 300, 500, 800]
	score += table[cleared] * level
	lines += cleared
	level = lines / 10 + 1
	popup_text = ["", "SINGLE", "DOUBLE", "TRIPLE", "TETRIS!"][cleared]
	popup_time = 1.0


# ---------------------------------------------------------------- pause / game over

func _toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		touch_map.clear()
		_open_overlay("PAUSED", "")
		UI.button(overlay, "RESUME", Rect2(120, 420, 300, 80), _toggle_pause, 32, Color("2f9e55"))
		UI.button(overlay, "MENU", Rect2(120, 520, 300, 70), func(): main.show_title(), 28)
	elif state == State.PAUSED:
		state = State.PLAYING
		_close_overlay()


func _game_over() -> void:
	state = State.OVER
	touch_map.clear()
	var rank := Scores.add(score, lines, level)
	var info := "Score  %d\nLines  %d   Level  %d" % [score, lines, level]
	if rank == 1:
		info += "\n\nNEW BEST!"
	elif rank > 0:
		info += "\n\nRank #%d" % rank
	_open_overlay("GAME OVER", info)
	UI.button(overlay, "PLAY AGAIN", Rect2(120, 520, 300, 80), func(): main.show_game(), 32, Color("2f9e55"))
	UI.button(overlay, "MENU", Rect2(120, 620, 140, 70), func(): main.show_title(), 26)
	UI.button(overlay, "SCORES", Rect2(280, 620, 140, 70), func(): main.show_leaderboard(), 26)


func _open_overlay(title: String, info: String) -> void:
	_close_overlay()
	overlay = Control.new()
	overlay.size = size
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = size
	overlay.add_child(dim)
	UI.label(overlay, title, Rect2(0, 220, 540, 80), 52)
	if info != "":
		UI.label(overlay, info, Rect2(0, 310, 540, 190), 28, Color("ffd400"))


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


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1020"))

	# Board
	var board_rect := Rect2(BOARD_POS, Vector2(COLS, ROWS) * CELL)
	draw_rect(board_rect, Color("141a33"))
	for x in range(1, COLS):
		draw_line(BOARD_POS + Vector2(x * CELL, 0), BOARD_POS + Vector2(x * CELL, ROWS * CELL), Color(1, 1, 1, 0.05))
	for y in range(1, ROWS):
		draw_line(BOARD_POS + Vector2(0, y * CELL), BOARD_POS + Vector2(COLS * CELL, y * CELL), Color(1, 1, 1, 0.05))
	for y in ROWS:
		for x in COLS:
			var v: int = board[y][x]
			if v >= 0:
				_draw_block(_cell_rect(x, y), Pieces.COLORS[v])
	if state != State.OVER:
		var gp := ghost_pos()
		for c in Pieces.cells(kind, rot):
			if gp.y + c.y >= 0:
				_draw_block(_cell_rect(gp.x + c.x, gp.y + c.y), Pieces.COLORS[kind], 0.25)
		for c in Pieces.cells(kind, rot):
			if pos.y + c.y >= 0:
				_draw_block(_cell_rect(pos.x + c.x, pos.y + c.y), Pieces.COLORS[kind])
	draw_rect(board_rect, Color(1, 1, 1, 0.25), false, 2.0)

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
	_stat(font, "SCORE", str(score), 520)
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

	if popup_time > 0.0 and popup_text != "":
		draw_string(font, Vector2(BOARD_POS.x, 360), popup_text, HORIZONTAL_ALIGNMENT_CENTER, COLS * CELL, 44, Color(1, 1, 1, minf(1.0, popup_time * 2.0)))


func _stat(font: Font, title: String, value: String, y: float) -> void:
	draw_string(font, Vector2(SIDE_X, y), title, HORIZONTAL_ALIGNMENT_LEFT, 172, 18, Color("8a93b8"))
	draw_string(font, Vector2(SIDE_X, y + 38), value, HORIZONTAL_ALIGNMENT_LEFT, 172, 38, Color.WHITE)
