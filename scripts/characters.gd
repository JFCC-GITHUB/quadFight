extends RefCounted
## VS-mode characters: art, special-attack recipe and the board operations of each special attack.
## A recipe is a set of line-clear sizes ("1 line x3", "1 + 2 + 1"); clears add up over time, in any order.

const COLS := 10
const ROWS := 20
const GARBAGE := 7  # board value of a garbage block

const LIST := [
	{"id": "bastion", "name": "BASTION", "color": "4ab0ff", "need": {1: 2, 3: 1}, "skill": "IRON WALL",
		"desc": "A heavy wall falls and scatters like sand over the stack."},
	{"id": "blaze", "name": "BLAZE", "color": "ff7a2a", "need": {1: 3}, "skill": "FIRE RAIN",
		"desc": "10 single blocks pour onto random columns."},
	{"id": "frost", "name": "FROST", "color": "58c8f8", "need": {2: 2}, "skill": "ICE SPIKES",
		"desc": "4-high pillars grow on the two lowest columns."},
	{"id": "volt", "name": "VOLT", "color": "ffc21a", "need": {1: 1, 2: 1, 3: 1}, "skill": "LIGHTNING",
		"desc": "Two 6-block lightning bolts strike, left and right."},
	{"id": "shade", "name": "SHADE", "color": "c040ff", "need": {1: 1, 2: 2}, "skill": "CHECKERS",
		"desc": "2 hole-punched checkerboard rows rise from below."},
	{"id": "titan", "name": "TITAN", "color": "a8e83a", "need": {4: 1}, "skill": "BOULDER",
		"desc": "A 3x3 boulder slams down in the middle."},
]

const PORTRAITS := {
	"bastion": preload("res://assets/chars/bastion.png"), "blaze": preload("res://assets/chars/blaze.png"),
	"frost": preload("res://assets/chars/frost.png"), "volt": preload("res://assets/chars/volt.png"),
	"shade": preload("res://assets/chars/shade.png"), "titan": preload("res://assets/chars/titan.png"),
}
const FX_CAST := {
	"bastion": preload("res://assets/fx/bastion_cast.png"), "blaze": preload("res://assets/fx/blaze_cast.png"),
	"frost": preload("res://assets/fx/frost_cast.png"), "volt": preload("res://assets/fx/volt_cast.png"),
	"shade": preload("res://assets/fx/shade_cast.png"), "titan": preload("res://assets/fx/titan_cast.png"),
}
const FX_HIT := {
	"bastion": preload("res://assets/fx/bastion_hit.png"), "blaze": preload("res://assets/fx/blaze_hit.png"),
	"frost": preload("res://assets/fx/frost_hit.png"), "volt": preload("res://assets/fx/volt_hit.png"),
	"shade": preload("res://assets/fx/shade_hit.png"), "titan": preload("res://assets/fx/titan_hit.png"),
}
const FX_FRAMES := 8
const FX_CELL := 192  # px of one animation frame in a strip


static func def(id: String) -> Dictionary:
	for d in LIST:
		if d["id"] == id:
			return d
	return LIST[0]


static func random_other(id: String) -> String:
	var ids: Array = []
	for d in LIST:
		if d["id"] != id:
			ids.append(d["id"])
	return ids[randi() % ids.size()]


## Flat list of the line counts a recipe needs, e.g. {1: 2, 2: 1} -> [1, 1, 2].
static func pips(id: String) -> Array:
	var out: Array = []
	var need: Dictionary = def(id)["need"]
	for n in [1, 2, 3, 4]:
		for i in need.get(n, 0):
			out.append(n)
	return out


## Adds one clear of `n` lines to `have`; true once the whole recipe is satisfied (then `have` is reset).
static func add_clear(id: String, have: Dictionary, n: int) -> bool:
	var need: Dictionary = def(id)["need"]
	if need.has(n):
		have[n] = mini(have.get(n, 0) + 1, need[n])
	for k in need:
		if have.get(k, 0) < need[k]:
			return false
	have.clear()
	return true


## Fraction of the recipe collected, 0..1.
static func progress(id: String, have: Dictionary) -> float:
	var got := 0
	var total := 0
	var need: Dictionary = def(id)["need"]
	for k in need:
		total += need[k]
		got += mini(have.get(k, 0), need[k])
	return float(got) / float(maxi(total, 1))


# ---------------------------------------------------------------- board operations (board[y][x], -1 = empty)

## Applies character `id`'s special attack to `board`. Returns false when the board overflowed (that side loses).
static func apply(id: String, board: Array) -> bool:
	match id:
		"bastion":
			return _sand(board, 30)
		"blaze":
			return _rain(board, 10)
		"frost":
			return _pillars(board)
		"volt":
			var bolt := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
			return _drop(board, bolt, 1) and _drop(board, bolt, 6)
		"shade":
			var a: Array = []
			var b: Array = []
			for x in COLS:
				a.append(GARBAGE if x % 2 == 0 else -1)
				b.append(-1 if x % 2 == 0 else GARBAGE)
			return _push(board, [a, b])
		"titan":
			var cells: Array = []
			for yy in 3:
				for xx in 3:
					cells.append(Vector2i(xx, yy))
			return _drop(board, cells, 4)
	return true


## Pours `n` grains over the stack, one column at a time; each slides down to a lower neighbour (like sand).
static func _sand(board: Array, n: int) -> bool:
	for i in n:
		var x := i % COLS
		for step in COLS * 4:
			var here := _top(board, x)
			var left := _top(board, x - 1) if x > 0 else -99
			var right := _top(board, x + 1) if x < COLS - 1 else -99
			# a neighbour whose surface is 2+ cells lower (top index larger) takes the grain
			if left >= here + 2 and left >= right:
				x -= 1
			elif right >= here + 2:
				x += 1
			else:
				break
		var y := _top(board, x) - 1
		if y < 0:
			return false
		board[y][x] = GARBAGE
	return true


## Pushes whole rows in from the bottom; false if existing blocks were pushed off the top.
static func _push(board: Array, rows: Array) -> bool:
	var ok := true
	for y in rows.size():
		for v in board[y]:
			if v != -1:
				ok = false
	for r in rows:
		board.remove_at(0)
		board.append(r.duplicate())
	return ok


static func _top(board: Array, x: int) -> int:
	for y in ROWS:
		if board[y][x] != -1:
			return y
	return ROWS


static func _rain(board: Array, n: int) -> bool:
	for i in n:
		var x := randi_range(0, COLS - 1)
		var t := _top(board, x)
		if t - 1 < 0:
			return false
		board[t - 1][x] = GARBAGE
	return true


static func _pillars(board: Array) -> bool:
	var cols: Array = range(COLS)
	cols.shuffle()  # random tie-break between equally low columns
	cols.sort_custom(func(a, b): return _top(board, a) > _top(board, b))
	for x in cols.slice(0, 2):
		var t := _top(board, x)
		for k in 4:
			if t - 1 - k < 0:
				return false
			board[t - 1 - k][x] = GARBAGE
	return true


## Lets a shape fall from above the board at column `x0` until it rests; false if it sticks out of the top.
static func _drop(board: Array, cells: Array, x0: int) -> bool:
	var h := 0
	for c in cells:
		h = maxi(h, c.y + 1)
	var dy := -h
	while true:
		var free := true
		for c in cells:
			var y: int = dy + 1 + c.y
			if y >= ROWS or (y >= 0 and board[y][x0 + c.x] != -1):
				free = false
				break
		if not free:
			break
		dy += 1
	for c in cells:
		var y: int = dy + c.y
		if y < 0:
			return false
		board[y][x0 + c.x] = GARBAGE
	return true
