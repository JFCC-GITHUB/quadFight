extends Node
## Root: sets up input actions and switches between screens.

const TitleScreen := preload("res://scripts/title.gd")
const GameScreen := preload("res://scripts/game.gd")
const BoardScreen := preload("res://scripts/leaderboard.gd")
const VsSelectScreen := preload("res://scripts/vs_select.gd")
const CharSelectScreen := preload("res://scripts/char_select.gd")

const PORTRAIT := Vector2(540, 960)
const LANDSCAPE := Vector2(960, 540)

var current: Control
var landscape_ok := false  # the current screen has a landscape layout


func _ready() -> void:
	_setup_input()
	get_window().size_changed.connect(_on_resized)
	show_title()


func show_title() -> void:
	_swap(TitleScreen.new(), true)


func show_game(vs: bool = false, cpu_level: int = 3) -> void:
	var g := GameScreen.new()
	g.vs = vs
	g.cpu_level = cpu_level
	g.char_id = Settings.vs_char
	_swap(g, true)


func show_vs_select() -> void:
	_swap(VsSelectScreen.new(), true)


func show_char_select(cpu_level: int) -> void:
	var s := CharSelectScreen.new()
	s.cpu_level = cpu_level
	_swap(s, true)


func show_leaderboard() -> void:
	_swap(BoardScreen.new())


## Logical size: landscape only for screens that support it, and only while the window is wider than tall.
func _screen_size() -> Vector2:
	var w := get_window().size
	return LANDSCAPE if landscape_ok and w.x > w.y else PORTRAIT


func _on_resized() -> void:
	_apply_orientation.call_deferred()  # the window finishes its own resize first


func _apply_orientation() -> void:
	if current == null or Vector2i(_screen_size()) == get_window().content_scale_size:
		return
	get_window().content_scale_size = Vector2i(_screen_size())
	current.size = _screen_size()
	if current.has_method("relayout"):
		current.relayout()


func _swap(screen: Control, allow_landscape: bool = false) -> void:
	if current:
		current.queue_free()
	current = screen
	landscape_ok = allow_landscape
	get_window().content_scale_size = Vector2i(_screen_size())
	screen.set("main", self)
	screen.size = _screen_size()
	add_child(screen)
	screen.modulate.a = 0.0
	screen.create_tween().tween_property(screen, "modulate:a", 1.0, 0.2)


func _setup_input() -> void:
	_action("move_left", [], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("soft_drop", [], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("hard_drop", [], [JOY_BUTTON_DPAD_UP, JOY_BUTTON_Y], [])
	_action("rotate_cw", [], [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER], [])
	_action("rotate_ccw", [], [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER], [])
	_action("hold", [], [JOY_BUTTON_X], [])
	_action("pause", [], [JOY_BUTTON_START], [])
	_action("confirm", [KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_A, JOY_BUTTON_START], [])
	Settings.apply_keys()  # the rebindable keyboard keys (Options -> KEYS)


func _action(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	InputMap.add_action(action, 0.5)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = a[0]
		m.axis_value = a[1]
		InputMap.action_add_event(action, m)
