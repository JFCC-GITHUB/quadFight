extends RefCounted
## Computer opponent for VS mode: a self-playing board with a simple placement AI.
## Level 1-10 changes how fast it reacts / moves and how often it blunders.

const Pieces := preload("res://scripts/pieces.gd")
const Characters := preload("res://scripts/characters.gd")

const COLS := 10
const ROWS := 20
const LOCK_DELAY := 0.5
const GARBAGE := 7  # board value of a garbage block

const NAMES := ["Rookie", "Beginner", "Casual", "Regular", "Skilled",
	"Advanced", "Expert", "Master", "Elite", "Boss"]
const MISTAKE := [0.40, 0.33, 0.27, 0.22, 0.18, 0.14, 0.11, 0.08, 0.05, 0.03]
const MAX_GRAVITY_LEVEL := 7  # VS mode: gravity stops speeding up here

var level := 3
var board: Array = []
var bag: Array = []
var queue: Array = []
var kind := 0
var rot := 0
var pos := Vector2i.ZERO
var lines := 0
var combo := 0
var incoming := 0   # garbage blocks waiting to drop on this board
var wall_left := 0   # pieces until an iron wall on this board crumbles
var special_in: Array = []   # special attacks (character ids) waiting to land on this board
var alive := true

var gravity_acc := 0.0
var lock_timer := 0.0
var think_timer := 0.0
var act_timer := 0.0
var has_plan := false
var plan_rot := 0
var plan_x := 0
var failed_moves := 0

var on_clear: Callable = func(_rows, _combo): pass   # (rows_cleared: int, combo: int)
var on_hit: Callable = func(_n): pass                # garbage landed (count)
var on_special: Callable = func(_id): pass           # a special attack landed (character id)
var rng := RandomNumberGenerator.new()


## Timing and mistake rate for a level (also used by the level-select screen).
static func params(lv: int) -> Dictionary:
	var t := clampf(float(lv - 1) / 9.0, 0.0, 1.0)
	return {
		"think": lerpf(1.6, 0.35, pow(t, 0.8)),     # reaction time after a piece appears (s)
		"act": lerpf(0.7, 0.16, pow(t, 0.8)),      # time per rotate / shift (s)
		"mistake": MISTAKE[clampi(lv - 1, 0, 9)],   # chance to pick a bad placement
	}


func _init(lv: int = 3) -> void:
	level = lv
	rng.randomize()
	for r in ROWS:
		board.append(_empty_row())
	_spawn()


func _empty_row() -> Array:
	var row: Array = []
	row.resize(COLS)
	row.fill(-1)
	return row


func game_level() -> int:
	return mini(lines / 10 + 1, MAX_GRAVITY_LEVEL)


func gravity_interval() -> float:
	var lv := game_level()
	return pow(0.8 - float(lv - 1) * 0.007, float(lv - 1))


# ---------------------------------------------------------------- simulation

func step(delta: float) -> void:
	if not alive:
		return
	var interval := gravity_interval()
	if _collides(kind, rot, pos + Vector2i(0, 1)):
		gravity_acc = 0.0
		lock_timer += delta
		if lock_timer >= LOCK_DELAY:
			_lock()
			return
	else:
		lock_timer = 0.0
		gravity_acc += delta
		while gravity_acc >= interval:
			gravity_acc -= interval
			if _collides(kind, rot, pos + Vector2i(0, 1)):
				break
			pos.y += 1
	_think(delta)


func _think(delta: float) -> void:
	var p := params(level)
	if not has_plan:
		think_timer -= delta
		if think_timer <= 0.0:
			_make_plan(p["mistake"])
			act_timer = p["act"] * 0.5
		return
	act_timer -= delta
	var guard := 0
	while act_timer <= 0.0 and has_plan and alive and guard < 4:
		guard += 1
		act_timer += p["act"]
		_do_action()


func _do_action() -> void:
	if rot != plan_rot and failed_moves < 3:
		if not _rotate():
			failed_moves += 1
	elif pos.x != plan_x and failed_moves < 3:
		if not _move(signi(plan_x - pos.x)):
			failed_moves += 1
	else:
		_hard_drop()


func _collides(k: int, r: int, p: Vector2i) -> bool:
	for c in Pieces.cells(k, r):
		var x: int = p.x + c.x
		var y: int = p.y + c.y
		if x < 0 or x >= COLS or y >= ROWS:
			return true
		if y >= 0 and board[y][x] != -1:
			return true
	return false


func _move(dx: int) -> bool:
	if _collides(kind, rot, pos + Vector2i(dx, 0)):
		return false
	pos.x += dx
	_on_moved()
	return true


func _rotate() -> bool:
	var new_rot := (rot + 1) % 4
	for k in Pieces.kicks(kind, rot, new_rot):
		if not _collides(kind, new_rot, pos + k):
			pos += k
			rot = new_rot
			_on_moved()
			return true
	return false


func _on_moved() -> void:
	if _collides(kind, rot, pos + Vector2i(0, 1)):
		lock_timer = 0.0


func _hard_drop() -> void:
	while not _collides(kind, rot, pos + Vector2i(0, 1)):
		pos.y += 1
	_lock()


func _refill() -> void:
	while queue.size() < 7:
		if bag.is_empty():
			bag = [0, 1, 2, 3, 4, 5, 6]
			bag.shuffle()
		queue.append(bag.pop_back())


func _spawn() -> void:
	_refill()
	kind = queue.pop_front()
	_refill()
	rot = 0
	pos = Vector2i(3, -1)
	gravity_acc = 0.0
	lock_timer = 0.0
	has_plan = false
	failed_moves = 0
	think_timer = params(level)["think"]
	if _collides(kind, rot, pos):
		alive = false


func _lock() -> void:
	for c in Pieces.cells(kind, rot):
		var p: Vector2i = pos + c
		if p.y >= 0:
			board[p.y][p.x] = kind
	if wall_left > 0:
		wall_left -= 1
		if wall_left == 0:
			Characters.crumble(board)
	var cleared := 0
	var y := ROWS - 1
	while y >= 0:
		if Characters.is_clearable(board[y]):
			board.remove_at(y)
			board.push_front(_empty_row())
			cleared += 1
		else:
			y -= 1
	if cleared > 0:
		lines += cleared
		combo += 1
		on_clear.call(cleared, combo)
	else:
		combo = 0
		apply_incoming()
	if alive:
		_spawn()


## Drops pending garbage blocks onto random columns. Overflowing the board loses the game.
func apply_incoming() -> void:
	for sid in special_in:
		on_special.call(sid)
		if not Characters.apply(sid, board):
			alive = false
			special_in.clear()
			return
		if sid == "bastion":
			wall_left = Characters.WALL_LIFE
	special_in.clear()
	if incoming <= 0:
		return
	var n := incoming
	incoming = 0
	for i in n:
		var x := rng.randi_range(0, COLS - 1)
		var top := ROWS
		for yy in ROWS:
			if board[yy][x] != -1:
				top = yy
				break
		if top - 1 < 0:
			alive = false
			break
		board[top - 1][x] = GARBAGE
	on_hit.call(n)


# ---------------------------------------------------------------- AI

func _make_plan(mistake: float) -> void:
	var cands: Array = []
	for r in (1 if kind == 1 else 4):
		var minx := 99
		var maxx := -99
		for c in Pieces.cells(kind, r):
			minx = mini(minx, c.x)
			maxx = maxi(maxx, c.x)
		for x in range(-minx, COLS - maxx):
			var p := Vector2i(x, -1)
			if _collides(kind, r, p):
				continue
			while not _collides(kind, r, p + Vector2i(0, 1)):
				p.y += 1
			cands.append([_evaluate(kind, r, p), r, x])
	if cands.is_empty():
		has_plan = true
		plan_rot = rot
		plan_x = pos.x
		return
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var pick := 0
	var n := cands.size()
	if rng.randf() < mistake and n > 4:
		if rng.randf() < 0.85:
			# a slip: a mediocre placement (somewhere in the 10%-35% rank band)
			pick = rng.randi_range(int(n * 0.1), int(n * 0.35))
		else:
			# a real blunder: any placement from the worse half
			pick = rng.randi_range(int(n * 0.5), n - 1)
	elif n > 1 and rng.randf() < 0.12:
		pick = 1  # sometimes just the second-best, like a human
	plan_rot = cands[pick][1]
	plan_x = cands[pick][2]
	has_plan = true


## Heuristic: low stack, few holes, flat surface, clear lines.
func _evaluate(k: int, r: int, p: Vector2i) -> float:
	var tb: Array = []
	for row in board:
		tb.append(row.duplicate())
	for c in Pieces.cells(k, r):
		var q: Vector2i = p + c
		if q.y >= 0:
			tb[q.y][q.x] = k
	var cleared := 0
	var y := ROWS - 1
	while y >= 0:
		if Characters.is_clearable(tb[y]):
			tb.remove_at(y)
			tb.push_front(_empty_row())
			cleared += 1
		else:
			y -= 1
	var heights: Array = []
	var holes := 0
	for x in COLS:
		var h := 0
		var seen := false
		for yy in ROWS:
			if tb[yy][x] != -1:
				if not seen:
					h = ROWS - yy
					seen = true
			elif seen:
				holes += 1
		heights.append(h)
	var agg := 0
	var bump := 0
	var maxh := 0
	for x in COLS:
		agg += heights[x]
		maxh = maxi(maxh, heights[x])
		if x < COLS - 1:
			bump += absi(heights[x] - heights[x + 1])
	var score := -0.51 * agg + 0.76 * cleared + 0.2 * cleared * cleared - 0.36 * holes - 0.18 * bump
	if maxh > 14:
		score -= 0.6 * (maxh - 14)
	return score
