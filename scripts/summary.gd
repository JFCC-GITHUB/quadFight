extends Control
## Tournament summary: one row per fight (every attempt, win or lose) and the run totals. Portrait and landscape.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Characters := preload("res://scripts/characters.gd")
const Skill := preload("res://scripts/skill.gd")

# column name, x offset inside the table (of a 488 px wide table), width, alignment
const COLS := [["FOE", 0.0, 150.0, HORIZONTAL_ALIGNMENT_LEFT], ["LV", 148.0, 40.0, HORIZONTAL_ALIGNMENT_CENTER],
	["RESULT", 188.0, 80.0, HORIZONTAL_ALIGNMENT_CENTER], ["SCORE", 268.0, 90.0, HORIZONTAL_ALIGNMENT_RIGHT],
	["LINES", 360.0, 60.0, HORIZONTAL_ALIGNMENT_CENTER], ["ATK", 422.0, 66.0, HORIZONTAL_ALIGNMENT_CENTER]]

var main: Node
var land := false


func _ready() -> void:
	_build()


## Called by Main when the window is rotated.
func relayout() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	var won: bool = main.run["won"]
	var y := 446.0 if land else 842.0
	var h := 76.0 if land else 90.0
	if won:
		var r := Rect2(632, y, 280, h) if land else Rect2(110, y, 320, h)
		UI.button(self, "NEXT", r, func(): main.show_intro(true), 34, Style.BTN_PRIMARY, "swords")
	else:
		UI.button(self, "TRY AGAIN", Rect2(592, y, 200, h) if land else Rect2(30, y, 280, h),
			func(): main.start_run("tournament", main.run["base"]), 26, Style.BTN_PRIMARY, "retry")
		UI.button(self, "MENU", Rect2(804, y, 140, h) if land else Rect2(322, y, 188, h), func(): main.show_title(), 22,
			Style.BTN_GLASS, "home")
	queue_redraw()


static func time_text(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _draw() -> void:
	Style.draw_bg(self, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.4))
	var run: Dictionary = main.run
	var log: Array = run["log"]
	var won: bool = run["won"]
	var wins := 0
	for r in log:
		if r["won"]:
			wins += 1
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 56 if land else 84), "CHAMPION!" if won else "RUN OVER", 44 if land else 48,
		Style.GOLD if won else Color("ff6f8e"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	Style.text(self, Style.FONT_SEMI, Vector2(0, 88 if land else 120), "%s   |   %d fights won, %d continues used" % [
		Characters.def(run["player"])["name"], wins, run["used"]], 17, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)

	# one row per fight; rows shrink so every attempt fits
	var table := Rect2(16, 106, 560, 424) if land else Rect2(16, 140, 508, 440)
	draw_style_box(Style.panel_box(Style.PANEL, 18, Style.PANEL_BORDER), table)
	var tx := table.position.x + 12.0
	var k := (table.size.x - 24.0) / 488.0
	var head_y := table.position.y + 28.0
	for c in COLS:
		Style.text(self, Style.FONT_SEMI, Vector2(tx + c[1] * k, head_y), c[0], 12, Style.MUTED, c[3], c[2] * k)
	var top := head_y + 34.0
	var rh := minf(42.0, (table.end.y - 14.0 - top + 24.0) / maxf(log.size(), 1))
	var fs := 15 if rh >= 30.0 else 13
	var tot := {"score": 0, "lines": 0, "sent": 0, "taken": 0, "combo": 0, "specials": 0, "quads": 0, "time": 0.0}
	for i in log.size():
		var r: Dictionary = log[i]
		var y := top + i * rh
		if i % 2 == 0:
			draw_rect(Rect2(table.position.x + 8, y - rh * 0.62, table.size.x - 16, rh * 0.92), Color(1, 1, 1, 0.05))
		var vals := [Characters.def(r["foe"])["name"], str(r["lv"]), "WIN" if r["won"] else "LOSE", str(r["score"]),
			"%d/%d" % [r["lines"], r["cpu_lines"]], str(r["sent"])]
		for j in COLS.size():
			var col := Style.TEXT
			if j == 2:
				col = Style.GOLD if r["won"] else Color("ff6f8e")
			Style.text(self, Style.FONT_BOLD, Vector2(tx + COLS[j][1] * k, y), vals[j], fs, col, COLS[j][3], COLS[j][2] * k)
		for key in ["score", "lines", "sent", "taken", "specials", "quads", "time"]:
			tot[key] += r[key]
		tot["combo"] = maxi(tot["combo"], r["combo"])

	# totals
	var cells := [["SCORE", str(tot["score"])], ["LINES", str(tot["lines"])], ["ATTACK SENT", str(tot["sent"])],
		["ATTACK TAKEN", str(tot["taken"])], ["BEST COMBO", str(tot["combo"])], ["SPECIALS", str(tot["specials"])],
		["QUADS", str(tot["quads"])], ["TIME", time_text(tot["time"])]]
	var level_line := "YOUR LEVEL  ~  " + Skill.text(Skill.estimate(run["sk"]))
	if land:  # one column beside the table
		var box := Rect2(592, 106, 352, 324)
		draw_style_box(Style.panel_box(Style.PANEL, 18, Color(Style.GOLD, 0.6)), box)
		Style.text(self, Style.FONT_DISPLAY, Vector2(box.position.x, 140), "TOTAL", 22, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
		for i in cells.size():
			var y := 176.0 + i * 28.0
			Style.text(self, Style.FONT_SEMI, Vector2(box.position.x + 20, y), cells[i][0], 12, Style.MUTED)
			Style.text(self, Style.FONT_BOLD, Vector2(box.position.x, y), cells[i][1], 18, Style.TEXT, HORIZONTAL_ALIGNMENT_RIGHT,
				box.size.x - 20)
		Style.text(self, Style.FONT_BOLD, Vector2(box.position.x, 418), level_line, 15, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER,
			box.size.x)
		return
	draw_style_box(Style.panel_box(Style.PANEL, 18, Color(Style.GOLD, 0.6)), Rect2(16, 596, 508, 226))
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 632), "TOTAL", 22, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	for i in cells.size():
		var cx := 40.0 + (i % 2) * 250.0
		var cy := 664.0 + (i / 2) * 36.0
		Style.text(self, Style.FONT_SEMI, Vector2(cx, cy), cells[i][0], 12, Style.MUTED)
		Style.text(self, Style.FONT_BOLD, Vector2(cx + 120.0, cy), cells[i][1], 20, Style.TEXT)
	Style.text(self, Style.FONT_BOLD, Vector2(0, 806), level_line, 19, Style.CYAN, HORIZONTAL_ALIGNMENT_CENTER, size.x)
