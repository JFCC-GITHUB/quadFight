extends RefCounted
## Full-screen toggle. iPhone Safari has no Fullscreen API: there the button explains Add to Home Screen instead.

const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")


static func supported() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)", true))
	return true


static func active() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


## Call from a button press (browsers only allow full screen from a user gesture).
static func toggle(host: Control) -> void:
	if not supported():
		_toast(host, "iPhone: tap Share, then Add to Home Screen, to play full screen")
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if active() else DisplayServer.WINDOW_MODE_FULLSCREEN)


static func _toast(host: Control, text: String) -> void:
	var w := minf(host.size.x - 40.0, 480.0)
	var p := Panel.new()
	p.position = Vector2((host.size.x - w) * 0.5, host.size.y - 150.0)
	p.size = Vector2(w, 84)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", Style.panel_box(Color(0.08, 0.07, 0.2, 0.96), 20, Color(1, 1, 1, 0.2)))
	host.add_child(p)
	var l := UI.label(p, text, Rect2(14, 8, w - 28, 68), 17, Style.TEXT, HORIZONTAL_ALIGNMENT_CENTER, Style.FONT_SEMI)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var t := p.create_tween()
	t.tween_interval(3.5)
	t.tween_property(p, "modulate:a", 0.0, 0.4)
	t.tween_callback(p.queue_free)
