extends Node
## Local leaderboard (autoload "Scores"). Saved to user:// which the web
## build persists in the browser's IndexedDB.

const PATH := "user://scores.json"
const MAX_ENTRIES := 10

var entries: Array = []


func _ready() -> void:
	_load()


func best() -> int:
	return int(entries[0]["score"]) if entries.size() > 0 else 0


## Adds a finished game. Returns its 1-based rank, or 0 if it did not make the board.
func add(score: int, lines: int, level: int) -> int:
	var entry := {
		"score": score, "lines": lines, "level": level,
		"date": Time.get_date_string_from_system(),
	}
	entries.append(entry)
	entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	_save()
	var rank := entries.find(entry)
	return rank + 1 if rank >= 0 and score > 0 else 0


func clear() -> void:
	entries.clear()
	_save()


func _load() -> void:
	entries.clear()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		for e in data:
			if e is Dictionary and e.has("score"):
				entries.append({
					"score": int(e["score"]), "lines": int(e.get("lines", 0)),
					"level": int(e.get("level", 1)), "date": str(e.get("date", "")),
				})


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(entries))
