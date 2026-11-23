extends Control

const UI := preload("res://scripts/ui.gd")

var main: Node
var highlight := -1
var reset_armed := false
var reset_button: Button
var time := 0.0


func _ready() -> void:
	highlight = Scores.highlight
	Scores.highlight = -1
	var grey := Color("8a93b8")
	UI.label(self, "LEADERBOARD", Rect2(0, 40, 540, 70), 44, Color("ffd400"))
	UI.label(self, "#", Rect2(14, 130, 40, 30), 18, grey)
	UI.label(self, "NAME", Rect2(60, 130, 100, 30), 18, grey, HORIZONTAL_ALIGNMENT_LEFT)
	UI.label(self, "SCORE", Rect2(165, 130, 120, 30), 18, grey, HORIZONTAL_ALIGNMENT_LEFT)
	UI.label(self, "LINES", Rect2(290, 130, 70, 30), 18, grey)
	UI.label(self, "LV", Rect2(360, 130, 50, 30), 18, grey)
	UI.label(self, "DATE", Rect2(410, 130, 120, 30), 18, grey)
	if Scores.entries.is_empty():
		UI.label(self, "No scores yet.\nGo play a game!", Rect2(0, 330, 540, 120), 28, grey)
	var medals := [Color("ffd400"), Color("cfd8e8"), Color("e0925a")]
	for i in Scores.entries.size():
		var e: Dictionary = Scores.entries[i]
		var y := 170 + i * 56
		var col: Color = medals[i] if i < 3 else Color.WHITE
		UI.label(self, str(i + 1), Rect2(14, y, 40, 50), 26, col)
		UI.label(self, str(e["name"]), Rect2(60, y, 100, 50), 26, col, HORIZONTAL_ALIGNMENT_LEFT)
		UI.label(self, str(e["score"]), Rect2(165, y, 125, 50), 26, col, HORIZONTAL_ALIGNMENT_LEFT)
		UI.label(self, str(e["lines"]), Rect2(290, y, 70, 50), 22, col)
		UI.label(self, str(e["level"]), Rect2(360, y, 50, 50), 22, col)
		UI.label(self, str(e["date"]).substr(5), Rect2(410, y, 120, 50), 18, grey)
	UI.button(self, "BACK", Rect2(130, 800, 280, 80), func(): main.show_title(), 30)
	if not Scores.entries.is_empty():
		reset_button = UI.button(self, "Reset scores", Rect2(170, 895, 200, 44), _on_reset, 16, Color("4a2a35"))


func _on_reset() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "Tap again to confirm"
		return
	Scores.clear()
	main.show_leaderboard()


func _process(delta: float) -> void:
	time += delta
	if highlight >= 0:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("confirm"):
		main.show_title()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1020"))
	if highlight >= 0:
		var a := 0.18 + 0.12 * sin(time * 5.0)
		draw_rect(Rect2(8, 170 + highlight * 56, 524, 52), Color(1, 0.83, 0, a))
		draw_rect(Rect2(8, 170 + highlight * 56, 524, 52), Color(1, 0.83, 0, 0.7), false, 2.0)
