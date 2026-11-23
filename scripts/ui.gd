extends RefCounted
## Helpers for building UI nodes from code.

const Style := preload("res://scripts/style.gd")


static func label(parent: Node, text: String, rect: Rect2, font_size: int = 24,
		color: Color = Style.TEXT, align: int = HORIZONTAL_ALIGNMENT_CENTER,
		font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font if font else Style.FONT_BOLD)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, rect: Rect2, callback: Callable,
		font_size: int = 28, scheme: Array = Style.BTN_GLASS, icon: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Style.FONT_DISPLAY)
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, Style.TEXT)
	b.add_theme_color_override("icon_normal_color", Style.TEXT)
	b.add_theme_color_override("icon_pressed_color", Style.TEXT)
	b.add_theme_color_override("icon_hover_color", Style.TEXT)
	b.add_theme_stylebox_override("normal", Style.button_box(scheme, false))
	b.add_theme_stylebox_override("hover", Style.button_box(scheme, false))
	b.add_theme_stylebox_override("pressed", Style.button_box(scheme, true))
	b.add_theme_stylebox_override("hover_pressed", Style.button_box(scheme, true))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if icon != "" and text != "":
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			var box: StyleBoxFlat = b.get_theme_stylebox(st)
			box.content_margin_left = clampf(rect.size.x * 0.08, 12, 28)
			box.content_margin_right = box.content_margin_left
	if icon != "":
		b.icon = Style.ICONS[icon]
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", int(font_size * 1.15))
		b.add_theme_constant_override("h_separation", 12)
	b.pressed.connect(func(): Sfx.play("click"))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


## Square icon-only button.
static func icon_button(parent: Node, icon: String, rect: Rect2, callback: Callable,
		scheme: Array = Style.BTN_GLASS) -> Button:
	var b := button(parent, "", rect, callback, 20, scheme, icon)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", int(rect.size.x * 0.5))
	return b


## A floating card panel; children are positioned relative to it.
static func card(parent: Node, rect: Rect2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.pivot_offset = rect.size * 0.5
	p.add_theme_stylebox_override("panel", Style.panel_box(Color(0.08, 0.07, 0.2, 0.94), 26,
		Color(1, 1, 1, 0.14), Color(0.4, 0.3, 1.0, 0.35), 28))
	parent.add_child(p)
	return p


## Pop-in animation for a card / overlay.
static func pop_in(node: Control) -> void:
	node.scale = Vector2(0.88, 0.88)
	node.modulate.a = 0.0
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "modulate:a", 1.0, 0.18)


## Two round icon buttons toggling sound effects / music, centred at x.
static func audio_toggles(parent: Node, center_x: float, y: float, size: float = 64.0) -> void:
	var s := icon_button(parent, "sound_on", Rect2(center_x - size - 8, y, size, size), func(): pass)
	var m := icon_button(parent, "music_on", Rect2(center_x + 8, y, size, size), func(): pass)
	var refresh := func():
		s.icon = Style.ICONS["sound_on" if Sfx.sound_on else "sound_off"]
		m.icon = Style.ICONS["music_on" if Sfx.music_on else "music_off"]
		s.modulate.a = 1.0 if Sfx.sound_on else 0.55
		m.modulate.a = 1.0 if Sfx.music_on else 0.55
	s.pressed.connect(func():
		Sfx.set_sound(not Sfx.sound_on)
		refresh.call())
	m.pressed.connect(func():
		Sfx.set_music(not Sfx.music_on)
		refresh.call())
	refresh.call()
