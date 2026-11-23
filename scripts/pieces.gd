extends RefCounted
## Tetromino data (SRS). Kinds: 0=I 1=O 2=T 3=S 4=Z 5=J 6=L

const BASE := [
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
]
const BOX := [4, 4, 3, 3, 3, 3, 3]
const COLORS := [
	Color("33e1ff"), Color("ffd23f"), Color("b45cff"), Color("4be37a"),
	Color("ff4d6d"), Color("4d7dff"), Color("ff9a3c"),
]

# SRS wall kicks, y-up convention (flipped to y-down in kicks()).
const KICKS_JLSTZ := {
	"0>1": [[0, 0], [-1, 0], [-1, 1], [0, -2], [-1, -2]],
	"1>0": [[0, 0], [1, 0], [1, -1], [0, 2], [1, 2]],
	"1>2": [[0, 0], [1, 0], [1, -1], [0, 2], [1, 2]],
	"2>1": [[0, 0], [-1, 0], [-1, 1], [0, -2], [-1, -2]],
	"2>3": [[0, 0], [1, 0], [1, 1], [0, -2], [1, -2]],
	"3>2": [[0, 0], [-1, 0], [-1, -1], [0, 2], [-1, 2]],
	"3>0": [[0, 0], [-1, 0], [-1, -1], [0, 2], [-1, 2]],
	"0>3": [[0, 0], [1, 0], [1, 1], [0, -2], [1, -2]],
}
const KICKS_I := {
	"0>1": [[0, 0], [-2, 0], [1, 0], [-2, -1], [1, 2]],
	"1>0": [[0, 0], [2, 0], [-1, 0], [2, 1], [-1, -2]],
	"1>2": [[0, 0], [-1, 0], [2, 0], [-1, 2], [2, -1]],
	"2>1": [[0, 0], [1, 0], [-2, 0], [1, -2], [-2, 1]],
	"2>3": [[0, 0], [2, 0], [-1, 0], [2, 1], [-1, -2]],
	"3>2": [[0, 0], [-2, 0], [1, 0], [-2, -1], [1, 2]],
	"3>0": [[0, 0], [1, 0], [-2, 0], [1, -2], [-2, 1]],
	"0>3": [[0, 0], [-1, 0], [2, 0], [-1, 2], [2, -1]],
}


static func cells(kind: int, rot: int) -> Array:
	var out: Array = BASE[kind].duplicate()
	if kind == 1:
		return out
	var n: int = BOX[kind]
	for _i in range(rot % 4):
		var next: Array = []
		for c in out:
			next.append(Vector2i(n - 1 - c.y, c.x))
		out = next
	return out


static func kicks(kind: int, from_rot: int, to_rot: int) -> Array:
	if kind == 1:
		return [Vector2i.ZERO]
	var table: Dictionary = KICKS_I if kind == 0 else KICKS_JLSTZ
	var out: Array = []
	for k in table["%d>%d" % [from_rot, to_rot]]:
		out.append(Vector2i(k[0], -k[1]))
	return out
