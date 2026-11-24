extends Control
## Pick the CPU level (and how it uses its special attack) for LADDER or TOURNAMENT.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")

var main: Node
var mode := "ladder"   # "ladder" | "tournament"
var level := 3
var time := 0.0
var land := false
var slider: HSlider


func _ready() -> void:
	level = clampi(Settings.vs_level, 1, CpuPlayer.MAX_LEVEL)
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	var sx := 40.0 if land else 26.0
	var sw := 500.0 if land else 488.0
	var y0 := 128.0 if land else 160.0
	UI.icon_button(self, "left", Rect2(sx, y0, 76, 76), func(): _set_level(level - 1), Style.BTN_GLASS)
	UI.icon_button(self, "right", Rect2(sx + sw - 76, y0, 76, 76), func(): _set_level(level + 1), Style.BTN_GLASS)
	slider = HSlider.new()
	slider.position = Vector2(sx + 8, y0 + 96)
	slider.size = Vector2(sw - 16, 44)
	slider.min_value = 1
	slider.max_value = CpuPlayer.MAX_LEVEL
	slider.step = 1
	slider.value = level
	slider.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.14)
	track.set_corner_radius_all(6)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	var fill := StyleBoxFlat.new()
	fill.bg_color = Style.CYAN
	fill.set_corner_radius_all(6)
	fill.content_margin_top = 7
	fill.content_margin_bottom = 7
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	for k in ["grabber", "grabber_highlight", "grabber_disabled"]:
		slider.add_theme_icon_override(k, Style.KNOB)
	slider.value_changed.connect(func(v): _set_level(int(v)))
	add_child(slider)
	# CPU special attack: never / when it happens / aims for it
	var seg_y := 322.0 if land else 598.0
	var labels := ["NEVER", "NORMAL", "AIM"]
	var gap := 8.0
	var w := (sw - gap * 2.0) / 3.0
	for i in 3:
		var idx := i
		UI.button(self, labels[i], Rect2(sx + i * (w + gap), seg_y, w, 56), func():
			Settings.cpu_special = idx
			_build(), 20, Style.BTN_PRIMARY if i == Settings.cpu_special else Style.BTN_GLASS)
	if land:
		UI.button(self, "NEXT", Rect2(600, 440, 300, 80), _start, 38, Style.BTN_PRIMARY, "swords")
		UI.button(self, "BACK", Rect2(40, 450, 200, 64), func(): main.show_title(), 26, Style.BTN_GLASS, "left")
	else:
		UI.button(self, "NEXT", Rect2(110, 704, 320, 94), _start, 38, Style.BTN_PRIMARY, "swords")
		UI.button(self, "BACK", Rect2(150, 814, 240, 70), func(): main.show_title(), 26, Style.BTN_GLASS, "left")
	queue_redraw()


## Called by Main when the window is rotated.
func relayout() -> void:
	_build()


func _set_level(lv: int) -> void:
	lv = clampi(lv, 1, CpuPlayer.MAX_LEVEL)
	if lv == level:
		return
	level = lv
	if slider and int(slider.value) != lv:
		slider.set_value_no_signal(lv)
	queue_redraw()


func _start() -> void:
	Settings.vs_level = level
	Settings.save()
	main.show_char_select(level, mode, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_start()
	elif event.is_action_pressed("pause"):
		main.show_title()
	elif event.is_action_pressed("move_left"):
		_set_level(level - 1)
	elif event.is_action_pressed("move_right"):
		_set_level(level + 1)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	Style.draw_bg(self, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	var hx := size.x * 0.5
	var title := "TOURNAMENT" if mode == "tournament" else "LADDER"
	Style.draw_icon(self, "swords" if mode == "tournament" else "up", Vector2(hx - 40 - title.length() * 11.0, 64), 44, Style.TEXT)
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 82), title, 38, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, size.x + 90, 8)
	var cap := Style.caption_font()
	var sub := "START LEVEL  (each fight is 1 level harder)" if mode == "tournament" else "CHOOSE THE COMPUTER'S LEVEL"
	var cx := 290.0 if land else hx
	Style.text(self, cap, Vector2(cx - 300.0, 112 if land else 140), sub, 15, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 600.0)
	# big level readout between the arrows
	var y0 := 128.0 if land else 160.0
	Style.text(self, Style.FONT_DISPLAY, Vector2(cx - 150.0, y0 + 52), "Lv %d" % level, 50, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 300.0)
	Style.text(self, Style.FONT_BOLD, Vector2(cx - 150.0, y0 + 74), CpuPlayer.NAMES[level - 1].to_upper(), 16, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, 300.0)
	# details card
	var card := Rect2(570, 120, 360, 290) if land else Rect2(26, 312, 488, 226)
	draw_style_box(Style.panel_box(Style.PANEL, 24, Style.PANEL_BORDER, Color(0.3, 0.2, 0.9, 0.25), 24), card)
	var p := CpuPlayer.params(level)
	var rows := [
		["REACTION", "%.2f s" % p["think"]],
		["MOVE SPEED", "%.1f moves / sec" % (1.0 / p["act"])],
		["MISTAKES", "%d%% of pieces" % roundi(p["mistake"] * 100.0) if p["mistake"] >= 0.01 else "almost none" if p["mistake"] > 0.0 else "none"],
		["THINKS AHEAD", "next piece" if level >= CpuPlayer.LOOKAHEAD_FROM else "this piece"],
	]
	var top := card.position.y + (56.0 if land else 50.0)
	var step := 40.0 if land else 36.0
	for i in rows.size():
		var y := top + i * step
		Style.text(self, cap, Vector2(card.position.x + 34, y), rows[i][0], 15, Style.MUTED)
		Style.text(self, Style.FONT_BOLD, Vector2(card.position.x, y + 2), rows[i][1], 22, Style.TEXT,
			HORIZONTAL_ALIGNMENT_RIGHT, card.size.x - 34)
	var rec: Array = Settings.record(level)
	var rec_txt := "Your record:  %d wins  /  %d losses" % [rec[0], rec[1]] if mode == "ladder" \
		else "Tournaments won:  %d" % Settings.tour_clears
	Style.text(self, Style.FONT_SEMI, Vector2(card.position.x, card.end.y - 22), rec_txt, 18 if not land else 16, Style.CYAN,
		HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
	# special attack setting
	var sy := 304.0 if land else 578.0
	var scap: String = "CPU SPECIAL ATTACK:  " + ["NEVER USES IT", "USES IT WHEN IT HAPPENS", "AIMS FOR IT"][Settings.cpu_special]
	Style.text(self, cap, Vector2(40 if land else 26, sy), scap, 14, Style.MUTED)
