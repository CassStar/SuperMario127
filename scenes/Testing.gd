extends Node

func _readynt():
	var level_JSON = load("res://assets/levels/TestLevel.tres")
	var level = Level.new()
	level.load_in(level_JSON)
	level.areas[0].unload(self)
	level.areas[0].load_in(self, false)
