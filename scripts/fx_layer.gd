extends Control
## Plays pixel-art strip animations (8 frames of 192 px) anywhere on screen, nearest-neighbour filtered.

const Characters := preload("res://scripts/characters.gd")

var items: Array = []


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Plays `tex` (a strip) once, or looping, into `rect`.
func play(tex: Texture2D, rect: Rect2, fps: float = 14.0, loop: bool = false) -> void:
	items.append({"tex": tex, "rect": rect, "t": 0.0, "fps": fps, "loop": loop})


func clear() -> void:
	items.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if items.is_empty():
		return
	for it in items:
		it["t"] += delta
	items = items.filter(func(it): return it["loop"] or it["t"] * it["fps"] < Characters.FX_FRAMES)
	queue_redraw()  # also once after the last item ended, to wipe it


func _draw() -> void:
	for it in items:
		var f: int = int(it["t"] * it["fps"]) % Characters.FX_FRAMES
		draw_texture_rect_region(it["tex"], it["rect"], Rect2(f * Characters.FX_CELL, 0, Characters.FX_CELL, Characters.FX_CELL))
