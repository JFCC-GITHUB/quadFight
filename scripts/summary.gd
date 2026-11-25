extends Control
## Tournament summary: one row per fight (every attempt, win or lose) and the run totals.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Characters := preload("res://scripts/characters.gd")
const Skill := preload("res://scripts/skill.gd")

var main: Node


func _ready() -> void:
	var won: bool = main.run["won"]
	if won:
		UI.button(self, "NEXT", Rect2(110, 842, 320, 90), func(): main.show_intro(true), 34, Style.BTN_PRIMARY, "swords")
	else:
		UI.button(self, "TRY AGAIN", Rect2(30, 842, 280, 90), func(): main.start_run("tournament", main.run["base"]), 28,
			Style.BTN_PRIMARY, "retry")
		UI.button(self, "MENU", Rect2(322, 842, 188, 90), func(): main.show_title(), 24, Style.BTN_GLASS, "home")


static func time_text(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _draw() -> void:
	Style.draw_bg(self, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.4))
	var run: Dictionary = main.run
	var log: Array = run["log"]
	var won: bool = run["won"]
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 84), "CHAMPION!" if won else "RUN OVER", 48,
		Style.GOLD if won else Color("ff6f8e"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	var fights := 0
	for r in log:
		if r["won"]:
			fights += 1
	Style.text(self, Style.FONT_SEMI, Vector2(0, 120), "%s   |   %d fights won, %d continues used" % [
		Characters.def(run["player"])["name"], fights, run["used"]], 17, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	# one row per fight
	draw_style_box(Style.panel_box(Style.PANEL, 18, Style.PANEL_BORDER), Rect2(16, 140, 508, 440))
	var cols := [["FOE", 28.0, 150.0, HORIZONTAL_ALIGNMENT_LEFT], ["LV", 176.0, 40.0, HORIZONTAL_ALIGNMENT_CENTER],
		["RESULT", 216.0, 80.0, HORIZONTAL_ALIGNMENT_CENTER], ["SCORE", 296.0, 90.0, HORIZONTAL_ALIGNMENT_RIGHT],
		["LINES", 388.0, 60.0, HORIZONTAL_ALIGNMENT_CENTER], ["ATK", 450.0, 66.0, HORIZONTAL_ALIGNMENT_CENTER]]
	for c in cols:
		Style.text(self, Style.FONT_SEMI, Vector2(c[1], 168), c[0], 12, Style.MUTED, c[3], c[2])
	var tot := {"score": 0, "lines": 0, "sent": 0, "taken": 0, "combo": 0, "specials": 0, "quads": 0, "time": 0.0}
	for i in log.size():
		var r: Dictionary = log[i]
		var y := 202.0 + i * 42.0
		if i % 2 == 0:
			draw_rect(Rect2(24, y - 24, 492, 38), Color(1, 1, 1, 0.05))
		var vals := [Characters.def(r["foe"])["name"], str(r["lv"]), "WIN" if r["won"] else "LOSE", str(r["score"]),
			"%d/%d" % [r["lines"], r["cpu_lines"]], str(r["sent"])]
		for k in cols.size():
			var col := Style.TEXT
			if k == 2:
				col = Style.GOLD if r["won"] else Color("ff6f8e")
			Style.text(self, Style.FONT_BOLD, Vector2(cols[k][1], y), vals[k], 15, col, cols[k][3], cols[k][2])
		tot["score"] += r["score"]
		tot["lines"] += r["lines"]
		tot["sent"] += r["sent"]
		tot["taken"] += r["taken"]
		tot["combo"] = maxi(tot["combo"], r["combo"])
		tot["specials"] += r["specials"]
		tot["quads"] += r["quads"]
		tot["time"] += r["time"]
	# totals
	draw_style_box(Style.panel_box(Style.PANEL, 18, Color(Style.GOLD, 0.6)), Rect2(16, 596, 508, 226))
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 632), "TOTAL", 22, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	var cells := [["SCORE", str(tot["score"])], ["LINES", str(tot["lines"])], ["ATTACK SENT", str(tot["sent"])],
		["ATTACK TAKEN", str(tot["taken"])], ["BEST COMBO", str(tot["combo"])], ["SPECIALS", str(tot["specials"])],
		["QUADS", str(tot["quads"])], ["TIME", time_text(tot["time"])]]
	var run_est := Skill.estimate(run["sk"])
	Style.text(self, Style.FONT_BOLD, Vector2(0, 806), "YOUR LEVEL  ~  " + Skill.text(run_est), 19, Style.CYAN,
		HORIZONTAL_ALIGNMENT_CENTER, size.x)
	for i in cells.size():
		var cx := 40.0 + (i % 2) * 250.0
		var cy := 664.0 + (i / 2) * 36.0
		Style.text(self, Style.FONT_SEMI, Vector2(cx, cy), cells[i][0], 12, Style.MUTED)
		Style.text(self, Style.FONT_BOLD, Vector2(cx + 120.0, cy), cells[i][1], 20, Style.TEXT)
