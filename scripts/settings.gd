extends Node
## User options (autoload "Settings"), persisted to user://settings.cfg.

const PATH := "user://settings.cfg"
const DAS := [0.17, 0.13, 0.09]  # delay before auto-repeat: slow / normal / fast
const ARR := [0.05, 0.035, 0.02]  # auto-repeat interval

# Audio
var sound_on := true
var music_on := true
var sound_vol := 0.8
var music_vol := 0.7
# Look
var theme := "candy"
var background := "nebula"
# Controls
var layout := "classic"  # "classic" | "thumbs"
var swap_sides := false
var move_speed := 1      # 0 slow, 1 normal, 2 fast
var ghost := true


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	sound_on = cfg.get_value("audio", "sound", sound_on)
	music_on = cfg.get_value("audio", "music", music_on)
	sound_vol = clampf(cfg.get_value("audio", "sound_vol", sound_vol), 0.0, 1.0)
	music_vol = clampf(cfg.get_value("audio", "music_vol", music_vol), 0.0, 1.0)
	theme = cfg.get_value("look", "theme", theme)
	background = cfg.get_value("look", "background", background)
	layout = cfg.get_value("controls", "layout", layout)
	swap_sides = cfg.get_value("controls", "swap_sides", swap_sides)
	move_speed = clampi(cfg.get_value("controls", "move_speed", move_speed), 0, 2)
	ghost = cfg.get_value("controls", "ghost", ghost)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound", sound_on)
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sound_vol", sound_vol)
	cfg.set_value("audio", "music_vol", music_vol)
	cfg.set_value("look", "theme", theme)
	cfg.set_value("look", "background", background)
	cfg.set_value("controls", "layout", layout)
	cfg.set_value("controls", "swap_sides", swap_sides)
	cfg.set_value("controls", "move_speed", move_speed)
	cfg.set_value("controls", "ghost", ghost)
	cfg.save(PATH)
