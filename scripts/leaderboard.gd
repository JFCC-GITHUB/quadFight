extends Control

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")

const CARD := Rect2(16, 120, 508, 660)
const ROW_Y := 196.0
const ROW_H := 56.0

var main: Node
var highlight := -1
var reset_armed := false
var reset_button: Button
var time := 0.0


func _ready() -> void:
	highlight = Scores.highlight
	Scores.highlight = -1
	UI.button(self, "BACK", Rect2(130, 806, 280, 84), func(): main.show_title(), 30,
		Style.BTN_GLASS, "home")
	if not Scores.entries.is_empty():
		reset_button = UI.button(self, "Reset scores", Rect2(180, 904, 180, 40), _on_reset, 15, Style.BTN_DANGER)
		reset_button.add_theme_font_override("font", Style.FONT_BOLD)
		reset_button.modulate.a = 0.8


func _on_reset() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "Tap again to clear"
		return
	Scores.clear()
	main.show_leaderboard()


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("confirm"):
		main.show_title()


func _draw() -> void:
	draw_texture_rect(Style.bg_texture(), Rect2(Vector2.ZERO, size), false)
	Style.draw_icon(self, "trophy", Vector2(size.x * 0.5, 44), 40, Style.GOLD)
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 104), "RANKING", 40, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)

	draw_style_box(Style.panel_box(Style.PANEL, 24, Style.PANEL_BORDER, Color(0.3, 0.2, 0.9, 0.25), 24), CARD)
	var cap := Style.caption_font()
	var hy := CARD.position.y + 46
	Style.text(self, cap, Vector2(76, hy), "NAME", 15, Style.MUTED)
	Style.text(self, cap, Vector2(170, hy), "SCORE", 15, Style.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 140)
	Style.text(self, cap, Vector2(318, hy), "LINES", 15, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 64)
	Style.text(self, cap, Vector2(382, hy), "LV", 15, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 44)
	Style.text(self, cap, Vector2(426, hy), "DATE", 15, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 86)

	if Scores.entries.is_empty():
		Style.text(self, Style.FONT_DISPLAY, Vector2(0, 430), "NO SCORES YET", 28, Style.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, size.x)
		Style.text(self, Style.FONT_SEMI, Vector2(0, 470), "Play a game to get on the board!", 20,
			Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		return

	for i in Scores.entries.size():
		var e: Dictionary = Scores.entries[i]
		var row := Rect2(CARD.position.x + 12, ROW_Y + i * ROW_H, CARD.size.x - 24, ROW_H - 6)
		if i == highlight:
			var a := 0.22 + 0.12 * sin(time * 5.0)
			draw_style_box(Style.panel_box(Color(1, 0.82, 0.3, a), 12, Color(1, 0.82, 0.3, 0.8)), row)
		elif i % 2 == 0:
			draw_style_box(Style.panel_box(Color(1, 1, 1, 0.035), 12, Color(0, 0, 0, 0)), row)
		var cy := row.position.y + row.size.y * 0.5
		var base := cy + 10
		# Rank badge
		var badge_c := Vector2(row.position.x + 26, cy)
		if i < 3:
			draw_circle(badge_c, 16, Style.MEDALS[i])
			draw_circle(badge_c, 16, Style.MEDALS[i].darkened(0.35), false, 2.0, true)
			Style.text(self, Style.FONT_DISPLAY, badge_c + Vector2(-16, 7), str(i + 1), 18,
				Color("1a1030"), HORIZONTAL_ALIGNMENT_CENTER, 32)
		else:
			Style.text(self, Style.FONT_DISPLAY, badge_c + Vector2(-16, 7), str(i + 1), 18,
				Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 32)
		var col: Color = Style.MEDALS[i] if i < 3 else Style.TEXT
		Style.text(self, Style.FONT_DISPLAY, Vector2(76, base), str(e["name"]), 22, col)
		Style.text(self, Style.FONT_DISPLAY, Vector2(170, base), str(e["score"]), 24, col,
			HORIZONTAL_ALIGNMENT_RIGHT, 140)
		Style.text(self, Style.FONT_BOLD, Vector2(318, base), str(e["lines"]), 22, Style.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, 64)
		Style.text(self, Style.FONT_BOLD, Vector2(382, base), str(e["level"]), 22, Style.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, 44)
		Style.text(self, Style.FONT_SEMI, Vector2(426, base - 1), str(e["date"]).substr(5).replace("-", "/"),
			18, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 86)
