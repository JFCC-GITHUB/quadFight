extends RefCounted
## On-screen button layouts. Two clusters (left / right) can be swapped for the other hand.

const Style := preload("res://scripts/style.gd")

const SWAP_SHIFT := 264.0
const LAYOUTS := ["snes", "classic", "thumbs"]


## Returns [{name, icon, rect, held, scheme}] for the given layout.
static func buttons(layout: String, swap_sides: bool) -> Array:
	var g := Style.BTN_GLASS
	var list: Array
	# "left" cluster = x 12..264, "right" cluster = x 276..528 (before swapping).
	if layout == "snes":
		# Gamepad: D-pad (left/right/down) on the left, A/B/X/Y diamond on the right.
		var d := Style.BTN_DPAD
		list = [
			_b("hard_drop", "drop", 103, 733, 70, 70, false, d, 0, 14),
			_b("move_left", "left", 33, 803, 105, 70, true, d, 0, 14),
			_b("move_right", "right", 138, 803, 105, 70, true, d, 0, 14),
			_b("soft_drop", "down", 103, 873, 70, 70, true, d, 0, 14),
			_b("hard_drop", "drop", 360, 732, 84, 84, false, Style.BTN_SNES_X, 1, 42),
			_b("hold", "hold", 276, 796, 84, 84, false, Style.BTN_SNES_Y, 1, 42),
			_b("rotate_ccw", "rotate_ccw", 444, 796, 84, 84, false, Style.BTN_SNES_A, 1, 42),
			_b("rotate_cw", "rotate", 360, 860, 84, 84, false, Style.BTN_SNES_B, 1, 42),
		]
	elif layout == "thumbs":
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
	if layout == "snes":
		var pad := Rect2()
		for i in 4:
			pad = list[i]["rect"] if i == 0 else pad.merge(list[i]["rect"])
		for i in 4:
			list[i]["pad_center"] = pad.get_center()
	return list


static func _b(name: String, icon: String, x: float, y: float, w: float, h: float,
		held: bool, scheme: Array, cluster: int, radius: int = 20) -> Dictionary:
	return {"name": name, "icon": icon, "rect": Rect2(x, y, w, h), "held": held,
		"scheme": scheme, "cluster": cluster, "radius": radius}
