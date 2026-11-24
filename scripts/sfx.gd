extends Node
## Sound effects are synthesized in code; background music is rendered to OGG loops by
## tools/gen_music.py (styles listed in assets/music/styles.json).
## Autoload "Sfx". On/off, volumes and the music style live in the Settings autoload.

const RATE := 22050
const MRATE := 11025

var _banks := {}  # sfx style -> {sound name -> stream}
var _players: Array = []
var _music: AudioStreamPlayer
var _music_style := ""
var _theme := ""  # a fighter theme overrides the chosen style (tournament fights)
var _preview: AudioStreamPlayer
var _preview_token := 0
var _music_wanted := false


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_preview = AudioStreamPlayer.new()
	add_child(_preview)
	apply_volumes()
	_ensure_bank(Settings.sfx_style)


# ---------------------------------------------------------------- public API

func play(sound: String) -> void:
	if not Settings.sound_on:
		return
	var bank := _ensure_bank(Settings.sfx_style)
	if not bank.has(sound):
		return
	var player: AudioStreamPlayer = _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = bank[sound]
	player.volume_db = -6.0 + linear_to_db(maxf(Settings.sound_vol, 0.0001))
	player.play()


## `theme`: a fighter id to play that fighter's own music instead of the chosen style ("" = the chosen style).
func start_music(theme: String = "", pitch: float = 1.0) -> void:
	_theme = theme
	_music.pitch_scale = pitch
	_music_wanted = true
	if not Settings.music_on:
		return
	_ensure_style()
	if not _music.playing:
		_music.play()


## Loads the OGG for the selected style (looping) into the music player if needed.
func _ensure_style() -> void:
	var id := _current_id()
	if _music_style == id and _music.stream != null:
		return
	_music.stream = _load_style(id)
	_music_style = id


func _current_id() -> String:
	return "theme_" + _theme if _theme != "" else Settings.music_style


func _load_style(id: String) -> AudioStream:
	var st = load("res://assets/music/%s.ogg" % id)
	if st == null:
		st = load("res://assets/music/robot.ogg")
	if st is AudioStreamOggVorbis:
		st.loop = true
	return st


## Call after the style option changed: swaps the track if music is supposed to be playing.
func refresh_music_style() -> void:
	if _music_wanted and Settings.music_on:
		_music.stream = _load_style(_current_id())
		_music_style = _current_id()
		_music.play()


## Plays the first seconds of a style (used by the options screen).
func preview_music(id: String) -> void:
	_preview_token += 1
	var token := _preview_token
	_preview.stream = _load_style(id)
	_preview.volume_db = -15.0 + linear_to_db(maxf(Settings.music_vol, 0.0001))
	_preview.play()
	await get_tree().create_timer(9.0).timeout
	if token == _preview_token:
		_preview.stop()


func stop_preview() -> void:
	_preview_token += 1
	_preview.stop()


func stop_music() -> void:
	_music_wanted = false
	_music.pitch_scale = 1.0
	_music.stop()


func pause_music(paused: bool) -> void:
	_music.stream_paused = paused


func apply_volumes() -> void:
	var db := -15.0 + linear_to_db(maxf(Settings.music_vol, 0.0001))
	_music.volume_db = db
	_preview.volume_db = db


func set_sound(on: bool) -> void:
	Settings.sound_on = on
	Settings.save()


func set_music(on: bool) -> void:
	Settings.music_on = on
	Settings.save()
	if on:
		if _music_wanted:
			start_music()
	else:
		_music.stop()


# ---------------------------------------------------------------- synthesis

func _wave(shape: int, phase: float) -> float:
	var f := fposmod(phase, 1.0)
	match shape:
		0: return sin(TAU * phase)
		1: return 1.0 if f < 0.5 else -1.0
		2: return 4.0 * absf(f - 0.5) - 1.0
		_: return 2.0 * f - 1.0


## Adds one note into buf. shape: 0 sine, 1 square, 2 triangle, 3 saw.
func _note(buf: PackedFloat32Array, rate: int, start: float, dur: float, f0: float,
		f1: float, shape: int, vol: float, noise: float = 0.0, decay: float = 1.5) -> void:
	var s0 := int(start * rate)
	var n := int(dur * rate)
	var phase := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= buf.size():
			break
		var t := float(i) / float(n)
		phase += lerpf(f0, f1, t) / float(rate)
		var env := minf(float(i) / (0.004 * rate), 1.0) * pow(1.0 - t, decay)
		var v := _wave(shape, phase)
		if noise > 0.0:
			v = lerpf(v, randf_range(-1.0, 1.0), noise)
		buf[idx] += v * vol * env


func _to_stream(buf: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


func _blank(seconds: float, rate: int = RATE) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	return b


func _ensure_bank(style: String) -> Dictionary:
	if not _banks.has(style):
		_banks[style] = _build_soft() if style == "soft" else _build_arcade()
	return _banks[style]


## Gentle, marimba / bell style effects (the relaxed option).
func _bell(buf: PackedFloat32Array, start: float, dur: float, f: float, vol: float) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	for i in n:
		var idx := s0 + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var env := minf(float(i) / (0.003 * RATE), 1.0) * exp(-t * (7.0 / maxf(dur, 0.05)))
		var v := sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) * exp(-t * 14.0) \
			+ 0.12 * sin(TAU * f * 4.0 * t) * exp(-t * 30.0)
		buf[idx] += v * vol * env


func _build_soft() -> Dictionary:
	var out := {}
	var pent := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]  # C major pentatonic
	var b := _blank(0.1)
	_bell(b, 0, 0.09, 784.0, 0.16)
	out["move"] = _to_stream(b, RATE)
	b = _blank(0.16)
	_bell(b, 0, 0.14, 659.25, 0.22)
	_bell(b, 0.04, 0.12, 880.0, 0.18)
	out["rotate"] = _to_stream(b, RATE)
	b = _blank(0.25)
	_bell(b, 0, 0.2, 587.33, 0.24)
	_bell(b, 0.06, 0.18, 440.0, 0.2)
	out["hold"] = _to_stream(b, RATE)
	b = _blank(0.16)  # soft wooden "tok"
	_bell(b, 0, 0.12, 196.0, 0.5)
	out["lock"] = _to_stream(b, RATE)
	b = _blank(0.3)
	_bell(b, 0, 0.25, 130.8, 0.6)
	_bell(b, 0, 0.1, 261.6, 0.3)
	out["drop"] = _to_stream(b, RATE)
	for n in range(1, 5):
		b = _blank(1.0)
		for i in n + 1:
			_bell(b, i * 0.08, 0.5, pent[i], 0.24)
		if n == 4:
			_bell(b, 0.4, 0.55, 1046.5, 0.2)
			_bell(b, 0.4, 0.55, 1318.5, 0.16)
		out["clear%d" % n] = _to_stream(b, RATE)
	b = _blank(0.9)
	for i in 5:
		_bell(b, i * 0.09, 0.4, pent[i] * 0.75, 0.22)
	out["levelup"] = _to_stream(b, RATE)
	b = _blank(1.6)
	for i in 4:
		_bell(b, i * 0.28, 0.7, [440.0, 392.0, 329.6, 261.6][i], 0.26)
	out["gameover"] = _to_stream(b, RATE)
	b = _blank(0.07)
	_bell(b, 0, 0.06, 880.0, 0.14)
	out["click"] = _to_stream(b, RATE)
	b = _blank(0.5)  # attack sent: rising chime
	_bell(b, 0, 0.3, 523.25, 0.2)
	_bell(b, 0.07, 0.3, 783.99, 0.2)
	_bell(b, 0.14, 0.3, 1046.5, 0.2)
	out["attack"] = _to_stream(b, RATE)
	b = _blank(0.4)  # incoming garbage landing
	_bell(b, 0, 0.3, 110.0, 0.55)
	_bell(b, 0.05, 0.2, 164.8, 0.3)
	out["hit"] = _to_stream(b, RATE)
	b = _blank(1.4)
	for i in 5:
		_bell(b, i * 0.12, 0.6, pent[i], 0.24)
	_bell(b, 0.6, 0.8, 1046.5, 0.2)
	_bell(b, 0.6, 0.8, 1318.5, 0.16)
	out["win"] = _to_stream(b, RATE)
	b = _blank(1.5)
	for i in 3:
		_bell(b, i * 0.3, 0.7, [392.0, 329.6, 261.6][i], 0.24)
	out["lose"] = _to_stream(b, RATE)
	return out


func _build_arcade() -> Dictionary:
	var out := {}
	var b := _blank(0.04)
	_note(b, RATE, 0, 0.035, 700, 700, 1, 0.18)
	out["move"] = _to_stream(b, RATE)

	b = _blank(0.08)
	_note(b, RATE, 0, 0.07, 480, 900, 1, 0.2)
	out["rotate"] = _to_stream(b, RATE)

	b = _blank(0.12)
	_note(b, RATE, 0, 0.1, 620, 330, 2, 0.5)
	out["hold"] = _to_stream(b, RATE)

	b = _blank(0.12)
	_note(b, RATE, 0, 0.1, 210, 70, 2, 0.7)
	_note(b, RATE, 0, 0.04, 400, 400, 1, 0.2, 0.8)
	out["lock"] = _to_stream(b, RATE)

	b = _blank(0.2)
	_note(b, RATE, 0, 0.16, 320, 45, 2, 0.8)
	_note(b, RATE, 0, 0.09, 200, 200, 1, 0.45, 0.9)
	out["drop"] = _to_stream(b, RATE)

	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	for n in range(1, 5):
		b = _blank(0.7)
		for i in n + 1:
			_note(b, RATE, i * 0.065, 0.16, notes[i], notes[i], 1, 0.2)
		if n == 4:
			_note(b, RATE, 0.32, 0.35, 1046.5, 1046.5, 2, 0.35, 0.0, 1.0)
			_note(b, RATE, 0.32, 0.35, 1318.5, 1318.5, 2, 0.25, 0.0, 1.0)
		out["clear%d" % n] = _to_stream(b, RATE)

	b = _blank(0.6)
	for i in 5:
		_note(b, RATE, i * 0.07, 0.12, notes[i] * 0.75, notes[i] * 0.75, 2, 0.4)
	out["levelup"] = _to_stream(b, RATE)

	b = _blank(1.1)
	var down := [440.0, 370.0, 311.0, 233.0]
	for i in 4:
		_note(b, RATE, i * 0.2, 0.3, down[i], down[i] * 0.97, 2, 0.5, 0.0, 1.0)
	out["gameover"] = _to_stream(b, RATE)

	b = _blank(0.05)
	_note(b, RATE, 0, 0.04, 950, 950, 1, 0.15)
	out["click"] = _to_stream(b, RATE)

	b = _blank(0.3)  # attack sent: rising zap
	_note(b, RATE, 0, 0.22, 260, 1100, 1, 0.2)
	_note(b, RATE, 0.05, 0.2, 390, 1650, 2, 0.14)
	out["attack"] = _to_stream(b, RATE)

	b = _blank(0.35)  # incoming blocks landing: dull crunch
	_note(b, RATE, 0, 0.28, 150, 40, 2, 0.8)
	_note(b, RATE, 0, 0.12, 300, 300, 1, 0.35, 0.95)
	out["hit"] = _to_stream(b, RATE)

	b = _blank(1.2)  # win fanfare
	var up := [523.25, 659.25, 783.99, 1046.5]
	for i in 4:
		_note(b, RATE, i * 0.11, 0.18, up[i], up[i], 1, 0.22)
	_note(b, RATE, 0.5, 0.6, 1046.5, 1046.5, 2, 0.4, 0.0, 1.0)
	_note(b, RATE, 0.5, 0.6, 1318.5, 1318.5, 2, 0.3, 0.0, 1.0)
	out["win"] = _to_stream(b, RATE)

	b = _blank(1.4)  # lose: sad descending
	var sad := [392.0, 349.2, 311.1, 261.6]
	for i in 4:
		_note(b, RATE, i * 0.25, 0.35, sad[i], sad[i] * 0.96, 2, 0.5, 0.0, 1.0)
	out["lose"] = _to_stream(b, RATE)
	return out
