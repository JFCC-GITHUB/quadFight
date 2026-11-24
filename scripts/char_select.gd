extends Control
## Pick your VS character: 2 x 3 cards, details + animated attack preview below.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Characters := preload("res://scripts/characters.gd")
const Portrait := preload("res://scripts/portrait.gd")
const FxLayer := preload("res://scripts/fx_layer.gd")

const CARD_W := 238.0
const CARD_H := 150.0
const HEAD := Rect2(0.18, 0.0, 0.64, 0.64)  # crop of the bust shown on a card

var main: Node
var cpu_level := 3
var selected := 0
var time := 0.0
var fx: Control
var preview_t := 0.0
var cards: Array = []


func _ready() -> void:
	for i in Characters.LIST.size():
		if Characters.LIST[i]["id"] == Settings.vs_char:
			selected = i
	for i in Characters.LIST.size():
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
	UI.button(self, "START", Rect2(110, 832, 320, 94), _start, 38, Style.BTN_PRIMARY, "swords")
	UI.icon_button(self, "left", Rect2(16, 24, 56, 56), func(): main.show_vs_select(), Style.BTN_GLASS)
	_select(selected)


func _card_rect(i: int) -> Rect2:
	return Rect2(26 + (i % 2) * (CARD_W + 12), 128 + (i / 2) * (CARD_H + 10), CARD_W, CARD_H)


func _select(i: int) -> void:
	selected = i
	preview_t = 0.0
	var id: String = Characters.LIST[i]["id"]
	fx.clear()
	fx.play(Characters.FX_HIT[id], Rect2(400, 708, 120, 120), 10.0, true)
	queue_redraw()


func _start() -> void:
	Settings.vs_char = Characters.LIST[selected]["id"]
	Settings.save()
	main.show_game(true, cpu_level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_start()
	elif event.is_action_pressed("pause"):
		main.show_vs_select()
	elif event.is_action_pressed("move_left") and selected > 0:
		_select(selected - 1)
	elif event.is_action_pressed("move_right") and selected < Characters.LIST.size() - 1:
		_select(selected + 1)
	elif event.is_action_pressed("soft_drop") and selected + 2 < Characters.LIST.size():
		_select(selected + 2)
	elif event.is_action_pressed("rotate_cw") and selected >= 2:
		_select(selected - 2)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


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
	draw_texture_rect(Style.bg_texture(), Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 82), "CHOOSE FIGHTER", 36, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	for i in Characters.LIST.size():
		var d: Dictionary = Characters.LIST[i]
		var col := Color(d["color"])
		var r := _card_rect(i)
		var on := i == selected
		var border := col if on else Style.PANEL_BORDER
		var glow := Color(col, 0.45 + 0.2 * sin(time * 5.0)) if on else Color(0, 0, 0, 0)
		draw_style_box(Style.panel_box(Color(0.1, 0.07, 0.22, 0.92) if on else Style.PANEL, 18, border, glow, 18 if on else 0), r)
		Style.text(self, Style.FONT_DISPLAY, r.position + Vector2(130, 52), d["name"], 22, col if on else Style.TEXT)
		Style.text(self, Style.caption_font(), r.position + Vector2(130, 76), d["skill"], 13, Style.MUTED)
		_draw_pips(d["id"], r.position + Vector2(130, 92), 24.0, col)

	# details
	var d: Dictionary = Characters.LIST[selected]
	var col := Color(d["color"])
	var box := Rect2(26, 700, 488, 128)
	draw_style_box(Style.panel_box(Style.PANEL, 22, Color(col, 0.7), Color(col, 0.18), 20), box)
	Style.text(self, Style.FONT_DISPLAY, Vector2(44, 738), d["skill"], 26, col)
	_draw_pips(d["id"], Vector2(44, 750), 26.0, col)
	Style.text(self, Style.FONT_SEMI, Vector2(44, 806), "Clears add up in any order.", 14, Style.MUTED)
	Style.text(self, Style.FONT_SEMI, Vector2(44, 822), d["desc"], 13, Style.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 350)
