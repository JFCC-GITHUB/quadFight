extends Control

const UI := preload("res://scripts/ui.gd")
const Pieces := preload("res://scripts/pieces.gd")

var main: Node


func _ready() -> void:
	UI.button(self, "START", Rect2(120, 520, 300, 90), func(): main.show_game(), 38, Color("2f9e55"))
	UI.button(self, "LEADERBOARD", Rect2(120, 630, 300, 76), func(): main.show_leaderboard(), 28)
	var best := "BEST  %d" % Scores.best() if Scores.best() > 0 else "No score yet - play!"
	UI.label(self, best, Rect2(0, 440, 540, 50), 28, Color("ffd400"))
	UI.label(self, "Keyboard: arrows move/rotate, Space drop, C hold, P pause\nGamepad: D-pad + A/B/X, Start = pause\nTouch: on-screen buttons",
		Rect2(20, 800, 500, 110), 16, Color("8a93b8"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		main.show_game()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1020"))
	# Decorative row of tetrominoes.
	for kind in 7:
		var origin := Vector2(24 + kind * 72, 130 + (kind % 2) * 36)
		for c in Pieces.cells(kind, 0):
			var r := Rect2(origin + Vector2(c) * 16, Vector2(15, 15))
			draw_rect(r, Pieces.COLORS[kind])
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 330), "TETRIS", HORIZONTAL_ALIGNMENT_CENTER, 540, 84, Color.WHITE)
	draw_string(font, Vector2(0, 410), "FIGHT", HORIZONTAL_ALIGNMENT_CENTER, 540, 84, Color("ff5a5a"))
