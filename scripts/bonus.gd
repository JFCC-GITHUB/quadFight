extends Control
## Bonus stage: smash the car before time runs out. Played between tournament fights (a destroyed car gives a
## continue) and, as a free-play secret, by tapping the title of the Options screen seven times.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const Portrait := preload("res://scripts/portrait.gd")
const Characters := preload("res://scripts/characters.gd")

const CARS := [
	preload("res://assets/bonus/car_0.png"), preload("res://assets/bonus/car_1.png"), preload("res://assets/bonus/car_2.png"),
	preload("res://assets/bonus/car_3.png"), preload("res://assets/bonus/car_4.png"),
]
const HP := 36
const TIME := 10.0
const MAX_CREDITS := 5
const CAR_SIZE := Vector2(384, 192)

var main: Node
var free := false          # free play from Options: no reward
var state := 0             # 0 get ready, 1 smash, 2 result
var t := 0.0
var hp := HP
var left := TIME
var hits := 0
var shake := 0.0
var punch := 0.0
var sparks: Array = []
var pops: Array = []
var land := false
var car_rect: TextureRect
var fighter: Control
var gave_credit := false


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	land = size.x > size.y
	car_rect = TextureRect.new()
	car_rect.texture = CARS[_stage()]
	car_rect.size = CAR_SIZE
	car_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	car_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(car_rect)
	fighter = Portrait.new()
	fighter.set_char(main.run.get("player", Settings.vs_char) if not free else Settings.vs_char)
	fighter.size = Vector2(192, 192)
	add_child(fighter)
	_place()
	if state == 2:
		_result_buttons()


func relayout() -> void:
	_build()


func _car_pos() -> Vector2:
	return Vector2(450, 220) if land else Vector2(78, 400)


func _place() -> void:
	var s := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * (shake / 0.12)
	car_rect.position = _car_pos() + s
	var home := Vector2(130, 240) if land else Vector2(24, 660)
	fighter.position = home + Vector2(60.0 * (punch / 0.12), 0)
	fighter.visible = state != 2


func _stage() -> int:
	return clampi(int((1.0 - float(hp) / HP) * 4.999), 0, 4) if hp > 0 else 4


func _spark_burst(n: int, power: float) -> void:
	var c := _car_pos() + CAR_SIZE * Vector2(randf_range(0.2, 0.8), randf_range(0.3, 0.7))
	for i in n:
		var a := randf_range(-PI * 0.9, -PI * 0.1)
		sparks.append({"p": c, "v": Vector2(cos(a), sin(a)) * randf_range(120, 320) * power, "life": randf_range(0.25, 0.6)})


func _hit() -> void:
	hp -= 1
	hits += 1
	punch = 0.12
	shake = 0.12
	_spark_burst(7, 1.0)
	pops.append({"text": ["POW!", "BAM!", "CRASH!", "SMASH!"][randi() % 4], "pos": _car_pos() + Vector2(randf_range(40, 300), -10), "life": 0.5})
	Sfx.play("hit" if hits % 6 == 0 else "lock")
	car_rect.texture = CARS[_stage()]
	if hp <= 0:
		_spark_burst(40, 2.0)
		_finish()


func _input(event: InputEvent) -> void:
	if state != 1:
		return
	var tap: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode != KEY_ESCAPE)
	if tap:
		_hit()


func _finish() -> void:
	if state == 2:
		return
	state = 2
	t = 0.0
	var destroyed := hp <= 0
	if destroyed and not free and main.run.get("credits", 0) < MAX_CREDITS:
		main.run["credits"] = main.run.get("credits", 0) + 1
		gave_credit = true
	Sfx.play("win" if destroyed else "lose")
	_result_buttons()


func _result_buttons() -> void:
	var y := 395.0 if land else 700.0
	var x := 30.0 if land else 90.0
	if free:
		var w := 180.0 if land else 175.0
		UI.button(self, "AGAIN", Rect2(x, y, w, 78), func(): main.show_bonus(true), 24, Style.BTN_PRIMARY, "retry")
		UI.button(self, "BACK", Rect2(x + w + 10, y, w, 78), func(): main.show_title(), 24, Style.BTN_GLASS, "home")
	else:
		UI.button(self, "NEXT FIGHT", Rect2(x, y, 360, 86), func(): main.show_intro(), 28, Style.BTN_PRIMARY, "swords")


func _process(delta: float) -> void:
	t += delta
	shake = maxf(0.0, shake - delta)
	punch = maxf(0.0, punch - delta)
	for s in sparks:
		s["life"] -= delta
		s["v"].y += 700.0 * delta
		s["p"] += s["v"] * delta
	sparks = sparks.filter(func(s): return s["life"] > 0.0)
	for p in pops:
		p["life"] -= delta
		p["pos"].y -= 60.0 * delta
	pops = pops.filter(func(p): return p["life"] > 0.0)
	if state == 0 and t >= 1.8:
		state = 1
		t = 0.0
		Sfx.play("levelup")
	elif state == 1:
		left -= delta
		if left <= 0.0:
			left = 0.0
			_finish()
	_place()
	queue_redraw()


func _draw() -> void:
	Style.draw_bg(self, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	var cx := size.x * 0.5
	var car := _car_pos()
	# road
	draw_rect(Rect2(0, car.y + 170, size.x, size.y - car.y - 170), Color(0.08, 0.07, 0.14, 0.9))
	draw_rect(Rect2(0, car.y + 170, size.x, 4), Color(1, 1, 1, 0.25))
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 62 if land else 90), "BONUS STAGE", 40, Style.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	Style.text(self, Style.caption_font(), Vector2(0, 92 if land else 122), "SMASH THE CAR!  TAP OR PRESS ANY KEY AS FAST AS YOU CAN",
		13, Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	# time and car health
	if state == 1:
		Style.text(self, Style.FONT_DISPLAY, Vector2(0, 190 if land else 250), "%.1f" % left, 64, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	var bar := Rect2(car.x, car.y + CAR_SIZE.y + 40, CAR_SIZE.x, 18)
	draw_style_box(Style.panel_box(Color(0, 0, 0, 0.5), 9, Color(1, 1, 1, 0.3)), bar)
	var frac := float(maxi(hp, 0)) / HP
	if frac > 0.0:
		draw_style_box(Style.panel_box(Color("ff4d6d").lerp(Color("ffd400"), 1.0 - frac), 9), Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)))
	Style.text(self, Style.caption_font(), bar.position + Vector2(0, -8), "CAR HEALTH", 12, Style.MUTED)
	# sparks and pops
	for s in sparks:
		draw_rect(Rect2(s["p"] - Vector2(3, 3), Vector2(6, 6)), Color("ffd400") if s["life"] > 0.2 else Color("ff7a2a"))
	for p in pops:
		Style.text(self, Style.FONT_DISPLAY, p["pos"], p["text"], 26, Color(1, 1, 1, clampf(p["life"] * 3.0, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
	if state == 0:
		var k := minf(t / 0.3, 1.0)
		Style.text(self, Style.FONT_DISPLAY, Vector2(0, 205 if land else 265), "READY?" if t < 1.2 else "SMASH!", int(80 * (0.6 + 0.4 * k)),
			Color("ff5a4a"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 12)
	elif state == 1 and hits < 3:
		Style.text(self, Style.FONT_DISPLAY, Vector2(fighter.position.x + 200, fighter.position.y + 120), "TAP!", 44,
			Color(1, 1, 1, 0.5 + 0.5 * sin(t * 12.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	elif state == 2:
		var card := Rect2(30, 110, 380, 240) if land else Rect2(50, 150, 440, 230)
		draw_style_box(Style.panel_box(Color(0.08, 0.07, 0.2, 0.95), 26, Color(1, 1, 1, 0.14), Color(0.4, 0.3, 1.0, 0.35), 28), card)
		var destroyed := hp <= 0
		Style.text(self, Style.FONT_DISPLAY, card.position + Vector2(0, 66), "DESTROYED!" if destroyed else "TIME UP", 42,
			Color.GOLD if destroyed else Color("ff6f8e"), HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 8)
		Style.text(self, Style.FONT_BOLD, card.position + Vector2(0, 116), "Damage  %d%%     Hits  %d" % [roundi(100.0 * (1.0 - float(maxi(hp, 0)) / HP)), hits],
			22, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
		var line := "Free play" if free else ("+1 CONTINUE!" if gave_credit else ("Continues are full" if destroyed else "No bonus this time"))
		Style.text(self, Style.FONT_SEMI, card.position + Vector2(0, 162), line, 24, Style.CYAN if gave_credit else Style.MUTED,
			HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
		if not free:
			Style.text(self, Style.caption_font(), card.position + Vector2(0, 200), "CONTINUES  %d" % main.run.get("credits", 0), 15,
				Style.MUTED, HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
