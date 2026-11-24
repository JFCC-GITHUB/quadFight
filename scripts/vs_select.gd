extends Control
## Pick the CPU level for VS mode.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")

var main: Node
var level := 3
var time := 0.0
var level_buttons: Array = []
var land := false


func _ready() -> void:
	level = Settings.vs_level
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	level_buttons.clear()
	var origin := Vector2(40, 150) if land else Vector2(26, 176)
	for i in 10:
		var lv := i + 1
		var r := Rect2(origin + Vector2((i % 5) * 100, (i / 5) * 100), Vector2(88, 88))
		var b := UI.button(self, str(lv), r, func(): _select(lv), 34, Style.BTN_GLASS)
		level_buttons.append(b)
	if land:
		UI.button(self, "NEXT", Rect2(600, 440, 300, 80), _start, 38, Style.BTN_PRIMARY, "swords")
		UI.button(self, "BACK", Rect2(40, 450, 200, 64), func(): main.show_title(), 26, Style.BTN_GLASS, "left")
	else:
		UI.button(self, "NEXT", Rect2(110, 704, 320, 94), _start, 38, Style.BTN_PRIMARY, "swords")
		UI.button(self, "BACK", Rect2(150, 814, 240, 70), func(): main.show_title(), 26, Style.BTN_GLASS, "left")
	_refresh()


## Called by Main when the window is rotated.
func relayout() -> void:
	_build()


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
	Style.draw_bg(self, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	var hx := size.x * 0.5
	Style.draw_icon(self, "swords", Vector2(hx - 100, 64), 44, Style.TEXT)
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 82), "VS CPU", 38, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x + 90, 8)
	Style.text(self, Style.caption_font(), Vector2(0, 140 if land else 150), "CHOOSE THE COMPUTER'S LEVEL", 16,
		Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x if not land else 580.0)

	# Level details card
	var card := Rect2(570, 120, 360, 290) if land else Rect2(26, 392, 488, 264)
	draw_style_box(Style.panel_box(Style.PANEL, 24, Style.PANEL_BORDER, Color(0.3, 0.2, 0.9, 0.25), 24), card)
	var p := CpuPlayer.params(level)
	var cap := Style.caption_font()
	var left := card.position.x
	Style.text(self, Style.FONT_DISPLAY, Vector2(left, card.position.y + 54), "Lv %d  %s" % [level, CpuPlayer.NAMES[level - 1]],
		32, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
	var rows := [
		["REACTION", "%.2f s" % p["think"]],
		["MOVE SPEED", "%.1f moves / sec" % (1.0 / p["act"])],
		["MISTAKES", "%d%% of pieces" % roundi(p["mistake"] * 100.0)],
	]
	for i in rows.size():
		var y := card.position.y + 102.0 + i * 38.0
		Style.text(self, cap, Vector2(left + 34, y), rows[i][0], 15, Style.MUTED)
		Style.text(self, Style.FONT_BOLD, Vector2(left, y + 2), rows[i][1], 24, Style.TEXT,
			HORIZONTAL_ALIGNMENT_RIGHT, card.size.x - 34)
	var rec: Array = Settings.record(level)
	Style.text(self, Style.FONT_SEMI, Vector2(left, card.position.y + 244), "Your record:  %d wins  /  %d losses" % [rec[0], rec[1]],
		20 if not land else 17, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
	var hint_pos := Vector2(40, 388) if land else Vector2(0, 684)
	Style.text(self, Style.FONT_SEMI, hint_pos, "Clear lines to drop 1-10 blocks on your rival!", 16,
		Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 500.0 if land else size.x)
