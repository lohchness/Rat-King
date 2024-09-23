extends CharacterBody2D

const BasicRat = preload("res://Scenes/BasicRat.tscn")
@export var RatSkin: Texture

var base_speed = 300
var base_accel = 30
var curr_speed
var curr_accel

@onready var grabOthersAreas = $GrabOthers
@onready var ratBodies = $BasicRatBodies
var group_name
var num_rats
var last_rat_added: BasicRat
var is_rotating = false
var current_rotation
var target_rotation


var movement_target_position: Vector2
var target_creature: CharacterBody2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@export var navigation_region: NavigationRegion2D
var map
var path = []


func _ready() -> void:
	movement_target_position = position
	call_deferred("setup_navserver")
	
	curr_speed = base_speed
	curr_accel = base_accel
	
	group_name = "RatPackCollider" + str(randi_range(0, 10))
	
	## Add initial rat
	var firstrat = BasicRat.instantiate()
	ratBodies.add_child(firstrat)
	num_rats = 1
	
	firstrat.call_deferred("add_to_pack", self, num_rats, true) ## Wait for tree to finish initializing
	#add_rat_to_this_pack(firstrat, true)
	call_deferred("add_rat_to_this_pack", firstrat, true)

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

func update_rat_transforms():
	## BasicRatBodies   CharacterBody2D and Sprites
	## GrabOthers       CollisionPolygon2Ds
	## 
	
	var rat_bodies = ratBodies.get_children() ## Rat Character Bodies and Sprites
	var rat_grab_colliders = grabOthersAreas.get_children() ## Grab Colliders
	var rat_physics_colliders = get_tree().get_nodes_in_group(group_name) ## Physics Collider
	
	assert(num_rats == len(rat_bodies))
	
	for i in range(num_rats):
		var pack_rotation: float = 2 * PI * i / num_rats
		
		rat_bodies[i].global_position = position
		rat_bodies[i].global_rotation = pack_rotation + rotation
		
		rat_grab_colliders[i].global_position = rat_bodies[i].grabCenter.global_position
		
		rat_physics_colliders[i].global_position = position
		rat_physics_colliders[i].global_rotation = pack_rotation + rotation

func reparent_nodes(body: BasicRat):
	body.reparent(ratBodies)
	
	## COLLISION AND AREAS
	var collision: CollisionPolygon2D = body.physicsCollider
	collision.reparent(self)
	collision.add_to_group(group_name)
	
	## Get CollisionShape of GrabOthersRadius
	## This will be put into GrabOthers Area2D to detect other rats to grab.
	var grab_shape = body.grabOthersCollider
	grab_shape.reparent(grabOthersAreas)

func shoot_rat(direction: Vector2):
	if (num_rats < 2):
		return
	
	unpack_rat(direction)
	num_rats -= 1
	
	update_rat_transforms()

## Reparent node
func unpack_rat(direction: Vector2):
	var rat_bodies = ratBodies.get_children() ## Rat Character Bodies and Sprites
	
	## Get a random rat and send it flying
	## Reparent and change collision layers
	var i = randi_range(0, len(rat_bodies) - 1)
	var rat_body: CollisionObject2D = rat_bodies[i]
	
	var rat_grab_collider = grabOthersAreas.get_child(i) ## Grab Colliders
	var rat_physics_collider = get_tree().get_nodes_in_group(group_name)[i] ## Physics Collider
	
	rat_physics_collider.reparent(rat_body)
	rat_grab_collider.reparent(rat_body.grabOthersArea)
	rat_body.reparent(get_parent()) ## ASSUMES PACK IS A CHILD OF THE SCENE
	
	rat_body.set_collision_layer_value(3, false) ## I am no longer a Enemy Rat Pack
	
	rat_body.set_collision_mask_value(2, false) ## I can no longer detect Solo Rats
	rat_body.set_collision_mask_value(7, false) # I can no longer detect Player Projectiles
	
	rat_body.set_collision_layer_value(4, true) ## I am a Player Projectile
	
	rat_body.projectile_settings(direction.normalized())
	rat_body.stateChart.send_event("on_throw")

func _physics_process(delta):
	
	#var dir = to_local(navigation_agent.get_next_path_position()).normalized()
	#velocity = dir * 100
	#move_and_slide()
	#
	#if target_creature:
		#navigation_agent.target_position = target_creature.global_position
	#
	var walk_distance = base_speed * delta
	move_along_path(walk_distance)
	move_and_slide()

func move_along_path(distance):
	var last_point = self.position
	while path.size():
		var distance_between_points = last_point.distance_to(path[0])
		if distance <= distance_between_points:
			self.position = last_point.lerp(path[0], distance / distance_between_points)
			return
		distance -= distance_between_points
		last_point = path[0]
		path.remove_at(0)
	self.position = last_point
	set_process(false)



## PATHFINDING

func setup_navserver():
	# Create new navigation server map
	map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_active(map, true)
	
	# Create a new navigation region and add it to the map
	var region = NavigationServer2D.region_create()
	NavigationServer2D.region_set_transform(region, Transform2D())
	NavigationServer2D.region_set_map(region, map)
	
	# Set navigation mesh for the Navigation Region from main scene
	var navigation_poly = NavigationMesh.new()
	navigation_poly = navigation_region.navigation_polygon
	NavigationServer2D.map_set_cell_size(map, 1)
	NavigationServer2D.region_set_navigation_polygon(region, navigation_poly)


func _on_recalculate_path_timeout() -> void:
	if (target_creature):
		update_navigation_path(global_position, target_creature.global_position)
		print("My position")
		print(global_position)
		print("Target position")
		print(target_creature.global_position)
		print("Direction")
		print(target_creature.global_position - global_position)

func update_navigation_path(start_pos, end_pos):
	path = NavigationServer2D.map_get_path(map, start_pos, end_pos, true)
	path.remove_at(0)

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func _on_detection_radius_body_entered(body: Node2D) -> void:
	target_creature = body

func _on_chase_radius_body_exited(body: Node2D) -> void:
	target_creature = null
