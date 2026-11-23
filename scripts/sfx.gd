extends Node
## Procedurally synthesized sound effects + chiptune music (no audio assets).
## Autoload "Sfx". Settings persist in user://settings.cfg.

const RATE := 22050
const MRATE := 11025
const SETTINGS := "user://settings.cfg"

var sound_on := true
var music_on := true

var _streams := {}
var _players: Array = []
var _music: AudioStreamPlayer
var _music_ready := false
var _music_wanted := false


func _ready() -> void:
	_load_settings()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -15.0
	add_child(_music)
	_build_sfx()
	# Music takes a moment to synthesize; do it after the first frames.
	await get_tree().create_timer(0.4).timeout
	_build_music()


# ---------------------------------------------------------------- public API

func play(sound: String) -> void:
	if not sound_on or not _streams.has(sound):
		return
	var player: AudioStreamPlayer = _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = _streams[sound]
	player.play()


func start_music() -> void:
	_music_wanted = true
	if music_on and _music_ready and not _music.playing:
		_music.play()


func stop_music() -> void:
	_music_wanted = false
	_music.stop()


func pause_music(paused: bool) -> void:
	_music.stream_paused = paused


func set_sound(on: bool) -> void:
	sound_on = on
	_save_settings()


func set_music(on: bool) -> void:
	music_on = on
	_save_settings()
	if on:
		start_music() if _music_wanted else null
	else:
		_music.stop()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		sound_on = cfg.get_value("audio", "sound", true)
		music_on = cfg.get_value("audio", "music", true)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound", sound_on)
	cfg.set_value("audio", "music", music_on)
	cfg.save(SETTINGS)


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


func _build_sfx() -> void:
	var b := _blank(0.04)
	_note(b, RATE, 0, 0.035, 700, 700, 1, 0.18)
	_streams["move"] = _to_stream(b, RATE)

	b = _blank(0.08)
	_note(b, RATE, 0, 0.07, 480, 900, 1, 0.2)
	_streams["rotate"] = _to_stream(b, RATE)

	b = _blank(0.12)
	_note(b, RATE, 0, 0.1, 620, 330, 2, 0.5)
	_streams["hold"] = _to_stream(b, RATE)

	b = _blank(0.12)
	_note(b, RATE, 0, 0.1, 210, 70, 2, 0.7)
	_note(b, RATE, 0, 0.04, 400, 400, 1, 0.2, 0.8)
	_streams["lock"] = _to_stream(b, RATE)

	b = _blank(0.2)
	_note(b, RATE, 0, 0.16, 320, 45, 2, 0.8)
	_note(b, RATE, 0, 0.09, 200, 200, 1, 0.45, 0.9)
	_streams["drop"] = _to_stream(b, RATE)

	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	for n in range(1, 5):
		b = _blank(0.7)
		for i in n + 1:
			_note(b, RATE, i * 0.065, 0.16, notes[i], notes[i], 1, 0.2)
		if n == 4:
			_note(b, RATE, 0.32, 0.35, 1046.5, 1046.5, 2, 0.35, 0.0, 1.0)
			_note(b, RATE, 0.32, 0.35, 1318.5, 1318.5, 2, 0.25, 0.0, 1.0)
		_streams["clear%d" % n] = _to_stream(b, RATE)

	b = _blank(0.6)
	for i in 5:
		_note(b, RATE, i * 0.07, 0.12, notes[i] * 0.75, notes[i] * 0.75, 2, 0.4)
	_streams["levelup"] = _to_stream(b, RATE)

	b = _blank(1.1)
	var down := [440.0, 370.0, 311.0, 233.0]
	for i in 4:
		_note(b, RATE, i * 0.2, 0.3, down[i], down[i] * 0.97, 2, 0.5, 0.0, 1.0)
	_streams["gameover"] = _to_stream(b, RATE)

	b = _blank(0.05)
	_note(b, RATE, 0, 0.04, 950, 950, 1, 0.15)
	_streams["click"] = _to_stream(b, RATE)


func _build_music() -> void:
	# "Korobeiniki" (traditional Russian folk song, public domain), 4-bar phrases.
	var N := {"A2": 110.0, "E2": 82.41, "D2": 73.42, "C2": 65.41,
		"A4": 440.0, "B4": 493.88, "C5": 523.25, "D5": 587.33, "E5": 659.25,
		"F5": 698.46, "G5": 783.99, "A5": 880.0}
	var mel := [
		["E5", 2], ["B4", 1], ["C5", 1], ["D5", 2], ["C5", 1], ["B4", 1],
		["A4", 2], ["A4", 1], ["C5", 1], ["E5", 2], ["D5", 1], ["C5", 1],
		["B4", 3], ["C5", 1], ["D5", 2], ["E5", 2],
		["C5", 2], ["A4", 2], ["A4", 4],
		["D5", 3], ["F5", 1], ["A5", 2], ["G5", 1], ["F5", 1],
		["E5", 3], ["C5", 1], ["E5", 2], ["D5", 1], ["C5", 1],
		["B4", 3], ["C5", 1], ["D5", 2], ["E5", 2],
		["C5", 2], ["A4", 2], ["A4", 4],
	]
	var roots := ["A2", "A2", "E2", "A2", "D2", "C2", "E2", "A2"]
	var unit := 0.19
	var total_units := 64
	var buf := _blank(total_units * unit, MRATE)
	var t := 0.0
	for m in mel:
		var d: float = m[1] * unit
		_note(buf, MRATE, t, d * 0.92, N[m[0]], N[m[0]], 1, 0.2, 0.0, 0.6)
		t += d
	for block in 8:
		var root: float = N[roots[block]]
		for q in 4:
			var f := root if q % 2 == 0 else root * 1.5
			_note(buf, MRATE, (block * 8 + q * 2) * unit, 1.8 * unit, f, f, 2, 0.3, 0.0, 0.5)
	var stream := _to_stream(buf, MRATE)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = buf.size()
	_music.stream = stream
	_music_ready = true
	if _music_wanted and music_on:
		_music.play()
