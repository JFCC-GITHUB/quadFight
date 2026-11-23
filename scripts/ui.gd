extends RefCounted
## Small helpers for building UI from code.


static func label(parent: Node, text: String, rect: Rect2, font_size: int = 24,
		color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func _box(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(14)
	return s


static func button(parent: Node, text: String, rect: Rect2, callback: Callable,
		font_size: int = 28, color: Color = Color("2b3a6b")) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", _box(color))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", _box(color.lightened(0.3)))
	b.pressed.connect(func(): Sfx.play("click"))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


## Two small buttons that toggle sound effects / music.
static func audio_toggles(parent: Node, y: float) -> void:
	var s := button(parent, "", Rect2(120, y, 145, 54), func(): pass, 18)
	var m := button(parent, "", Rect2(275, y, 145, 54), func(): pass, 18)
	var refresh := func():
		s.text = "SOUND: %s" % ("ON" if Sfx.sound_on else "OFF")
		m.text = "MUSIC: %s" % ("ON" if Sfx.music_on else "OFF")
	s.pressed.connect(func():
		Sfx.set_sound(not Sfx.sound_on)
		refresh.call())
	m.pressed.connect(func():
		Sfx.set_music(not Sfx.music_on)
		refresh.call())
	refresh.call()
