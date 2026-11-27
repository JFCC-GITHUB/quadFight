extends "res://scripts/cpu_player.gd"
## Player 2 in the 2-player versus mode: the same board as the CPU opponent (so attacks, specials and stats work the
## same way), but driven by the p2_* input actions instead of the AI. Movement follows the player-1 rules: DAS/ARR from
## Settings, soft drop, 15 lock resets per piece, a soft drop held through a lock is ignored until released.

const P := "p2_"
const MAX_LOCK_RESETS := 15

var das_dir := 0
var das_timer := 0.0
var lock_resets := 0
var soft_lock := false


func _init(lv: int = 10) -> void:
	super(lv)


## One-shot key from the game screen's input handler: "rotate_cw", "rotate_ccw", "hard_drop" or "hold".
func press(action: String) -> void:
	if not alive:
		return
	presses += 1
	match action:
		"rotate_cw": _rotate(1)
		"rotate_ccw": _rotate(-1)
		"hard_drop": _hard_drop()
		"hold":
			if not hold_used:
				_hold(params(level))


func _think(delta: float) -> void:
	var dir := int(Input.is_action_pressed(P + "move_right")) - int(Input.is_action_pressed(P + "move_left"))
	if dir == 0:
		das_dir = 0
		return
	if dir != das_dir:
		das_dir = dir
		das_timer = -Settings.DAS[Settings.move_speed]
		presses += 1
		_move(dir)
		return
	das_timer += delta
	var arr: float = Settings.ARR[Settings.move_speed]
	while das_timer >= arr:
		das_timer -= arr
		_move(dir)


func gravity_interval() -> float:
	var held := Input.is_action_pressed(P + "soft_drop")
	if not held:
		soft_lock = false
	return minf(super(), 0.05) if held and not soft_lock else super()


func _on_moved() -> void:
	if _collides(kind, rot, pos + Vector2i(0, 1)) and lock_resets < MAX_LOCK_RESETS:
		lock_timer = 0.0
		lock_resets += 1


func _spawn() -> void:
	super()
	lock_resets = 0
	soft_lock = Input.is_action_pressed(P + "soft_drop")
