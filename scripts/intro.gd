extends Control
## The "versus" screen shown before every fight, and the tournament champion screen.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Characters := preload("res://scripts/characters.gd")
const Portrait := preload("res://scripts/portrait.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")

const SHOW_TIME := 3.4
const PIC := 288.0  # 3 screen px per art pixel: crisp

var main: Node
var champion := false
var time := 0.0
var land := false
var left_pic: Control
var right_pic: Control
var started := false


func _ready() -> void:
	_build()
	Sfx.play("levelup")


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	var run: Dictionary = main.run
	left_pic = Portrait.new()
	left_pic.set_char(run["player"])
	left_pic.size = Vector2(PIC, PIC)
	add_child(left_pic)
	if champion:
		left_pic.size = Vector2(384, 384)
		left_pic.position = Vector2(70, 90) if land else Vector2(78, 170)
		var x := 540.0 if land else 110.0
		var y := 330.0 if land else 716.0
		UI.button(self, "PLAY AGAIN", Rect2(x, y, 320, 84), func(): main.start_run("tournament", run["base"]), 30,
			Style.BTN_PRIMARY, "retry")
		UI.button(self, "MENU", Rect2(x, y + 98, 320, 70), func(): main.show_title(), 26, Style.BTN_GLASS, "home")
		return
	right_pic = Portrait.new()
	right_pic.set_char(run["cpu"])
	right_pic.flip_h = true
	right_pic.size = Vector2(PIC, PIC)
	add_child(right_pic)
	_place()


func relayout() -> void:
	_build()


func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _place() -> void:
	if champion:
		return
	var a := _ease(time / 0.6)
	if land:
		left_pic.position = Vector2(lerpf(-320.0, 70.0, a), 150)
		right_pic.position = Vector2(lerpf(980.0, 602.0, a), 150)
	else:
		left_pic.position = Vector2(lerpf(-320.0, 30.0, a), 150)
		right_pic.position = Vector2(lerpf(560.0, 222.0, a), 560)


func _process(delta: float) -> void:
	time += delta
	_place()
	if not champion and time >= SHOW_TIME and not started:
		started = true
		main.show_match()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if not champion and time > 0.5 and (tap or event.is_action_pressed("confirm")):
		time = maxf(time, SHOW_TIME)
	elif champion and event.is_action_pressed("confirm"):
		main.start_run("tournament", main.run["base"])


func _fighter_info(id: String, at: Vector2, align: int, w: float) -> void:
	var d := Characters.def(id)
	var col := Color(d["color"])
	Style.text(self, Style.FONT_DISPLAY, at, d["name"], 34, col, align, w, 8)
	Style.text(self, Style.caption_font(), at + Vector2(0, 26), d["skill"], 15, Style.MUTED, align, w)
	var pips := Characters.pips(id)
	var total := pips.size() * 30.0 - 6.0
	var x := at.x + (0.0 if align == HORIZONTAL_ALIGNMENT_LEFT else w - total)
	for i in pips.size():
		var r := Rect2(x + i * 30.0, at.y + 38, 24, 24)
		draw_style_box(Style.panel_box(col.darkened(0.15), 6, col.lightened(0.5)), r)
		Style.text(self, Style.FONT_BOLD, r.position + Vector2(0, 18), str(pips[i]), 16, Color(0.06, 0.04, 0.14),
			HORIZONTAL_ALIGNMENT_CENTER, 24)


func _draw() -> void:
	var run: Dictionary = main.run
	Style.draw_bg(self, size)
	var pc := Color(Characters.def(run["player"])["color"])
	var cc := Color(Characters.def(run["cpu"])["color"]) if not champion else Color("ffd400")
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var a := _ease(time / 0.5)
	if champion:
		Style.text(self, Style.FONT_DISPLAY, Vector2(0, 70), "CHAMPION!", 54, Color("ffd400"), HORIZONTAL_ALIGNMENT_CENTER,
			size.x if not land else 960.0, 10)
		var lines := ["You beat every fighter,", "even your own dark self.", "Tournaments won:  %d" % Settings.tour_clears,
			"Won with  %s" % Characters.def(run["player"])["name"]]
		for i in lines.size():
			Style.text(self, Style.FONT_SEMI, Vector2(540 if land else 0, (200 if land else 596) + i * 30), lines[i], 20,
				Style.TEXT if i != 2 else Style.GOLD, HORIZONTAL_ALIGNMENT_LEFT if land else HORIZONTAL_ALIGNMENT_CENTER,
				400.0 if land else size.x)
		return
	# colour bands, one per fighter, sliding in on a diagonal; speed lines streak across
	var sl := size.x
	var sh := size.y
	var off := (1.0 - a) * sl
	draw_colored_polygon(PackedVector2Array([Vector2(-off, 0), Vector2(sl * 0.62 - off, 0), Vector2(sl * 0.38 - off, sh),
		Vector2(-off, sh)]), Color(pc, 0.28))
	draw_colored_polygon(PackedVector2Array([Vector2(sl * 0.62 + off, 0), Vector2(sl + off, 0), Vector2(sl + off, sh),
		Vector2(sl * 0.38 + off, sh)]), Color(cc, 0.28))
	for i in 16:
		var seed_v := float(i) * 12.9898
		var y := fposmod(sin(seed_v) * 43758.5, 1.0) * sh
		var x := fposmod(time * (900.0 + 70.0 * i) + i * 97.0, sl + 400.0) - 200.0
		var len := 120.0 + 14.0 * i
		draw_line(Vector2(x, y), Vector2(x + len, y), Color(1, 1, 1, 0.10), 2.0)
	# header
	var head := ""
	var boss: bool = run["mode"] == "tournament" and run["round"] == run["order"].size() - 1
	if boss:
		head = "FINAL FIGHT"
	elif run["mode"] == "tournament":
		head = "ROUND %d / %d" % [run["round"] + 1, run["order"].size()]
	else:
		head = {"practice": "PRACTICE", "versus": "2 PLAYERS"}.get(run["mode"], "LADDER")
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 62 if land else 90), head, 40, Color("ff3050") if boss else Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	var sub := "PLAYER 1   VS   PLAYER 2" if run["mode"] == "versus" else "CPU  LV %d   %s" % [run["level"], CpuPlayer.NAMES[run["level"] - 1].to_upper()]
	Style.text(self, Style.caption_font(), Vector2(0, 92 if land else 122), sub,
		16, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	if run["mode"] == "tournament":
		var n: int = run.get("credits", 0)
		var y := 108.0 if land else 138.0
		Style.text(self, Style.caption_font(), Vector2(size.x * 0.5 - 90.0, y + 12.0), "CONTINUES", 13, Style.MUTED)
		for i in n:
			draw_circle(Vector2(size.x * 0.5 + 10.0 + i * 20.0, y + 6.0), 7.0, Style.GOLD)
	# names
	if time > 0.4:
		if land:
			_fighter_info(run["player"], Vector2(70, 470), HORIZONTAL_ALIGNMENT_LEFT, 288)
			_fighter_info(run["cpu"], Vector2(602, 470), HORIZONTAL_ALIGNMENT_RIGHT, 288)
		else:
			_fighter_info(run["player"], Vector2(334, 250), HORIZONTAL_ALIGNMENT_LEFT, 176)
			_fighter_info(run["cpu"], Vector2(30, 660), HORIZONTAL_ALIGNMENT_RIGHT, 176)
	# VS slam, then FIGHT!
	var center := Vector2(size.x * 0.5, size.y * 0.5 + (0.0 if land else 10.0))
	if time > 0.7:
		var k := clampf((time - 0.7) / 0.25, 0.0, 1.0)
		var scale_v := lerpf(3.0, 1.0, _ease(k)) if time < SHOW_TIME - 1.1 else 1.0
		var txt := "VS" if time < SHOW_TIME - 1.1 else "FIGHT!"
		var col := Color("ffd400") if txt == "VS" else Color("ff5a4a")
		var fs := int((110 if txt == "VS" else 84) * scale_v)
		var shake := Vector2(randf_range(-4, 4), randf_range(-4, 4)) * (1.0 - k)
		Style.text(self, Style.FONT_DISPLAY, center + shake + Vector2(-size.x * 0.5, fs * 0.35), txt, fs, col,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(0.1, 0.02, 0.15))
		if time < 0.95:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.8 * (0.95 - time) / 0.25))
	Style.text(self, Style.caption_font(), Vector2(0, size.y - 22), "TAP TO SKIP", 13, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
