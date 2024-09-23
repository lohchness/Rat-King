extends Node2D

var curr_rats_solo = 0
var curr_rat_packs = 0

var max_rats_solo = 50
var max_rat_packs = 4

@onready var allSpawners = $Spawners.get_children()

func _process(delta: float) -> void:
	pass

func _on_spawn_timer_timeout() -> void:
	if curr_rats_solo < max_rats_solo:
		var r = allSpawners.pick_random().spawn_rat()
		if r:
			add_child(r)
			curr_rats_solo += 1
