extends Node
## User options (autoload "Settings"), persisted to user://settings.cfg.

const PATH := "user://settings.cfg"
const DAS := [0.17, 0.13, 0.09]  # delay before auto-repeat: slow / normal / fast
const ARR := [0.05, 0.035, 0.02]  # auto-repeat interval
const KEY_SLOTS := 3
## Rebindable keyboard actions: [action, label].
const ACTIONS := [["move_left", "MOVE LEFT"], ["move_right", "MOVE RIGHT"], ["soft_drop", "SOFT DROP"],
	["hard_drop", "HARD DROP"], ["rotate_cw", "ROTATE"], ["rotate_ccw", "ROTATE BACK"], ["hold", "HOLD"],
	["pause", "PAUSE"]]
const DEFAULT_KEYS := {
	"move_left": [KEY_LEFT, KEY_A, 0], "move_right": [KEY_RIGHT, KEY_D, 0], "soft_drop": [KEY_DOWN, KEY_S, 0],
	"hard_drop": [KEY_SPACE, 0, 0], "rotate_cw": [KEY_UP, KEY_X, KEY_W], "rotate_ccw": [KEY_Z, KEY_CTRL, 0],
	"hold": [KEY_C, KEY_SHIFT, 0], "pause": [KEY_P, KEY_ESCAPE, 0],
}

# Audio
var sound_on := true
var music_on := true
var sound_vol := 0.8
var music_vol := 0.7
var music_style := "robot"  # see assets/music/styles.json
var sfx_style := "arcade"   # "arcade" | "soft"
# Look
var theme := "candy"
var background := "nebula"
# Controls
var layout := "snes"  # "snes" | "classic" | "thumbs"
var swap_sides := false
var move_speed := 1      # 0 slow, 1 normal, 2 fast
var ghost := true
var control_mode := "auto"  # "auto" | "touch" | "keys": on-screen buttons or keyboard hints
var keys := {}  # action -> [3 physical keycodes] overriding DEFAULT_KEYS
# VS CPU
var vs_level := 3
var vs_char := "bastion"
var vs_record := {}  # cpu level (int) -> [wins, losses]


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sound_on = cfg.get_value("audio", "sound", sound_on)
	music_on = cfg.get_value("audio", "music", music_on)
	sound_vol = clampf(cfg.get_value("audio", "sound_vol", sound_vol), 0.0, 1.0)
	music_vol = clampf(cfg.get_value("audio", "music_vol", music_vol), 0.0, 1.0)
	music_style = cfg.get_value("audio", "music_style", music_style)
	sfx_style = cfg.get_value("audio", "sfx_style", sfx_style)
	theme = cfg.get_value("look", "theme", theme)
	background = cfg.get_value("look", "background", background)
	control_mode = cfg.get_value("controls", "mode", control_mode)
	for a in ACTIONS:
		if cfg.has_section_key("keys", a[0]):
			var v = cfg.get_value("keys", a[0])
			if v is Array and v.size() == KEY_SLOTS:
				keys[a[0]] = v
	layout = cfg.get_value("controls", "layout", layout)
	swap_sides = cfg.get_value("controls", "swap_sides", swap_sides)
	move_speed = clampi(cfg.get_value("controls", "move_speed", move_speed), 0, 2)
	ghost = cfg.get_value("controls", "ghost", ghost)
	vs_level = clampi(cfg.get_value("vs", "level", vs_level), 1, 10)
	vs_char = cfg.get_value("vs", "char", vs_char)
	for lv in range(1, 11):
		vs_record[lv] = [int(cfg.get_value("vs", "w%d" % lv, 0)), int(cfg.get_value("vs", "l%d" % lv, 0))]


## On-screen buttons (phones, tablets) or keyboard hints (computers); the user can force either.
func use_touch() -> bool:
	if control_mode != "auto":
		return control_mode == "touch"
	if OS.has_feature("web"):  # the primary pointer is a finger (phones, tablets), not a mouse or trackpad
		return bool(JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches", true))
	return OS.has_feature("mobile")


func key_slots(action: String) -> Array:
	return keys.get(action, DEFAULT_KEYS[action])


static func key_name(code: int) -> String:
	return "-" if code == 0 else OS.get_keycode_string(code).to_upper()


## Puts the current key bindings into the InputMap (gamepad bindings are left alone).
func apply_keys() -> void:
	for a in ACTIONS:
		var act: String = a[0]
		if not InputMap.has_action(act):
			continue
		for e in InputMap.action_get_events(act):
			if e is InputEventKey:
				InputMap.action_erase_event(act, e)
		for code in key_slots(act):
			if code != 0:
				var ev := InputEventKey.new()
				ev.physical_keycode = code
				InputMap.action_add_event(act, ev)


## Binds `code` (0 = clear) to a slot; the key is taken away from any other slot that used it.
func set_key(action: String, slot: int, code: int) -> void:
	for a in ACTIONS:
		var slots: Array = key_slots(a[0]).duplicate()
		for i in KEY_SLOTS:
			if code != 0 and slots[i] == code:
				slots[i] = 0
		if a[0] == action:
			slots[slot] = code
		keys[a[0]] = slots
	apply_keys()
	save()


func reset_keys() -> void:
	keys.clear()
	apply_keys()
	save()


func record(level: int) -> Array:
	if not vs_record.has(level):
		vs_record[level] = [0, 0]
	return vs_record[level]


func add_vs_result(level: int, won: bool) -> void:
	record(level)[0 if won else 1] += 1
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound", sound_on)
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sound_vol", sound_vol)
	cfg.set_value("audio", "music_vol", music_vol)
	cfg.set_value("audio", "music_style", music_style)
	cfg.set_value("audio", "sfx_style", sfx_style)
	cfg.set_value("look", "theme", theme)
	cfg.set_value("look", "background", background)
	cfg.set_value("controls", "mode", control_mode)
	for a in keys:
		cfg.set_value("keys", a, keys[a])
	cfg.set_value("controls", "layout", layout)
	cfg.set_value("controls", "swap_sides", swap_sides)
	cfg.set_value("controls", "move_speed", move_speed)
	cfg.set_value("controls", "ghost", ghost)
	cfg.set_value("vs", "level", vs_level)
	cfg.set_value("vs", "char", vs_char)
	for lv in vs_record:
		cfg.set_value("vs", "w%d" % lv, vs_record[lv][0])
		cfg.set_value("vs", "l%d" % lv, vs_record[lv][1])
	cfg.save(PATH)
