extends CharacterBody2D
class_name RatPack

const BasicRat = preload("res://Scenes/BasicRat.tscn")
@export var RatSkin: Texture

var base_speed = 300
var base_accel = 30
var curr_speed
var curr_accel
var is_moving : bool

@onready var grabOthersAreas = $GrabOthers
@onready var ratBodies = $BasicRatBodies
var num_rats
var last_rat_added: BasicRat

var is_rotating = false
var current_rotation
var target_rotation

func _ready() -> void:
	curr_speed = base_speed
	curr_accel = base_accel
	
	## Add initial rat
	var firstrat = BasicRat.instantiate()
	ratBodies.add_child(firstrat)
	num_rats = 1
	
	firstrat.call_deferred("add_to_pack", self, num_rats, true) ## Wait for tree to finish initializing
	#add_rat_to_this_pack(firstrat, true)
	call_deferred("add_rat_to_this_pack", firstrat, true)

func _physics_process(delta: float) -> void:
	## Movement
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity.x = move_toward(velocity.x, curr_speed * direction.x, curr_accel)
	velocity.y = move_toward(velocity.y, curr_speed * direction.y, curr_accel)
	move_and_slide()
	
	## Rotate based on direction
	is_moving = velocity.length() > 0.01
	if is_moving and !is_rotating:
		rotation = lerp_angle(rotation, velocity.angle(), 10 * delta)
	if is_rotating:
		current_rotation = lerp(current_rotation, target_rotation, 5 * delta)
		rotation = current_rotation
		if (abs(current_rotation - target_rotation) < 1):
			is_rotating = false

## Reparents the BasicRat and its nodes.
## The BasicRat CharacterBody2D will be a direct child of the RatPack.
func add_rat_to_this_pack(body: BasicRat, is_first = false):
	last_rat_added = body
	
	if !is_first:
		num_rats += 1
		body.add_to_pack(self, num_rats)
	
	#print_debug("Added rat number " + str(num_rats))
	
	reparent_nodes(body)
	update_rat_transforms()
	
	print("Pack is at position " + str(global_position))
	

func reparent_nodes(body: BasicRat):
	body.reparent(ratBodies)
	#body.add_to_group("PlayerRatCharacterBodies")
	
	## COLLISION AND AREAS
	var collision: CollisionPolygon2D = body.physicsCollider
	collision.reparent(self)
	collision.add_to_group("PlayerRatCollider")
	
	## Get CollisionShape of GrabOthersRadius
	## This will be put into GrabOthers Area2D to detect other rats to grab.
	var grab_shape = body.grabOthersCollider
	grab_shape.reparent(grabOthersAreas)
	#grab_shape.add_to_group("PlayerRatCharacterBodies")


func update_rat_transforms():
	## BasicRatBodies   CharacterBody2D and Sprites
	## GrabOthers       CollisionPolygon2Ds
	## 
	
	var rat_bodies = ratBodies.get_children() ## Rat Character Bodies and Sprites
	#var rat_bodies = get_tree().get_nodes_in_group("PlayerRatCharacterBodies")
	var rat_grab_colliders = grabOthersAreas.get_children() ## Grab Colliders
	var rat_physics_colliders = get_tree().get_nodes_in_group("PlayerRatCollider") ## Physics Collider
	
	assert(num_rats == len(rat_bodies))
	
	for i in range(num_rats):
		var pack_rotation: float = 2 * PI * i / num_rats
		
		rat_bodies[i].global_position = position
		rat_bodies[i].global_rotation = pack_rotation + rotation
		
		rat_grab_colliders[i].global_position = rat_bodies[i].grabCenter.global_position
		
		rat_physics_colliders[i].global_position = position
		rat_physics_colliders[i].global_rotation = pack_rotation + rotation

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space"):
		var bodies: Array = grabOthersAreas.get_overlapping_areas()\
			.filter(func (x): return x.is_in_group("EnemyRatSolo"))\
			.map(func (x): return x.get_parent())
		
		if (len(bodies) > 0):
			#add_rat_to_this_pack(bodies.pick_random())
			bodies.sort_custom(sort_bodies_distance)
			add_rat_to_this_pack(bodies[0])
	
	if event.is_action_pressed("mouse1"):
		var dir = get_local_mouse_position()
		current_rotation = rotation
		target_rotation = 5 * PI * -sign(dir.x)
		is_rotating = true
		
		shoot_rat(dir)


func shoot_rat(direction: Vector2):
	if (num_rats < 2):
		return
	
	unpack_rat(direction)
	num_rats -= 1
	
	update_rat_transforms()
	
	pass

## Reparent node
func unpack_rat(direction: Vector2):
	var rat_bodies = ratBodies.get_children() ## Rat Character Bodies and Sprites
	
	## Get a random rat and send it flying
	## Reparent and change collision layers
	var i = randi_range(0, len(rat_bodies) - 1)
	var rat_body: CollisionObject2D = rat_bodies[i]
	
	var rat_grab_collider = grabOthersAreas.get_child(i) ## Grab Colliders
	var rat_physics_collider = get_tree().get_nodes_in_group("PlayerRatCollider")[i] ## Physics Collider
	
	rat_physics_collider.reparent(rat_body)
	rat_grab_collider.reparent(rat_body.grabOthersArea)
	rat_body.reparent(get_parent()) ## ASSUMES PACK IS A CHILD OF THE SCENE
	
	## It is still technically a player, but now a projectile.
	rat_body.set_collision_layer_value(1, false) ## Not a Player Rat
	rat_body.set_collision_mask_value(2, false) ## Cannot detect Solo Rats (change?)
	
	rat_body.set_collision_layer_value(7, true) ## I am a projectile
	rat_body.set_collision_mask_value(3, true) ## I can detect Enemy Rat Pack
	rat_body.set_collision_mask_value(6, true) ## I can detect Wall
	
	rat_body.projectile_settings(direction.normalized())
	rat_body.stateChart.send_event("on_throw")


########### OTHERS

func sort_bodies_distance(a: Node2D, b: Node2D):
	if a.position.distance_squared_to(self.position) < b.position.distance_squared_to(self.position):
		return true
	return false

## Called when GrabOthers collides with another Area.
func _on_grab_others_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyRatSolo"):
		area.get_parent().call("entered_player_grab_radius")

func _on_grab_others_area_exited(area: Area2D) -> void:
	if area.is_in_group("EnemyRatSolo"):
		area.get_parent().call("exited_player_grab_radius")
