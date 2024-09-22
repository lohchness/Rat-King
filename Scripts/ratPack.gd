extends CharacterBody2D
class_name RatPack

const BasicRat = preload("res://Scenes/BasicRat.tscn")
@export var RatSkin: Texture

var base_speed = 500
var base_accel = 50
var curr_speed
var curr_accel
var is_moving : bool

@onready var grabOthersAreas = $GrabOthers
var num_rats = 0
var last_rat_added: BasicRat

var rat_bodies
var rat_colliders


func _ready() -> void:
	curr_speed = base_speed
	curr_accel = base_accel
	
	## Add initial rat
	var firstrat = BasicRat.instantiate()
	get_node("BasicRatBodies").add_child(firstrat)
	
	firstrat.call_deferred("add_to_pack", self) ## Wait for tree to finish initializing
	add_rat_to_this_pack(firstrat)

func _physics_process(delta: float) -> void:
	
	if num_rats == 1:
		last_rat_added.position = last_rat_added.get_node("Center").position
		last_rat_added.physicsCollider.position = last_rat_added.get_node("Center").position
	
	
	## Movement
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity.x = move_toward(velocity.x, curr_speed * direction.x, curr_accel)
	velocity.y = move_toward(velocity.y, curr_speed * direction.y, curr_accel)
	move_and_slide()
	
	## Rotate based on direction
	is_moving = velocity.length() > 0.01
	if is_moving:
		rotation = lerp_angle(rotation, velocity.angle(), 10 * delta)
	
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space"):
		var bodies: Array = grabOthersAreas.get_overlapping_areas()\
			.filter(func (x): return x.is_in_group("EnemyRatSolo"))\
			.map(func (x): return x.get_parent())
		
		if (len(bodies)):
			var new_rat = bodies.pick_random()
			add_rat_to_this_pack(new_rat)

## Reparents the collision nodes of a BasicRat
func add_rat_to_this_pack(body: BasicRat):
	body.add_to_pack(self)
	
	## APPEARANCE
	
	## COLLISION AND AREAS
	
	var collision: CollisionPolygon2D = body.get_node("Collision")
	collision.reparent(self)
	
	## Get CollisionShape of GrabOthersRadius
	## This will be put into GrabOthers Area2D to detect other rats to grab.
	var grab_area = body.get_node("GrabOtherRadius").get_child(0)
	grab_area.reparent(grabOthersAreas)
	
	last_rat_added = body
	num_rats += 1

## Called when GrabOthers collides with another Area.
func _on_grab_others_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyRatSolo"):
		area.get_parent().call("entered_player_grab_radius")

func _on_grab_others_area_exited(area: Area2D) -> void:
	if area.is_in_group("EnemyRatSolo"):
		area.get_parent().call("exited_player_grab_radius")
