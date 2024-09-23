extends Area2D

@onready var basicRat = preload("res://Scenes/BasicRat.tscn")

var can_spawn = true

func spawn_rat():
	#var b = get_overlapping_areas()
	#if b.any(func (x): x.is_in_group("PlayerRat")):
		#can_spawn = true
		#print("can spawn")
	
	
	if can_spawn:
		var rat = basicRat.instantiate()
		rat.global_position = position
		rat.global_rotation = randf_range(-PI, PI)
		return rat
	return null

func _on_area_entered(area: Area2D) -> void:
	can_spawn = false

func _on_area_exited(area: Area2D) -> void:
	can_spawn = true
