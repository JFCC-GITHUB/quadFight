extends RefCounted
## On-screen button layouts. Two clusters (left / right) can be swapped for the other hand.

const Style := preload("res://scripts/style.gd")

const SWAP_SHIFT := 264.0
const LAYOUTS := ["snes", "classic", "thumbs"]


## Returns [{name, icon, rect, held, scheme}] for the given layout.
static func buttons(layout: String, swap_sides: bool, landscape: bool = false) -> Array:
	var g := Style.BTN_GLASS
	var list: Array
	# "left" cluster = x 12..264, "right" cluster = x 276..528 (before swapping).
	if layout == "snes":
		# Gamepad: D-pad (left/right/down) on the left, A/B/X/Y diamond on the right.
		var d := Style.BTN_DPAD
		list = [
			_b("hard_drop", "drop", 78, 733, 70, 70, false, d, 0, 14),
			_b("move_left", "left", 8, 803, 105, 70, true, d, 0, 14),
			_b("move_right", "right", 113, 803, 105, 70, true, d, 0, 14),
			_b("soft_drop", "down", 78, 873, 70, 70, true, d, 0, 14),
			_b("hard_drop", "drop", 364, 732, 84, 84, false, Style.BTN_SNES_X, 1, 42),
			_b("hold", "hold", 280, 796, 84, 84, false, Style.BTN_SNES_Y, 1, 42),
			_b("rotate_ccw", "rotate_ccw", 448, 796, 84, 84, false, Style.BTN_SNES_A, 1, 42),
			_b("rotate_cw", "rotate", 364, 860, 84, 84, false, Style.BTN_SNES_B, 1, 42),
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
			if layout == "snes": # mirror each cluster to the other edge
				shift = 314.0 if b["cluster"] == 0 else -272.0
			b["rect"].position.x += shift
	if landscape:  # 960x540: clusters sit in the bottom corners (portrait coordinates are 540 wide, 960 tall)
		for b in list:
			b["rect"].position += Vector2(420.0 if b["rect"].get_center().x > 270.0 else 0.0, -414.0)
	if layout == "snes":
		var pad := Rect2()
		for i in 4:
			pad = list[i]["rect"] if i == 0 else pad.merge(list[i]["rect"])
		for i in 4:
			list[i]["pad_center"] = pad.get_center()
	return list


## 2 players on one tablet (960x540, screen coordinates): one compact set of buttons under each player's board.
## Player 2's button names are prefixed "p2:"; "half" keeps a touch from snapping to the other player's buttons.
static func two_player() -> Array:
	var list: Array = []
	for half in 2:
		var hx := 480.0 * half
		var pre := "p2:" if half == 1 else ""
		var row := [
			_b(pre + "move_left", "left", hx + 12, 414, 74, 122, true, Style.BTN_GLASS, 0, 16),
			_b(pre + "hold", "hold", hx + 92, 414, 74, 58, false, Style.BTN_GLASS, 0, 16),
			_b(pre + "soft_drop", "down", hx + 92, 478, 74, 58, true, Style.BTN_GLASS, 0, 16),
			_b(pre + "move_right", "right", hx + 172, 414, 74, 122, true, Style.BTN_GLASS, 0, 16),
			_b(pre + "rotate_ccw", "rotate_ccw", hx + 266, 414, 96, 58, false, Style.BTN_ACCENT, 1, 16),
			_b(pre + "rotate_cw", "rotate", hx + 368, 414, 100, 58, false, Style.BTN_ACCENT, 1, 16),
			_b(pre + "hard_drop", "drop", hx + 266, 478, 202, 58, false, Style.BTN_PRIMARY, 1, 16),
		]
		for b in row:
			b["half"] = half
		list.append_array(row)
	return list


static func _b(name: String, icon: String, x: float, y: float, w: float, h: float,
		held: bool, scheme: Array, cluster: int, radius: int = 20) -> Dictionary:
	return {"name": name, "icon": icon, "rect": Rect2(x, y, w, h), "held": held,
		"scheme": scheme, "cluster": cluster, "radius": radius}
