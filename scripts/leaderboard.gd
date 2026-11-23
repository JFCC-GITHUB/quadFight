extends Control

const UI := preload("res://scripts/ui.gd")

var main: Node


func _ready() -> void:
	UI.label(self, "LEADERBOARD", Rect2(0, 40, 540, 70), 44, Color("ffd400"))
	UI.label(self, "#", Rect2(20, 130, 50, 30), 18, Color("8a93b8"))
	UI.label(self, "SCORE", Rect2(70, 130, 150, 30), 18, Color("8a93b8"), HORIZONTAL_ALIGNMENT_LEFT)
	UI.label(self, "LINES", Rect2(240, 130, 80, 30), 18, Color("8a93b8"))
	UI.label(self, "LV", Rect2(320, 130, 60, 30), 18, Color("8a93b8"))
	UI.label(self, "DATE", Rect2(390, 130, 130, 30), 18, Color("8a93b8"))
	if Scores.entries.is_empty():
		UI.label(self, "No scores yet.\nGo play a game!", Rect2(0, 330, 540, 120), 28, Color("8a93b8"))
	for i in Scores.entries.size():
		var e: Dictionary = Scores.entries[i]
		var y := 170 + i * 56
		var col := Color("ffd400") if i == 0 else Color.WHITE
		UI.label(self, str(i + 1), Rect2(20, y, 50, 50), 26, col)
		UI.label(self, str(e["score"]), Rect2(70, y, 170, 50), 28, col, HORIZONTAL_ALIGNMENT_LEFT)
		UI.label(self, str(e["lines"]), Rect2(240, y, 80, 50), 24, col)
		UI.label(self, str(e["level"]), Rect2(320, y, 60, 50), 24, col)
		UI.label(self, str(e["date"]), Rect2(390, y, 130, 50), 18, Color("8a93b8"))
	UI.button(self, "BACK", Rect2(150, 800, 240, 80), func(): main.show_title(), 30)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("confirm"):
		main.show_title()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1020"))
