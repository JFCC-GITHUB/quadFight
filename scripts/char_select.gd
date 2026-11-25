extends Control
## Pick your VS character (step 0) and, for LADDER, the opponent or random (step 1): two pages (HEROES / BEASTS) of
## 2 x 3 cards, details + animated attack preview.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Characters := preload("res://scripts/characters.gd")
const Portrait := preload("res://scripts/portrait.gd")
const FxLayer := preload("res://scripts/fx_layer.gd")

const CARD_W := 238.0
const CARD_H := 150.0
const HEAD := Rect2(0.1, 0.0, 0.78, 0.78)  # crop of the bust shown on a card
const PER_PAGE := 6
const PAGES := ["HEROES", "BEASTS"]

var main: Node
var level := 3         # CPU level chosen on the previous screen
var mode := "ladder"   # "ladder" | "tournament"
var step := 0          # 0: your fighter, 1: the opponent (ladder)
var random_pick := false
var selected := 0
var page := 0
var time := 0.0
var fx: Control
var preview_t := 0.0
var cards: Array = []
var land := false


func _ready() -> void:
	var want: String = Settings.vs_char if step == 0 else Settings.vs_cpu_char
	random_pick = step == 1 and want == "random"
	for i in Characters.LIST.size():
		if Characters.LIST[i]["id"] == want:
			selected = i
	page = selected / PER_PAGE
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	cards.clear()
	for i: int in _page_ids():
		var r := _card_rect(i)
		var b := Button.new()
		b.flat = true
		b.position = r.position
		b.size = r.size
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _select(i))
		add_child(b)
		var p := Portrait.new()
		p.crop = HEAD
		p.position = r.position + Vector2(10, 19)
		p.size = Vector2(112, 112)
		p.set_char(Characters.LIST[i]["id"])
		add_child(p)
		cards.append(p)
	fx = FxLayer.new()
	fx.size = size
	add_child(fx)
	var go := "NEXT" if step == 0 and mode == "ladder" else "START"
	if land:
		UI.button(self, go, Rect2(716, 436, 224, 80), _start, 34, Style.BTN_PRIMARY, "swords")
	else:
		UI.button(self, go, Rect2(110, 832, 320, 94), _start, 38, Style.BTN_PRIMARY, "swords")
	UI.icon_button(self, "left", Rect2(16, 24, 56, 56), _back, Style.BTN_GLASS)
	for k in PAGES.size():
		var tr := Rect2(716 + k * 116, 28, 108, 48) if land else Rect2(26 + k * 250, 96, 238, 28)
		UI.button(self, PAGES[k], tr, func(): _select(k * PER_PAGE), 20 if land else 18,
			Style.BTN_ACCENT if k == page else Style.BTN_GLASS)
	if step == 1:
		var rr := Rect2(24, 448, 676, 64) if land else Rect2(26, 610, 488, 76)
		UI.button(self, "RANDOM OPPONENT", rr, func():
			random_pick = true
			_build.call_deferred(), 26, Style.BTN_PRIMARY if random_pick else Style.BTN_GLASS)
	_select(-1 if random_pick else selected)


## Called by Main when the window is rotated.
func relayout() -> void:
	_build()


func _cols() -> int:
	return 3 if land else 2


func _page_ids() -> Array:
	return range(page * PER_PAGE, mini((page + 1) * PER_PAGE, Characters.LIST.size()))


func _card_rect(i: int) -> Rect2:
	i %= PER_PAGE
	if land:  # 3 columns x 2 rows on the left, details on the right
		return Rect2(24 + (i % 3) * 230.0, 100 + (i / 3) * 170.0, 220, 160)
	return Rect2(26 + (i % 2) * (CARD_W + 12), 128 + (i / 2) * (CARD_H + 10), CARD_W, CARD_H)


func _back() -> void:
	if step == 1:
		main.show_char_select(level, mode, 0)
	else:
		main.show_vs_select(mode)


func _select(i: int) -> void:
	preview_t = 0.0
	fx.clear()
	if i < 0:
		queue_redraw()
		return
	if random_pick:
		random_pick = false
		_build.call_deferred()  # the RANDOM button goes back to normal
	selected = i
	if i / PER_PAGE != page:
		page = i / PER_PAGE
		_build.call_deferred()
	var id: String = Characters.LIST[i]["id"]
	fx.play(Characters.FX_HIT[id], Rect2(780, 304, 120, 120) if land else Rect2(400, 708, 120, 120), 10.0, true)
	queue_redraw()


func _start() -> void:
	if step == 0:
		Settings.vs_char = Characters.LIST[selected]["id"]
		Settings.save()
		if mode == "tournament":
			main.start_run("tournament", level)
		else:
			main.show_char_select(level, mode, 1)
	else:
		Settings.vs_cpu_char = "random" if random_pick else Characters.LIST[selected]["id"]
		Settings.save()
		main.start_run("ladder", level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_start()
	elif event.is_action_pressed("pause"):
		_back()
	elif event.is_action_pressed("move_left") and selected > 0:
		_select(selected - 1)
	elif event.is_action_pressed("move_right") and selected < Characters.LIST.size() - 1:
		_select(selected + 1)
	elif event.is_action_pressed("soft_drop") and selected % PER_PAGE + _cols() < PER_PAGE:
		_select(selected + _cols())
	elif event.is_action_pressed("rotate_cw") and selected % PER_PAGE >= _cols():
		_select(selected - _cols())


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


## Largest font size (at most `fs`) at which `text` fits in `avail` pixels.
func _fit(font: Font, text: String, fs: int, avail: float) -> int:
	while fs > 8 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
		fs -= 1
	return fs


## Little numbered squares showing what a recipe needs.
func _draw_pips(id: String, at: Vector2, sz: float, col: Color) -> void:
	var x := at.x
	for n in Characters.pips(id):
		var r := Rect2(x, at.y, sz, sz)
		draw_style_box(Style.panel_box(col.darkened(0.15), 6, col.lightened(0.5)), r)
		Style.text(self, Style.FONT_BOLD, r.position + Vector2(0, sz * 0.74), str(n), int(sz * 0.7),
			Color(0.06, 0.04, 0.14), HORIZONTAL_ALIGNMENT_CENTER, sz)
		x += sz + 5.0


func _draw() -> void:
	Style.draw_bg(self, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 74 if land else 82), "CHOOSE FIGHTER" if step == 0 else "CHOOSE OPPONENT", 36, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	for i: int in _page_ids():
		var d: Dictionary = Characters.LIST[i]
		var col := Color(d["color"])
		var r := _card_rect(i)
		var on := i == selected and not random_pick
		var border := col if on else Style.PANEL_BORDER
		var glow := Color(col, 0.45 + 0.2 * sin(time * 5.0)) if on else Color(0, 0, 0, 0)
		draw_style_box(Style.panel_box(Color(0.1, 0.07, 0.22, 0.92) if on else Style.PANEL, 18, border, glow, 18 if on else 0), r)
		var tx := 124.0 if land else 130.0
		var avail := r.size.x - tx - 10.0
		Style.text(self, Style.FONT_DISPLAY, r.position + Vector2(tx, 52), d["name"],
			_fit(Style.FONT_DISPLAY, d["name"], 20 if land else 22, avail), col if on else Style.TEXT)
		Style.text(self, Style.caption_font(), r.position + Vector2(tx, 76), d["skill"],
			_fit(Style.caption_font(), d["skill"], 13, avail), Style.MUTED)
		var n: int = Characters.pips(d["id"]).size()
		_draw_pips(d["id"], r.position + Vector2(tx, 92), minf(22.0 if land else 24.0, (avail - 5.0 * (n - 1)) / n), col)

	# details
	var d: Dictionary = Characters.LIST[selected]
	var col := Color(d["color"])
	var box := Rect2(716, 100, 224, 320) if land else Rect2(26, 700, 488, 128)
	if random_pick:
		draw_style_box(Style.panel_box(Style.PANEL, 22, Color(Style.GOLD, 0.7), Color(Style.GOLD, 0.18), 20), box)
		Style.text(self, Style.FONT_DISPLAY, box.position + Vector2(18, 44), "RANDOM", 28, Style.GOLD)
		draw_multiline_string(Style.FONT_SEMI, box.position + Vector2(18, 74), "A different fighter every time you start the ladder.",
			HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 36.0, 15, 4, Style.TEXT)
		return
	draw_style_box(Style.panel_box(Style.PANEL, 22, Color(col, 0.7), Color(col, 0.18), 20), box)
	var bx := box.position.x + 18.0
	Style.text(self, Style.FONT_DISPLAY, Vector2(bx, box.position.y + 38), d["skill"], 24 if land else 26, col)
	_draw_pips(d["id"], Vector2(bx, box.position.y + 50), 26.0, col)
	if land:
		Style.text(self, Style.FONT_SEMI, Vector2(bx, box.position.y + 108), "Clears add up in any order.", 12, Style.MUTED)
		draw_multiline_string(Style.FONT_SEMI, Vector2(bx, box.position.y + 128), d["desc"], HORIZONTAL_ALIGNMENT_LEFT,
			box.size.x - 36.0, 13, 4, Style.TEXT)
	else:
		Style.text(self, Style.FONT_SEMI, Vector2(bx, 806), "Clears add up in any order.", 14, Style.MUTED)
		Style.text(self, Style.FONT_SEMI, Vector2(bx, 822), d["desc"], 13, Style.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 350)
