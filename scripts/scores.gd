extends Node
## Local leaderboard (autoload "Scores"). Saved to user:// which the web
## build persists in the browser's IndexedDB.

const PATH := "user://scores.json"
const MAX_ENTRIES := 10

var entries: Array = []
var last_name := "AAA"
## Index of the entry just added (for highlighting), -1 if none.
var highlight := -1


func _ready() -> void:
	_load()


func best() -> int:
	return int(entries[0]["score"]) if entries.size() > 0 else 0


func qualifies(score: int) -> bool:
	if score <= 0:
		return false
	return entries.size() < MAX_ENTRIES or score > int(entries[entries.size() - 1]["score"])


## Adds a finished game. Returns its 1-based rank, or 0 if it did not make the board.
func add(player: String, score: int, lines: int, level: int) -> int:
	last_name = player
	var entry := {
		"name": player, "score": score, "lines": lines, "level": level,
		"date": Time.get_date_string_from_system(),
	}
	entries.append(entry)
	entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	var rank := entries.find(entry)
	highlight = rank
	_save()
	return rank + 1 if rank >= 0 else 0


func clear() -> void:
	entries.clear()
	highlight = -1
	_save()


func _load() -> void:
	entries.clear()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	var list = data
	if data is Dictionary:
		list = data.get("entries", [])
		last_name = str(data.get("name", last_name))
	if list is Array:
		for e in list:
			if e is Dictionary and e.has("score"):
				entries.append({
					"name": str(e.get("name", "---")), "score": int(e["score"]),
					"lines": int(e.get("lines", 0)), "level": int(e.get("level", 1)),
					"date": str(e.get("date", "")),
				})


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"v": 2, "name": last_name, "entries": entries}))
