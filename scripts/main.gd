extends Node
## Root: sets up input actions and switches between screens.

const TitleScreen := preload("res://scripts/title.gd")
const GameScreen := preload("res://scripts/game.gd")
const BoardScreen := preload("res://scripts/leaderboard.gd")
const VsSelectScreen := preload("res://scripts/vs_select.gd")

const SCREEN_SIZE := Vector2(540, 960)

var current: Control


func _ready() -> void:
	_setup_input()
	show_title()


func show_title() -> void:
	_swap(TitleScreen.new())


func show_game(vs: bool = false, cpu_level: int = 3) -> void:
	var g := GameScreen.new()
	g.vs = vs
	g.cpu_level = cpu_level
	_swap(g)


func show_vs_select() -> void:
	_swap(VsSelectScreen.new())


func show_leaderboard() -> void:
	_swap(BoardScreen.new())


func _swap(screen: Control) -> void:
	if current:
		current.queue_free()
	current = screen
	screen.set("main", self)
	screen.size = SCREEN_SIZE
	add_child(screen)
	screen.modulate.a = 0.0
	screen.create_tween().tween_property(screen, "modulate:a", 1.0, 0.2)


func _setup_input() -> void:
	_action("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("soft_drop", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("hard_drop", [KEY_SPACE], [JOY_BUTTON_DPAD_UP, JOY_BUTTON_Y], [])
	_action("rotate_cw", [KEY_UP, KEY_X, KEY_W], [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER], [])
	_action("rotate_ccw", [KEY_Z, KEY_CTRL], [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER], [])
	_action("hold", [KEY_C, KEY_SHIFT], [JOY_BUTTON_X], [])
	_action("pause", [KEY_P, KEY_ESCAPE], [JOY_BUTTON_START], [])
	_action("confirm", [KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_A, JOY_BUTTON_START], [])


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
