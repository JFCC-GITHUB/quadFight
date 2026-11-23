extends RefCounted
## On-screen button layouts. Two clusters (left / right) can be swapped for the other hand.

const Style := preload("res://scripts/style.gd")

const SWAP_SHIFT := 264.0
const LAYOUTS := ["classic", "thumbs"]


## Returns [{name, icon, rect, held, scheme}] for the given layout.
static func buttons(layout: String, swap_sides: bool) -> Array:
	var g := Style.BTN_GLASS
	var list: Array
	# "left" cluster = x 12..264, "right" cluster = x 276..528 (before swapping).
	if layout == "thumbs":
		list = [
			_b("move_left", "left", 12, 732, 122, 100, true, g, 0),
			_b("move_right", "right", 142, 732, 122, 100, true, g, 0),
			_b("soft_drop", "down", 12, 842, 252, 100, true, g, 0),
			_b("rotate_ccw", "rotate_ccw", 276, 732, 122, 100, false, Style.BTN_ACCENT, 1),
			_b("rotate_cw", "rotate", 406, 732, 122, 100, false, Style.BTN_ACCENT, 1),
			_b("hold", "hold", 276, 842, 122, 100, false, g, 1),
			_b("hard_drop", "drop", 406, 842, 122, 100, false, Style.BTN_PRIMARY, 1),
		]
	else:
		list = [
			_b("move_left", "left", 12, 732, 122, 100, true, g, 0),
			_b("move_right", "right", 142, 732, 122, 100, true, g, 0),
			_b("soft_drop", "down", 12, 842, 252, 100, true, g, 0),
			_b("hold", "hold", 276, 732, 122, 100, false, g, 1),
			_b("rotate_cw", "rotate", 406, 732, 122, 100, false, Style.BTN_ACCENT, 1),
			_b("hard_drop", "drop", 276, 842, 252, 100, false, Style.BTN_PRIMARY, 1),
		]
	if swap_sides:
		for b in list:
			var shift := SWAP_SHIFT if b["cluster"] == 0 else -SWAP_SHIFT
			b["rect"].position.x += shift
	return list


static func _b(name: String, icon: String, x: float, y: float, w: float, h: float,
		held: bool, scheme: Array, cluster: int) -> Dictionary:
	return {"name": name, "icon": icon, "rect": Rect2(x, y, w, h), "held": held,
		"scheme": scheme, "cluster": cluster}
