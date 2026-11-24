extends Control
## Draws a character's pixel-art portrait with nearest-neighbour filtering (keeps the pixels crisp).
## `crop` (in 0..1 of the image) shows only part of it, e.g. the head.

const Characters := preload("res://scripts/characters.gd")

var char_id := "bastion"
var crop := Rect2(0, 0, 1, 1)
var dim := 1.0
var flip_h := false


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_char(id: String) -> void:
	char_id = id
	queue_redraw()


func _draw() -> void:
	var tex: Texture2D = Characters.PORTRAITS[char_id]
	var s := tex.get_size()
	if flip_h:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect_region(tex, Rect2(Vector2.ZERO, size), Rect2(crop.position * s, crop.size * s), Color(dim, dim, dim, 1))
