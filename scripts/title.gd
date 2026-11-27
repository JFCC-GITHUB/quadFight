extends Control

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Pieces := preload("res://scripts/pieces.gd")
const OptionsScreen := preload("res://scripts/options.gd")
const Fullscreen := preload("res://scripts/fullscreen.gd")

var main: Node
var falling: Array = []
var time := 0.0
var options_open := false
var land := false  # 960x540 layout: logo on the left, buttons on the right


func _ready() -> void:
	for i in 12:
		falling.append(_new_piece(randf_range(-120, size.y)))
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	var x := 560.0 if land else 110.0
	var ys := [30.0, 114.0, 186.0, 258.0, 334.0, 396.0] if land else [470.0, 560.0, 634.0, 708.0, 790.0, 856.0]
	UI.button(self, "PLAY", Rect2(x, ys[0], 320, 76), func(): main.show_game(), 36, Style.BTN_PRIMARY, "play")
	UI.button(self, "LADDER", Rect2(x, ys[1], 320, 64), func(): main.show_vs_select("ladder"), 28, Style.BTN_ACCENT, "up")
	UI.button(self, "TOURNAMENT", Rect2(x, ys[2], 320, 64), func(): main.show_vs_select("tournament"), 26, Style.BTN_ACCENT,
		"swords")
	if Settings.two_player_ok():  # practice and 2 players share the row
		UI.button(self, "PRACTICE", Rect2(x, ys[3], 156, 64), func(): main.show_vs_select("practice"), 20, Style.BTN_ACCENT, "play")
		UI.button(self, "2 PLAYERS", Rect2(x + 164, ys[3], 156, 64), func(): main.show_char_select(3, "versus", 0), 20,
			Style.BTN_ACCENT, "swords")
	else:
		UI.button(self, "PRACTICE", Rect2(x, ys[3], 320, 64), func(): main.show_vs_select("practice"), 26, Style.BTN_ACCENT, "play")
	UI.button(self, "RANKING", Rect2(x, ys[4], 320, 56), func(): main.show_leaderboard(), 24, Style.BTN_GLASS, "trophy")
	UI.button(self, "OPTIONS", Rect2(x, ys[5], 320, 56), _open_options, 24, Style.BTN_GLASS, "gear")
	UI.icon_button(self, "fullscreen", Rect2(size.x - 68, 16, 52, 52), func(): Fullscreen.toggle(self), Style.BTN_GLASS)


## Called by Main when the window is rotated.
func relayout() -> void:
	if not options_open:
		_build()


func _new_piece(y: float) -> Dictionary:
	return {
		"kind": randi() % 7, "rot": randi() % 4,
		"x": randf_range(-30, size.x - 40.0), "y": y,
		"speed": randf_range(25, 70), "cell": randf_range(16, 30),
		"spin": randf_range(-0.3, 0.3), "angle": randf() * TAU,
	}


func _process(delta: float) -> void:
	time += delta
	for p in falling:
		p["y"] += p["speed"] * delta
		p["angle"] += p["spin"] * delta
		if p["y"] > size.y + 40.0:
			p.merge(_new_piece(-120), true)
	queue_redraw()


func _open_options() -> void:
	options_open = true
	var o := OptionsScreen.new()
	o.on_close = func(): options_open = false
	o.on_secret = func(): main.show_bonus(true)
	if land:  # the options screen is a 540x960 portrait page: fit it to the height
		var sc := size.y / 960.0
		o.scale = Vector2(sc, sc)
		o.position = Vector2((size.x - 540.0 * sc) * 0.5, 0)
	add_child(o)


func _unhandled_input(event: InputEvent) -> void:
	if options_open:
		return
	if event.is_action_pressed("confirm"):
		main.show_game()


func _draw() -> void:
	Style.draw_bg(self, size)
	for p in falling:
		var cell: float = p["cell"]
		var center := Vector2(p["x"], p["y"])
		draw_set_transform(center, p["angle"])
		var cells := Pieces.cells(p["kind"], p["rot"])
		for c in cells:
			Style.draw_block(self, p["kind"], Rect2(Vector2(c) * cell - Vector2(cell, cell) * 1.5, Vector2(cell, cell)), 0.28)
	draw_set_transform(Vector2.ZERO)

	# Logo
	var logo_w := 400.0 if land else 490.0
	var logo_h: float = logo_w * Style.LOGO.get_height() / Style.LOGO.get_width()
	var bob := sin(time * 1.8) * 6.0
	var cx := 280.0 if land else size.x * 0.5
	draw_texture_rect(Style.LOGO, Rect2(cx - logo_w * 0.5, (64 if land else 120) + bob, logo_w, logo_h), false)

	# Best score pill
	var pill := Rect2(cx - 120.0, 336 if land else 396, 240, 50)
	draw_style_box(Style.panel_box(Color(0, 0, 0, 0.35), 27, Color(1, 0.83, 0.3, 0.35)), pill)
	Style.draw_icon(self, "trophy", pill.position + Vector2(34, 27), 26, Style.GOLD)
	var best := Scores.best()
	Style.text(self, Style.caption_font(), pill.position + Vector2(56, 34), "BEST", 18, Style.MUTED)
	Style.text(self, Style.FONT_DISPLAY, pill.position + Vector2(0, 38), str(best) if best > 0 else "-",
		26, Style.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, pill.size.x - 24)

