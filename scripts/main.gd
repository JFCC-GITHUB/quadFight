extends Node
## Root: sets up input actions and switches between screens.

const TitleScreen := preload("res://scripts/title.gd")
const GameScreen := preload("res://scripts/game.gd")
const BoardScreen := preload("res://scripts/leaderboard.gd")
const VsSelectScreen := preload("res://scripts/vs_select.gd")
const CharSelectScreen := preload("res://scripts/char_select.gd")
const IntroScreen := preload("res://scripts/intro.gd")
const Characters := preload("res://scripts/characters.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")

const PORTRAIT := Vector2(540, 960)
const LANDSCAPE := Vector2(960, 540)

var current: Control
var landscape_ok := false  # the current screen has a landscape layout
## The VS run in progress. mode "ladder": one opponent, the level keeps rising.
## mode "tournament": every other fighter once, in random order, one level harder each time.
var run := {}

## Tournament difficulty: the CPU level range, spread evenly over the 5 fights.
const TOUR_NAMES := ["EASY", "NORMAL", "HARD"]
const TOUR_RANGES := [[1, 10], [6, 15], [11, 20]]


static func tour_levels(diff: int, fights: int = 5) -> Array:
	var out: Array = []
	var r: Array = TOUR_RANGES[diff]
	for i in fights:
		out.append(roundi(lerpf(r[0], r[1], float(i) / maxf(fights - 1, 1))))
	return out


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


func show_vs_select(mode: String = "ladder") -> void:
	var s := VsSelectScreen.new()
	s.mode = mode
	_swap(s, true)


## step 0: pick your fighter; step 1 (ladder only): pick the opponent or random.
func show_char_select(level: int, mode: String, step: int = 0) -> void:
	var s := CharSelectScreen.new()
	s.level = level
	s.mode = mode
	s.step = step
	_swap(s, true)


## Fighters are chosen: set up the run and show the "versus" intro.
## `level` is the starting CPU level for the ladder, or the difficulty index (0-2) for the tournament.
func start_run(mode: String, level: int) -> void:
	var player: String = Settings.vs_char
	run = {"mode": mode, "player": player, "level": level, "base": level, "round": 0, "order": [], "cpu": ""}
	if mode == "tournament":
		var ids: Array = []
		for d in Characters.LIST:
			if d["id"] != player:
				ids.append(d["id"])
		ids.shuffle()
		run["order"] = ids
		run["cpu"] = ids[0]
		run["levels"] = tour_levels(level, ids.size())
		run["level"] = run["levels"][0]
	else:
		run["cpu"] = Characters.random_other(player) if Settings.vs_cpu_char == "random" else Settings.vs_cpu_char
	show_intro()


func show_intro(champion: bool = false) -> void:
	var s := IntroScreen.new()
	s.champion = champion
	_swap(s, true)


## After a win: the next tournament fighter, or the next ladder level against the same opponent.
func next_fight() -> void:
	if run["mode"] == "tournament":
		run["round"] += 1
		if run["round"] >= run["order"].size():
			Settings.tour_clears += 1
			Settings.save()
			show_intro(true)
			return
		run["cpu"] = run["order"][run["round"]]
		run["level"] = run["levels"][run["round"]]
	else:
		run["level"] = mini(run["level"] + 1, CpuPlayer.MAX_LEVEL)
		Settings.vs_level = run["level"]
		Settings.save()
	show_intro()


func show_match() -> void:
	var g := GameScreen.new()
	g.vs = true
	g.cpu_level = run["level"]
	g.char_id = run["player"]
	g.cpu_char = run["cpu"]
	g.mode = run["mode"]
	g.round_no = run["round"] + 1
	g.round_total = run["order"].size()
	_swap(g, true)


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
