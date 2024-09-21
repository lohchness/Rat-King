extends CharacterBody2D
class_name RatPack

const BasicRat = preload("res://Scenes/BasicRat.tscn")
@export var RatSkin: Texture

var base_speed = 500
var base_accel = 50

var curr_speed
var curr_accel

var is_moving : bool

var num_rats = 0
var last_rat_added

func _ready() -> void:
	curr_speed = base_speed
	curr_accel = base_accel
	
	## Add initial rat
	var firstrat = BasicRat.instantiate()
	get_node("Rats").add_child(firstrat)
	
	last_rat_added = firstrat
	num_rats += 1
	
	firstrat.call_deferred("add_to_pack", self) ## Wait for tree to finish initializing
	
	## Change collision parent
	var collision_node = firstrat.get_node("Collision")
	firstrat.remove_child(collision_node)
	add_child(collision_node)

func _physics_process(delta: float) -> void:
	if num_rats == 1:
		last_rat_added.position = last_rat_added.get_node("Center").position
	
	## Movement
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity.x = move_toward(velocity.x, curr_speed * direction.x, curr_accel)
	velocity.y = move_toward(velocity.y, curr_speed * direction.y, curr_accel)
	move_and_slide()
	
	## Rotate based on direction
	is_moving = velocity.length() > 0.01
	if is_moving:
		rotation = lerp_angle(rotation, velocity.angle(), 20 * delta)
