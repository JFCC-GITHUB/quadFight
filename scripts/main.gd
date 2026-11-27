extends Node
## Root: sets up input actions and switches between screens.

const TitleScreen := preload("res://scripts/title.gd")
const GameScreen := preload("res://scripts/game.gd")
const BoardScreen := preload("res://scripts/leaderboard.gd")
const VsSelectScreen := preload("res://scripts/vs_select.gd")
const CharSelectScreen := preload("res://scripts/char_select.gd")
const IntroScreen := preload("res://scripts/intro.gd")
const BonusScreen := preload("res://scripts/bonus.gd")
const SummaryScreen := preload("res://scripts/summary.gd")
const Skill := preload("res://scripts/skill.gd")
const Characters := preload("res://scripts/characters.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")

const PORTRAIT := Vector2(540, 960)
const LANDSCAPE := Vector2(960, 540)

var current: Control
var landscape_ok := false  # the current screen has a landscape layout
var landscape_force := false  # 2-player versus: always the wide layout, even in a tall window
## The VS run in progress. mode "ladder": one opponent, the level keeps rising.
## mode "tournament": TOUR_FIGHTS random other fighters, one level harder each time, then your dark self.
var run := {}
const START_CREDITS := 3   # tournament continues
const TOUR_FIGHTS := 5     # random opponents before the dark boss
const BONUS_AFTER := 3     # the car-smashing bonus stage comes after this many tournament fights

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
	run = {"mode": mode, "player": player, "level": level, "base": level, "round": 0, "order": [], "cpu": "", "credits": START_CREDITS,
		"log": [], "won": false, "used": 0, "sk": Skill.empty()}
	if mode == "tournament":
		var ids: Array = []
		for d in Characters.LIST:
			if d["id"] != player:
				ids.append(d["id"])
		ids.shuffle()
		ids = ids.slice(0, TOUR_FIGHTS)
		ids.append(Characters.DARK + player)  # the last fight: a dark version of yourself
		run["order"] = ids
		run["cpu"] = ids[0]
		var lv := tour_levels(level, ids.size() - 1)
		lv.append(lv[-1])  # the dark self is as strong as the last fight (a level jump also turns on the 2-piece lookahead at Lv 11)
		run["levels"] = lv
		run["level"] = lv[0]
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
			run["won"] = true
			show_summary()
			return
		run["cpu"] = run["order"][run["round"]]
		run["level"] = run["levels"][run["round"]]
		if run["round"] == BONUS_AFTER:
			show_bonus()
			return
	else:
		run["level"] = mini(run["level"] + 1, CpuPlayer.MAX_LEVEL)
		Settings.vs_level = run["level"]
		Settings.save()
	show_intro()


## The run summary: every fight of the tournament, win or lose, plus totals.
func show_summary() -> void:
	_swap(SummaryScreen.new(), true)


func show_bonus(free: bool = false) -> void:
	var s := BonusScreen.new()
	s.free = free
	_swap(s, true)


## Tournament: spend a continue and fight the same opponent again.
func continue_fight() -> void:
	run["credits"] -= 1
	run["used"] += 1
	show_match()


func show_match() -> void:
	var g := GameScreen.new()
	g.vs = true
	g.cpu_level = run["level"]
	g.char_id = run["player"]
	g.cpu_char = run["cpu"]
	g.mode = run["mode"]
	g.round_no = run["round"] + 1
	g.round_total = run["order"].size()
	g.two_p = run["mode"] == "versus"
	_swap(g, true, g.two_p)


func show_leaderboard() -> void:
	_swap(BoardScreen.new())


## Logical size: landscape only for screens that support it, and only while the window is wider than tall.
func _screen_size() -> Vector2:
	var w := get_window().size
	return LANDSCAPE if landscape_ok and (w.x > w.y or landscape_force) else PORTRAIT


func _on_resized() -> void:
	_apply_orientation.call_deferred()  # the window finishes its own resize first


func _apply_orientation() -> void:
	if current == null or Vector2i(_screen_size()) == get_window().content_scale_size:
		return
	get_window().content_scale_size = Vector2i(_screen_size())
	current.size = _screen_size()
	if current.has_method("relayout"):
		current.relayout()


func _swap(screen: Control, allow_landscape: bool = false, force_landscape: bool = false) -> void:
	if current:
		current.queue_free()
	current = screen
	landscape_ok = allow_landscape
	landscape_force = force_landscape
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
	# 2 players on one computer: fixed key sets (no Ctrl / Alt / Tab: browser shortcuts), pad 1 and pad 2
	for pl in [["p1_", P1_KEYS, 0], ["p2_", P2_KEYS, 1]]:
		for a in pl[1]:
			_action(pl[0] + a, pl[1][a], PAD[a], PAD_AXES.get(a, []), pl[2])
	Settings.apply_keys()  # the rebindable keyboard keys (Options -> KEYS)  # the rebindable keyboard keys (Options -> KEYS)


const P1_KEYS := {"move_left": [KEY_A], "move_right": [KEY_D], "soft_drop": [KEY_S], "rotate_cw": [KEY_W],
	"rotate_ccw": [KEY_Q], "hard_drop": [KEY_SPACE], "hold": [KEY_E]}
const P2_KEYS := {"move_left": [KEY_LEFT], "move_right": [KEY_RIGHT], "soft_drop": [KEY_DOWN], "rotate_cw": [KEY_UP],
	"rotate_ccw": [KEY_PERIOD, KEY_KP_1], "hard_drop": [KEY_SLASH, KEY_KP_0], "hold": [KEY_COMMA, KEY_KP_2]}
const PAD := {"move_left": [JOY_BUTTON_DPAD_LEFT], "move_right": [JOY_BUTTON_DPAD_RIGHT], "soft_drop": [JOY_BUTTON_DPAD_DOWN],
	"hard_drop": [JOY_BUTTON_DPAD_UP, JOY_BUTTON_Y], "rotate_cw": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER],
	"rotate_ccw": [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER], "hold": [JOY_BUTTON_X]}
const PAD_AXES := {"move_left": [[JOY_AXIS_LEFT_X, -1.0]], "move_right": [[JOY_AXIS_LEFT_X, 1.0]], "soft_drop": [[JOY_AXIS_LEFT_Y, 1.0]]}


func _action(action: String, keys: Array, buttons: Array, axes: Array, device: int = -1) -> void:
	InputMap.add_action(action, 0.5)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		j.device = device
		InputMap.action_add_event(action, j)
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = a[0]
		m.axis_value = a[1]
		m.device = device
		InputMap.action_add_event(action, m)
