extends Control
## Options screen with three tabs: COLORS, SOUND, CONTROLS.
## Added as a child on top of the title screen or the paused game.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const TouchLayout := preload("res://scripts/touch_layout.gd")

const TABS := ["COLORS", "SOUND", "TOUCH", "KEYS"]
const PANEL := Rect2(16, 196, 508, 640)

var on_close: Callable = func(): pass
var on_secret: Callable = Callable()  # set by the title screen: seven quick taps on the title open the bonus game
var _taps := 0
var _last_tap := 0
var tab := 0
var content: Control
var tab_row: Control
var listening: Array = []  # [action, slot] while waiting for a key press


func _ready() -> void:
	size = Vector2(540, 960)
	tab_row = Control.new()
	add_child(tab_row)
	var secret := Button.new()
	secret.flat = true
	secret.position = Vector2(110, 20)
	secret.size = Vector2(320, 92)
	secret.focus_mode = Control.FOCUS_NONE
	secret.pressed.connect(_secret_tap)
	add_child(secret)
	UI.button(self, "BACK", Rect2(130, 862, 280, 76), _close, 28, Style.BTN_GLASS, "left")
	_build_tabs()
	_build_tab()


func _secret_tap() -> void:
	var now := Time.get_ticks_msec()
	_taps = 1 if now - _last_tap > 1200 else _taps + 1
	_last_tap = now
	if _taps >= 7 and on_secret.is_valid():
		_taps = 0
		Sfx.play("levelup")
		on_secret.call()
	elif _taps >= 3 and on_secret.is_valid():
		Sfx.play("click")


func _close() -> void:
	Sfx.stop_preview()
	Sfx.refresh_music_style()
	Settings.save()
	on_close.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


# ---------------------------------------------------------------- building blocks

func _build_tabs() -> void:
	for c in tab_row.get_children():
		c.queue_free()
	var w := (508.0 - 8.0 * (TABS.size() - 1)) / TABS.size()
	for i in TABS.size():
		var scheme := Style.BTN_PRIMARY if i == tab else Style.BTN_GLASS
		var idx := i
		UI.button(tab_row, TABS[i], Rect2(16 + i * (w + 8), 124, w, 56),
			func(): _set_tab(idx), 18, scheme)


func _set_tab(i: int) -> void:
	tab = i
	_build_tabs.call_deferred()
	_build_tab.call_deferred()


func _build_tab() -> void:
	if content:
		content.queue_free()
	content = Control.new()
	content.size = size
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE  # let the tab buttons underneath get clicks
	add_child(content)
	match tab:
		0: _build_colors()
		1: _build_sound()
		2: _build_controls()
		3: _build_keys()
	queue_redraw()


func _caption(text: String, y: float) -> void:
	UI.label(content, text, Rect2(32, y, 476, 26), 16, Style.MUTED, HORIZONTAL_ALIGNMENT_LEFT,
		Style.caption_font())


## Segmented choice buttons across the panel width. `cb` receives the chosen index.
func _segment(y: float, labels: Array, selected: int, cb: Callable) -> void:
	var n := labels.size()
	var gap := 8.0
	var w := (476.0 - gap * (n - 1)) / n
	for i in n:
		var idx := i
		var scheme := Style.BTN_PRIMARY if i == selected else Style.BTN_GLASS
		UI.button(content, labels[i], Rect2(32 + i * (w + gap), y, w, 60),
			func():
				cb.call(idx)
				_rebuild_soon(), 20, scheme)


func _rebuild_soon() -> void:
	_build_tab.call_deferred()


## Selectable card: a flat button with a highlighted border when chosen.
func _card(rect: Rect2, selected: bool, cb: Callable) -> Button:
	var b := UI.button(content, "", rect, func():
		Sfx.play("click")
		cb.call()
		_rebuild_soon())
	var border := Style.CYAN if selected else Color(1, 1, 1, 0.14)
	var glow := Color(0.2, 0.8, 1, 0.4) if selected else Color(0, 0, 0, 0)
	var bg := Color(1, 1, 1, 0.1) if selected else Color(1, 1, 1, 0.05)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, Style.panel_box(bg, 14, border, glow, 10 if selected else 0))
	b.clip_contents = true
	return b


# ---------------------------------------------------------------- COLORS

func _build_colors() -> void:
	_caption("BLOCK COLORS", 214)
	var y := 246.0
	for t in Style.theme_list():
		var id: String = t["id"]
		var card := _card(Rect2(32, y, 476, 80), Settings.theme == id, func(): Settings.theme = id)
		UI.label(card, t["name"], Rect2(16, 0, 150, 80), 20, Style.TEXT, HORIZONTAL_ALIGNMENT_LEFT,
			Style.FONT_DISPLAY)
		for k in 7:
			var tr := TextureRect.new()
			tr.texture = Style.block_texture(id, k)
			tr.position = Vector2(166 + k * 43, 20)
			tr.size = Vector2(40, 40)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(tr)
		y += 90.0
	_caption("BACKGROUND", y + 6)
	y += 38.0
	var bgs := Style.background_list()
	var gap := 12.0
	var w := (476.0 - gap * (bgs.size() - 1)) / bgs.size()
	for i in bgs.size():
		var id: String = bgs[i]["id"]
		var card := _card(Rect2(32 + i * (w + gap), y, w, 130), Settings.background == id,
			func(): Settings.background = id)
		var tr := TextureRect.new()
		tr.texture = load("res://assets/bg_%s.jpg" % id)
		tr.position = Vector2(3, 3)
		tr.size = Vector2(w - 6, 124)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tr)
		var l := UI.label(card, bgs[i]["name"], Rect2(0, 92, w, 34), 18)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 8)


# ---------------------------------------------------------------- SOUND

func _build_sound() -> void:
	_audio_row("SOUND EFFECTS", 204, Settings.sound_on, Settings.sound_vol,
		func(on): Sfx.set_sound(on),
		func(v): Settings.sound_vol = v,
		func(): Sfx.play("clear2"))
	_caption("EFFECT STYLE", 358)
	_segment(384, ["ARCADE", "SOFT & RELAXED"], 1 if Settings.sfx_style == "soft" else 0,
		func(i):
			Settings.sfx_style = "soft" if i == 1 else "arcade"
			Sfx.play("clear2"))
	_audio_row("MUSIC", 462, Settings.music_on, Settings.music_vol,
		func(on): Sfx.set_music(on),
		func(v):
			Settings.music_vol = v
			Sfx.apply_volumes(),
		func(): Sfx.preview_music(Settings.music_style))
	_caption("MUSIC STYLE  (tap arrows to preview)", 620)
	var styles := Style.music_styles()
	var idx := 0
	for i in styles.size():
		if styles[i]["id"] == Settings.music_style:
			idx = i
	UI.icon_button(content, "left", Rect2(32, 648, 72, 72), func(): _cycle_music(-1, styles, idx))
	UI.icon_button(content, "right", Rect2(436, 648, 72, 72), func(): _cycle_music(1, styles, idx))
	UI.label(content, styles[idx]["name"], Rect2(112, 648, 316, 40), 22, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_DISPLAY)
	UI.label(content, styles[idx]["desc"], Rect2(112, 686, 316, 34), 16, Style.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_SEMI)
	UI.label(content, "%d / %d" % [idx + 1, styles.size()], Rect2(112, 726, 316, 28), 15, Style.CYAN,
		HORIZONTAL_ALIGNMENT_CENTER, Style.caption_font())


func _cycle_music(d: int, styles: Array, idx: int) -> void:
	var i := (idx + d + styles.size()) % styles.size()
	Settings.music_style = styles[i]["id"]
	Sfx.preview_music(Settings.music_style)
	_rebuild_soon()


func _audio_row(title: String, y: float, on: bool, vol: float, on_toggle: Callable,
		on_volume: Callable, on_release: Callable) -> void:
	UI.label(content, title, Rect2(32, y, 300, 56), 24, Style.TEXT, HORIZONTAL_ALIGNMENT_LEFT,
		Style.FONT_DISPLAY)
	UI.button(content, "ON" if on else "OFF", Rect2(388, y, 120, 56),
		func():
			on_toggle.call(not on)
			_rebuild_soon(), 22, Style.BTN_PRIMARY if on else Style.BTN_GLASS)
	UI.label(content, "VOLUME", Rect2(32, y + 66, 200, 32), 16, Style.MUTED, HORIZONTAL_ALIGNMENT_LEFT,
		Style.caption_font())
	var pct := UI.label(content, "%d%%" % roundi(vol * 100.0), Rect2(408, y + 66, 100, 32), 22,
		Style.CYAN, HORIZONTAL_ALIGNMENT_RIGHT, Style.FONT_DISPLAY)
	var s := _slider(Rect2(32, y + 100, 476, 48), vol)
	s.modulate.a = 1.0 if on else 0.5
	s.value_changed.connect(func(v):
		on_volume.call(v)
		pct.text = "%d%%" % roundi(v * 100.0))
	s.drag_ended.connect(func(_changed): on_release.call())


func _slider(rect: Rect2, value: float) -> HSlider:
	var s := HSlider.new()
	s.position = rect.position
	s.size = rect.size
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.focus_mode = Control.FOCUS_NONE
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
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	for k in ["grabber", "grabber_highlight", "grabber_disabled"]:
		s.add_theme_icon_override(k, Style.KNOB)
	content.add_child(s)
	return s


# ---------------------------------------------------------------- CONTROLS

func _build_controls() -> void:
	_caption("TOUCH LAYOUT", 214)
	_segment(242, ["GAMEPAD", "CLASSIC", "THUMBS"], TouchLayout.LAYOUTS.find(Settings.layout),
		func(i): Settings.layout = TouchLayout.LAYOUTS[i])
	_caption("HANDS  (move buttons on the left or right)", 318)
	_segment(346, ["MOVE LEFT", "MOVE RIGHT"], 1 if Settings.swap_sides else 0,
		func(i): Settings.swap_sides = i == 1)
	_caption("MOVE SPEED  (hold to repeat)", 422)
	_segment(450, ["SLOW", "NORMAL", "FAST"], Settings.move_speed,
		func(i): Settings.move_speed = i)
	_caption("GHOST PIECE", 526)
	_segment(554, ["ON", "OFF"], 0 if Settings.ghost else 1, func(i): Settings.ghost = i == 0)
	_caption("PREVIEW", 634)


# ---------------------------------------------------------------- KEYS

func _build_keys() -> void:
	_caption("CONTROLS SHOWN IN GAME", 214)
	_segment(242, ["AUTO", "TOUCH", "KEYBOARD"], ["auto", "touch", "keys"].find(Settings.control_mode),
		func(i): Settings.control_mode = ["auto", "touch", "keys"][i])
	_caption("KEYBOARD  (tap a slot, press a key;  DEL clears)", 318)
	var y := 350.0
	for a in Settings.ACTIONS:
		var act: String = a[0]
		UI.label(content, a[1], Rect2(32, y, 150, 42), 17, Style.TEXT, HORIZONTAL_ALIGNMENT_LEFT, Style.FONT_BOLD)
		var slots: Array = Settings.key_slots(act)
		for i in Settings.KEY_SLOTS:
			var slot := i
			var waiting := listening == [act, slot]
			UI.button(content, "PRESS..." if waiting else Settings.key_name(slots[i]),
				Rect2(184 + i * 109, y, 101, 42),
				func():
					listening = [act, slot]
					_rebuild_soon(), 16, Style.BTN_ACCENT if waiting else Style.BTN_GLASS)
		y += 50.0
	UI.button(content, "RESET KEYS", Rect2(32, y + 8, 476, 56), func():
		listening = []
		Settings.reset_keys()
		_rebuild_soon(), 20, Style.BTN_GLASS)


func _input(event: InputEvent) -> void:
	if listening.is_empty() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	var code: int = event.physical_keycode
	if code == KEY_BACKSPACE or code == KEY_DELETE:
		Settings.set_key(listening[0], listening[1], 0)
	elif code != KEY_ESCAPE:  # Esc only cancels
		Settings.set_key(listening[0], listening[1], code)
	listening = []
	_rebuild_soon()


func _draw() -> void:
	draw_texture_rect(Style.bg_texture(), Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	Style.draw_icon(self, "gear", Vector2(172, 66), 40, Style.TEXT)
	Style.text(self, Style.FONT_DISPLAY, Vector2(0, 82), "OPTIONS", 38, Style.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, size.x + 62, 8)
	draw_style_box(Style.panel_box(Style.PANEL, 24, Style.PANEL_BORDER, Color(0.3, 0.2, 0.9, 0.25), 24), PANEL)
	if tab == 2:
		_draw_pad_preview()


## A scaled-down copy of the on-screen buttons, in the current layout.
func _draw_pad_preview() -> void:
	var sc := 0.5
	var origin := Vector2(540.0 * (1.0 - sc) * 0.5, 666.0)
	var frame := Rect2(origin - Vector2(8, 6), Vector2(540 * sc + 16, 212 * sc + 12))
	draw_style_box(Style.panel_box(Color(0, 0, 0, 0.35), 14, Color(1, 1, 1, 0.12)), frame)
	for b in TouchLayout.buttons(Settings.layout, Settings.swap_sides):
		var r: Rect2 = b["rect"]
		var pr := Rect2(origin + (r.position - Vector2(0, 732)) * sc, r.size * sc)
		draw_style_box(Style.button_box(b["scheme"], false, b["radius"] / 2), pr.grow(-1))
		Style.draw_icon(self, b["icon"], pr.get_center(), 26.0)
