extends Control
## Pick the CPU level for VS mode.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")

var main: Node
var level := 3
var time := 0.0
var level_buttons: Array = []


func _ready() -> void:
	level = Settings.vs_level
	for i in 10:
		var lv := i + 1
		var r := Rect2(26 + (i % 5) * 100, 176 + (i / 5) * 100, 88, 88)
		var b := UI.button(self, str(lv), r, func(): _select(lv), 34, Style.BTN_GLASS)
		level_buttons.append(b)
	UI.button(self, "NEXT", Rect2(110, 704, 320, 94), _start, 38, Style.BTN_PRIMARY, "swords")
	UI.button(self, "BACK", Rect2(150, 814, 240, 70), func(): main.show_title(), 26, Style.BTN_GLASS, "left")
	_refresh()


func _select(lv: int) -> void:
	level = lv
	_refresh()


func _refresh() -> void:
	for i in 10:
		var b: Button = level_buttons[i]
		var scheme := Style.BTN_ACCENT if i + 1 == level else Style.BTN_GLASS
		b.add_theme_stylebox_override("normal", Style.button_box(scheme, false))
		b.add_theme_stylebox_override("hover", Style.button_box(scheme, false))
		b.add_theme_stylebox_override("pressed", Style.button_box(scheme, true))
	queue_redraw()


func _start() -> void:
	Settings.vs_level = level
	Settings.save()
	main.show_char_select(level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_start()
	elif event.is_action_pressed("pause"):
		main.show_title()


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(Style.bg_texture(), Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	Style.draw_icon(self, "swords", Vector2(170, 64), 44, Style.TEXT)
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 82), "VS CPU", 38, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x + 90, 8)
	Style.text(self, Style.caption_font(), Vector2(0, 150), "CHOOSE THE COMPUTER'S LEVEL", 16, Style.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER, size.x)

	# Level details card
	var card := Rect2(26, 392, 488, 264)
	draw_style_box(Style.panel_box(Style.PANEL, 24, Style.PANEL_BORDER, Color(0.3, 0.2, 0.9, 0.25), 24), card)
	var p := CpuPlayer.params(level)
	var cap := Style.caption_font()
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 446), "Lv %d  %s" % [level, CpuPlayer.NAMES[level - 1]], 32,
		Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	var rows := [
		["REACTION", "%.2f s" % p["think"]],
		["MOVE SPEED", "%.1f moves / sec" % (1.0 / p["act"])],
		["MISTAKES", "%d%% of pieces" % roundi(p["mistake"] * 100.0)],
	]
	for i in rows.size():
		var y := 494.0 + i * 38.0
		Style.text(self, cap, Vector2(60, y), rows[i][0], 15, Style.MUTED)
		Style.text(self, Style.FONT_BOLD, Vector2(0, y + 2), rows[i][1], 24, Style.TEXT,
			HORIZONTAL_ALIGNMENT_RIGHT, 480)
	var rec: Array = Settings.record(level)
	Style.text(self, Style.FONT_SEMI, Vector2(0, 636), "Your record:  %d wins  /  %d losses" % [rec[0], rec[1]], 20,
		Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	Style.text(self, Style.FONT_SEMI, Vector2(0, 684), "Clear lines to drop 1-10 blocks on your rival!", 16,
		Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
