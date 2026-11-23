extends Control

const UI := preload("res://scripts/ui.gd")
const Pieces := preload("res://scripts/pieces.gd")

var main: Node
var falling: Array = []
var time := 0.0


func _ready() -> void:
	for i in 14:
		falling.append(_new_piece(randf_range(-100, 960)))
	var best := "BEST  %d" % Scores.best() if Scores.best() > 0 else "No score yet - play!"
	UI.label(self, best, Rect2(0, 440, 540, 50), 28, Color("ffd400"))
	UI.button(self, "START", Rect2(120, 520, 300, 90), func(): main.show_game(), 38, Color("2f9e55"))
	UI.button(self, "LEADERBOARD", Rect2(120, 630, 300, 76), func(): main.show_leaderboard(), 28)
	UI.audio_toggles(self, 725)
	UI.label(self, "Keyboard: arrows move/rotate, Space drop, C hold, P pause\nGamepad: D-pad + A/B/X, Start = pause\nTouch: on-screen buttons",
		Rect2(20, 820, 500, 100), 16, Color("8a93b8"))


func _new_piece(y: float) -> Dictionary:
	return {
		"kind": randi() % 7, "rot": randi() % 4,
		"x": randf_range(-20, 500), "y": y,
		"speed": randf_range(30, 90), "scale": randf_range(14, 26),
	}


func _process(delta: float) -> void:
	time += delta
	for p in falling:
		p["y"] += p["speed"] * delta
		if p["y"] > 980:
			p.merge(_new_piece(-100), true)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		main.show_game()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1020"))
	for p in falling:
		var s: float = p["scale"]
		var col: Color = Pieces.COLORS[p["kind"]]
		col.a = 0.22
		for c in Pieces.cells(p["kind"], p["rot"]):
			draw_rect(Rect2(Vector2(p["x"], p["y"]) + Vector2(c) * s, Vector2(s - 2, s - 2)), col)
	var font := ThemeDB.fallback_font
	var bob := sin(time * 2.0) * 5.0
	draw_string(font, Vector2(0, 250 + bob), "TETRIS", HORIZONTAL_ALIGNMENT_CENTER, 540, 84, Color.WHITE)
	draw_string(font, Vector2(0, 335 - bob), "FIGHT", HORIZONTAL_ALIGNMENT_CENTER, 540, 84, Color("ff5a5a"))
