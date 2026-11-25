extends RefCounted
## Estimates the player's skill as a CPU level (1-20) from what was recorded while playing.
## A profile is {pieces, time, keys, delay, delay_n, holes}: pieces locked, seconds played, key presses (moves, rotates,
## hold), summed delay from a piece appearing to its first key, number of those delays, holes created.
## Speed (pieces/s) and reaction are matched to the CPU's own numbers; stacking cleanliness (holes per piece) is a rough
## linear scale. Weights: speed 50 %, stacking 30 %, reaction 20 %.

const CpuPlayer := preload("res://scripts/cpu_player.gd")

const MIN_PIECES := 15
# pieces per second the CPU really reaches (measured headless), by level
const PPS_LEVELS := [1, 3, 5, 7, 10, 13, 15, 18, 20]
const PPS := [0.40, 0.47, 0.60, 0.73, 1.14, 1.38, 1.59, 2.07, 2.61]


static func empty() -> Dictionary:
	return {"pieces": 0, "time": 0.0, "keys": 0, "delay": 0.0, "delay_n": 0, "holes": 0}


static func add(into: Dictionary, p: Dictionary) -> void:
	for k in p:
		into[k] = into.get(k, 0) + p[k]


## Estimated CPU level (1.0-20.0), or -1.0 when there is too little data.
static func estimate(p: Dictionary) -> float:
	if p.get("pieces", 0) < MIN_PIECES or p.get("time", 0.0) <= 1.0:
		return -1.0
	var pps: float = p["pieces"] / p["time"]
	var speed := float(PPS_LEVELS[0])
	if pps >= PPS[-1]:
		speed = 20.0
	else:
		for i in range(1, PPS.size()):
			if pps < PPS[i]:
				speed = lerpf(PPS_LEVELS[i - 1], PPS_LEVELS[i], clampf((pps - PPS[i - 1]) / (PPS[i] - PPS[i - 1]), 0.0, 1.0))
				break
	var delay: float = p["delay"] / maxf(p["delay_n"], 1)
	var react := 1.0
	for lv in range(MAX_LV, 0, -1):  # the highest level that is no faster than the player
		if CpuPlayer.params(lv)["think"] + CpuPlayer.INPUT_LAG >= delay:
			react = float(lv)
			break
	var clean := clampf(20.0 - 19.0 * (float(p["holes"]) / p["pieces"]) / 0.4, 1.0, 20.0)
	return clampf(0.5 * speed + 0.3 * clean + 0.2 * react, 1.0, 20.0)


const MAX_LV := 20


static func text(level: float) -> String:
	if level < 0.0:
		return "not enough data"
	var lv := roundi(level)
	return "CPU Lv %d  %s" % [lv, CpuPlayer.NAMES[lv - 1]]
