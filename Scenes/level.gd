extends Node2D

var curr_rats_solo = 0
var curr_rat_packs = 0

var max_rats_solo = 50
var max_rat_packs = 4

@onready var allSpawners = $Spawners.get_children()

@onready var navreg = $TileMaps/NavigationRegion2D
@onready var target = $Player

var enemyratpacks

func _ready() -> void:
	pass
	#var enemyratpacks = get_children().any(func (x): return x.has_signal("pack_dead"))

func _process(delta: float) -> void:
	pass

func _on_spawn_timer_timeout() -> void:
	if curr_rats_solo < max_rats_solo:
		var r = allSpawners.pick_random().spawn_rat()
		if r:
			add_child(r)
			curr_rats_solo += 1


func _on_label_timer_timeout() -> void:
	$Label.visible = false
	pass # Replace with function body.
