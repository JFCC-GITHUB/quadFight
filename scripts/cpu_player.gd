extends RefCounted
## Computer opponent for VS mode: a self-playing board with a simple placement AI that plays like a person:
## it only presses keys (rotate cw/ccw, move, hard drop) with the same rules as the player, never teleports,
## has input lag, a perception + thinking delay that grows with a messy stack, key presses with human jitter,
## DAS/ARR for long shifts, slips that it may or may not notice, and more mistakes when the stack is high.

const Pieces := preload("res://scripts/pieces.gd")
const Characters := preload("res://scripts/characters.gd")

const COLS := 10
const ROWS := 20
const LOCK_DELAY := 0.5
const INPUT_LAG := 0.05  # keyboard + screen latency before the first key of a piece (s)
const GARBAGE := 7  # board value of a garbage block

const MAX_LEVEL := 20
const NAMES := ["Rookie", "Beginner", "Casual", "Regular", "Skilled",
	"Advanced", "Expert", "Master", "Elite", "Boss",
	"Veteran", "Champion", "Prodigy", "Phantom", "Legend",
	"Mythic", "Overlord", "Demigod", "Cosmic", "Perfect"]
const MISTAKE := [0.40, 0.33, 0.27, 0.22, 0.18, 0.14, 0.11, 0.08, 0.05, 0.03,
	0.02, 0.015, 0.01, 0.007, 0.005, 0.004, 0.003, 0.002, 0.0015, 0.001]
const LOOKAHEAD_FROM := 11  # from this level on, placements are chosen with the next piece in mind
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
var special_in: Array = []   # special attacks (character ids) waiting to land on this board
var alive := true

var gravity_acc := 0.0
var lock_timer := 0.0
var think_timer := 0.0
var has_plan := false
var plan_rot := 0   # where the piece should end up
var plan_x := 0
var exec_rot := 0   # where the fingers aim (differs from the plan after a slip)
var exec_x := 0
var actions: Array = []   # timed key presses [time since scheduling, "rot" | "move" | "drop", arg]
var plan_t := 0.0
var fixes := 0
var placed := 0     # pieces locked / key presses made (read by the speed test)
var presses := 0

var on_clear: Callable = func(_rows, _combo): pass   # (rows_cleared: int, combo: int)
var on_hit: Callable = func(_n): pass                # garbage landed (count)
var on_special: Callable = func(_id): pass           # a special attack landed (character id)
var aim := false          # steer the stack toward the clears its special attack needs
var want: Dictionary = {}  # clear size -> how many more of it the special needs
var rng := RandomNumberGenerator.new()


## Human timing for a level (also used by the level-select screen). Level 20 is a top human player:
## about 2.5-3 pieces/s, ~0.12 s to decide (it plans during the previous piece), ~12 key presses/s.
static func params(lv: int) -> Dictionary:
	var t := clampf(float(lv - 1) / 9.0, 0.0, 1.0)
	var u := clampf(float(lv - 10) / 10.0, 0.0, 1.0)  # levels 11-20 keep getting faster
	var e := pow(t, 0.8)
	return {
		"think": lerpf(lerpf(1.5, 0.45, e), 0.12, u),    # see the piece + decide, after it appears (s)
		"key": lerpf(lerpf(0.55, 0.17, e), 0.085, u),    # time between two key taps (s)
		"das": lerpf(lerpf(0.30, 0.15, t), 0.11, u),     # hold a direction: delay before it auto-repeats (s)
		"arr": lerpf(lerpf(0.10, 0.05, t), 0.03, u),     # auto-repeat interval (s)
		"drop": lerpf(lerpf(0.25, 0.12, e), 0.05, u),    # pause to check the result before hard drop (s)
		"slip": lerpf(0.08, 0.004, e),                   # chance a finger hits the wrong key or count
		"blind": lerpf(0.4, 0.05, e),                    # chance a slip goes unnoticed
		"mistake": MISTAKE[clampi(lv - 1, 0, MAX_LEVEL - 1)],   # chance to pick a bad placement
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
			_make_plan(p["mistake"] * (1.0 + 1.5 * _panic()))
			_schedule(p)
		return
	plan_t += delta
	while not actions.is_empty() and actions[0][0] <= plan_t and alive and has_plan:
		var a: Array = actions.pop_front()
		match a[1]:
			"rot":
				presses += 1
				_rotate(a[2])
			"move":
				presses += 1
				_move(a[2])
			"drop":
				_finish(p)


## 0..1: how messy / high the stack is. People think longer and slip more when it is.
func _panic() -> float:
	return clampf((_max_height(board) - 10) / 8.0, 0.0, 1.0)


## Plans the key presses for the target: rotations (the shorter of cw / ccw), the shift (taps, or hold with
## DAS/ARR when that is faster), done in parallel like two fingers, then a short check and the hard drop.
func _schedule(p: Dictionary, extra := 0.0, slip := true) -> void:
	actions.clear()
	plan_t = 0.0
	exec_rot = plan_rot
	exec_x = plan_x
	if slip and rng.randf() < p["slip"] * (1.0 + _panic()):
		if rng.randf() < 0.5:
			exec_x = clampi(plan_x + (1 if rng.randf() < 0.5 else -1), -2, COLS)
		else:
			exec_rot = (plan_rot + (1 if rng.randf() < 0.5 else 3)) % 4
	var t0 := INPUT_LAG + extra + rng.randf_range(0.0, 0.04)
	var n_rot := (exec_rot - rot + 4) % 4
	var rot_dir := -1 if n_rot == 3 else 1
	var rot_end := t0
	var tt := t0
	for i in (1 if n_rot == 3 else n_rot):
		actions.append([tt, "rot", rot_dir])
		rot_end = tt
		tt += float(p["key"]) * rng.randf_range(0.8, 1.25)
	var dx := exec_x - pos.x
	var dist := absi(dx)
	var move_end := t0
	if dist > 0:
		var m0: float = t0 + (p["key"] * 0.3 if n_rot > 0 else 0.0)  # the rotation key goes first
		var tap_end: float = m0 + p["key"] * 1.1 * (dist - 1)
		var hold_end: float = m0 + p["das"] + p["arr"] * (dist - 2)
		var times: Array = [m0]
		if dist > 2 and hold_end < tap_end:
			for i in range(1, dist):
				times.append(m0 + p["das"] + p["arr"] * (i - 1))
		else:
			for i in range(1, dist):
				times.append(times[i - 1] + p["key"] * rng.randf_range(0.8, 1.25))
		for x in times:
			actions.append([x, "move", signi(dx)])
		move_end = times[-1]
	actions.append([maxf(rot_end, move_end) + p["drop"] * rng.randf_range(0.7, 1.3), "drop", 0])
	actions.sort_custom(func(a, b): return a[0] < b[0])
	has_plan = true


## Before the hard drop: a person looks at the piece. Wrong place and noticed -> a short pause, then fix it.
func _finish(p: Dictionary) -> void:
	if (rot != plan_rot or pos.x != plan_x) and fixes < 2 and rng.randf() >= p["blind"]:
		fixes += 1
		_schedule(p, rng.randf_range(0.12, 0.25), false)
		return
	_hard_drop()


func _collides(k: int, r: int, p: Vector2i, bd: Array = []) -> bool:
	var b: Array = board if bd.is_empty() else bd
	for c in Pieces.cells(k, r):
		var x: int = p.x + c.x
		var y: int = p.y + c.y
		if x < 0 or x >= COLS or y >= ROWS:
			return true
		if y >= 0 and b[y][x] != -1:
			return true
	return false


func _move(dx: int) -> bool:
	if _collides(kind, rot, pos + Vector2i(dx, 0)):
		return false
	pos.x += dx
	_on_moved()
	return true


func _rotate(dir := 1) -> bool:
	var new_rot := (rot + dir + 4) % 4
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
	actions.clear()
	fixes = 0
	# deciding takes longer on a messy stack; everyone varies from piece to piece
	think_timer = params(level)["think"] * rng.randf_range(0.8, 1.3) * (1.0 + 0.5 * _panic())
	if _collides(kind, rot, pos):
		alive = false


func _lock() -> void:
	placed += 1
	for c in Pieces.cells(kind, rot):
		var p: Vector2i = pos + c
		if p.y >= 0:
			board[p.y][p.x] = kind
	var cleared := 0
	var y := ROWS - 1
	while y >= 0:
		if not board[y].has(-1):
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
		var ok := Characters.apply(sid, board)  # first: the lightning picks its side here
		on_special.call(sid)
		if not ok:
			alive = false
			special_in.clear()
			return

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

func _placements(k: int, bd: Array) -> Array:
	var out: Array = []
	for r in (1 if k == 1 else 4):
		var minx := 99
		var maxx := -99
		for c in Pieces.cells(k, r):
			minx = mini(minx, c.x)
			maxx = maxi(maxx, c.x)
		for x in range(-minx, COLS - maxx):
			var p := Vector2i(x, -1)
			if _collides(k, r, p, bd):
				continue
			while not _collides(k, r, p + Vector2i(0, 1), bd):
				p.y += 1
			out.append([r, x, p])
	return out


func _make_plan(mistake: float) -> void:
	var cands: Array = []
	for pl in _placements(kind, board):
		var ev := _eval_on(board, kind, pl[0], pl[2])
		var in_well := false
		for c in Pieces.cells(kind, pl[0]):
			if pl[2].x + c.x == COLS - 1:
				in_well = true
		cands.append([ev[0], pl[0], pl[1], ev[1], in_well, ev[2]])
	if aim and want.get(4, 0) > 0 and _max_height(board) < 11:
		# quad stacking: the last column stays an open well; only an I piece that clears four goes in
		var keep: Array = []
		for c in cands:
			if not c[4] or (kind == 0 and c[5] == 4):
				keep.append(c)
		if not keep.is_empty():
			cands = keep
	if level >= LOOKAHEAD_FROM and not queue.is_empty() and cands.size() > 1:
		# two-piece lookahead on the best few placements: add the best score of the next piece
		cands.sort_custom(func(a, b): return a[0] > b[0])
		var top := mini(6, cands.size())
		var lowest := 1e9
		for i in top:
			var best := -1e9
			for pl in _placements(queue[0], cands[i][3]):
				best = maxf(best, _eval_on(cands[i][3], queue[0], pl[0], pl[2])[0])
			if best <= -1e9:
				best = -100.0  # no room for the next piece
			cands[i][0] += best
			lowest = minf(lowest, best)
		for i in range(top, cands.size()):
			cands[i][0] += lowest - 1.0  # not looked at: keep them below the examined ones
	if cands.is_empty():
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


## Heuristic: low stack, few holes, flat surface, clear lines. Returns [score, board after the move].
func _eval_on(bd: Array, k: int, r: int, p: Vector2i) -> Array:
	var tb: Array = []
	for row in bd:
		tb.append(row.duplicate())
	for c in Pieces.cells(k, r):
		var q: Vector2i = p + c
		if q.y >= 0:
			tb[q.y][q.x] = k
	var cleared := 0
	var y := ROWS - 1
	while y >= 0:
		if not tb[y].has(-1):
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
	if aim and not want.is_empty():
		score += _aim_bonus(cleared, maxh)
	return [score, tb, cleared]


## Pulls the placement choice toward the clears the special attack needs.
func _aim_bonus(cleared: int, maxh: int) -> float:
	if cleared == 0:
		return 0.0
	if want.get(cleared, 0) > 0:
		return 1.4 + 0.5 * cleared
	# a clear that does not help: skip it while the stack is low
	return -(0.76 * cleared + 0.2 * cleared * cleared + 0.8) if maxh < 12 else 0.0


func _max_height(bd: Array) -> int:
	for y in ROWS:
		for v in bd[y]:
			if v != -1:
				return ROWS - y
	return 0
