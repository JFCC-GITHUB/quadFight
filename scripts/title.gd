extends Control

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Pieces := preload("res://scripts/pieces.gd")

var main: Node
var falling: Array = []
var time := 0.0


func _ready() -> void:
	for i in 12:
		falling.append(_new_piece(randf_range(-120, 960)))
	UI.button(self, "PLAY", Rect2(110, 530, 320, 100), func(): main.show_game(), 40,
		Style.BTN_PRIMARY, "play")
	UI.button(self, "RANKING", Rect2(110, 652, 320, 80), func(): main.show_leaderboard(), 28,
		Style.BTN_GLASS, "trophy")
	UI.audio_toggles(self, 270, 762)


func _new_piece(y: float) -> Dictionary:
	return {
		"kind": randi() % 7, "rot": randi() % 4,
		"x": randf_range(-30, 500), "y": y,
		"speed": randf_range(25, 70), "cell": randf_range(16, 30),
		"spin": randf_range(-0.3, 0.3), "angle": randf() * TAU,
	}


func _process(delta: float) -> void:
	time += delta
	for p in falling:
		p["y"] += p["speed"] * delta
		p["angle"] += p["spin"] * delta
		if p["y"] > 1000:
			p.merge(_new_piece(-120), true)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		main.show_game()


func _draw() -> void:
	draw_texture_rect(Style.BG, Rect2(Vector2.ZERO, size), false)
	for p in falling:
		var cell: float = p["cell"]
		var center := Vector2(p["x"], p["y"])
		draw_set_transform(center, p["angle"])
		var cells := Pieces.cells(p["kind"], p["rot"])
		for c in cells:
			Style.draw_block(self, p["kind"], Rect2(Vector2(c) * cell - Vector2(cell, cell) * 1.5, Vector2(cell, cell)), 0.28)
	draw_set_transform(Vector2.ZERO)

	# Logo
	var logo_w := 490.0
	var logo_h: float = logo_w * Style.LOGO.get_height() / Style.LOGO.get_width()
	var bob := sin(time * 1.8) * 6.0
	draw_texture_rect(Style.LOGO, Rect2((size.x - logo_w) * 0.5, 150 + bob, logo_w, logo_h), false)

	# Best score pill
	var pill := Rect2(150, 446, 240, 54)
	draw_style_box(Style.panel_box(Color(0, 0, 0, 0.35), 27, Color(1, 0.83, 0.3, 0.35)), pill)
	Style.draw_icon(self, "trophy", pill.position + Vector2(34, 27), 26, Style.GOLD)
	var best := Scores.best()
	Style.text(self, Style.caption_font(), pill.position + Vector2(56, 34), "BEST", 18, Style.MUTED)
	Style.text(self, Style.FONT_DISPLAY, pill.position + Vector2(0, 38), str(best) if best > 0 else "-",
		26, Style.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, pill.size.x - 24)

	# Controls hint
	var f := Style.FONT_SEMI
	var y := 868.0
	for line in ["Keyboard   Arrows · Space drop · C hold · P pause",
			"Gamepad   D-pad · A / B rotate · X hold · Start",
			"Touch   on-screen buttons"]:
		Style.text(self, f, Vector2(0, y), line, 17, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		y += 26
