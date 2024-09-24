extends CharacterBody2D

const BasicRat = preload("res://Scenes/BasicRat.tscn")
@export var RatSkin: Texture

var base_speed = 200
var base_accel = 5
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
	call_deferred("add_rat_to_this_pack", firstrat, true)


## Reparents the BasicRat and its nodes.
## The BasicRat CharacterBody2D will be a direct child of the RatPack.
func add_rat_to_this_pack(body: BasicRat, is_first = false):
	last_rat_added = body
	
	if !is_first:
		num_rats += 1
		body.add_to_pack(self, num_rats)
	
	reparent_nodes(body)
	update_rat_transforms()

func update_rat_transforms():
	## BasicRatBodies   CharacterBody2D and Sprites
	## GrabOthers       CollisionPolygon2Ds
	## 
	
	var rat_bodies = ratBodies.get_children() ## Rat Character Bodies and Sprites
	var rat_grab_colliders = grabOthersAreas.get_children() ## Grab Colliders
	var rat_physics_colliders = get_tree().get_nodes_in_group(group_name) ## Physics Collider
	
	#assert(num_rats == len(rat_bodies))
	
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
	
	rat_body.projectile_settings(direction.normalized(), true)
	rat_body.stateChart.send_event("on_throw")

var is_moving
var can_attack = false

var first_few_rats_added = false

signal pack_dead

func _physics_process(delta):
	
	if num_rats == 0:
		pack_dead.emit()
		queue_free()
	
	if !first_few_rats_added:
		var n = randi_range(3, 7)
		for i in range(n):
			var r = BasicRat.instantiate()
			get_parent().add_child(r)
			
			#add_rat_to_this_pack(r)
			call_deferred("add_rat_to_this_pack", r)
		
		first_few_rats_added = true
	
	#var dir = Vector2(navigation_agent.get_next_path_position())
	#dir = to_local(dir).normalized()
	#print(dir)
	#
	#if target_creature:
		#velocity = dir * base_speed
		#look_at(target_creature.global_position)
	var direction = Vector2.ZERO
	if can_chase:
		direction = (target_creature.global_position - global_position).normalized()
		#look_at(target_creature.global_position)
		rotation = lerp_angle(rotation, velocity.angle(), 5 * delta)
	if is_rotating:
		current_rotation = lerp(current_rotation, target_rotation, 5 * delta)
		rotation = current_rotation
		if (abs(current_rotation - target_rotation) < 1):
			is_rotating = false
		
	velocity.x = move_toward(velocity.x, curr_speed * direction.x, curr_accel)
	velocity.y = move_toward(velocity.y, curr_speed * direction.y, curr_accel)
	velocity.clamp(Vector2.ZERO, Vector2(600, 600))
	
	move_and_slide()
	
	#var walk_distance = base_speed * delta
	#move_along_path(walk_distance)
	#move_and_slide()

func move_along_path(distance):
	return
	#var last_point = self.position
	#while path.size():
		#var distance_between_points = last_point.distance_to(path[0])
		#if distance <= distance_between_points:
			#self.position = last_point.lerp(path[0], distance / distance_between_points)
			#return
		#distance -= distance_between_points
		#last_point = path[0]
		#path.remove_at(0)
	#self.position = last_point
	#set_process(false)

## PATHFINDING

func setup_navserver():
	return
	## Create new navigation server map
	#map = NavigationServer2D.map_create()
	#NavigationServer2D.map_set_active(map, true)
	#
	## Create a new navigation region and add it to the map
	#var region = NavigationServer2D.region_create()
	#NavigationServer2D.region_set_transform(region, Transform2D())
	#NavigationServer2D.region_set_map(region, map)
	#
	## Set navigation mesh for the Navigation Region from main scene
	#var navigation_poly = NavigationMesh.new()
	#navigation_poly = navigation_region.navigation_polygon
	#NavigationServer2D.map_set_cell_size(map, 1)
	#NavigationServer2D.region_set_navigation_polygon(region, navigation_poly)

#func _on_recalculate_path_timeout() -> void:
	#if (target_creature):
		##update_navigation_path(global_position, target_creature.global_position)
		#
		#navigation_agent.target_position = target_creature.global_position

func update_navigation_path(start_pos, end_pos):
	return
	#path = NavigationServer2D.map_get_path(map, start_pos, end_pos, true)
	#path.remove_at(0)

#func set_movement_target(movement_target: Vector2):
	#navigation_agent.target_position = movement_target

var can_chase = false
@export var player_body: RatPack

func _on_detection_radius_body_entered(body: Node2D) -> void:
	if !body.is_in_group("EnemyRatProjectile"):
		print("hi")
		target_creature = player_body
		can_chase = true

func _on_chase_radius_body_exited(body: Node2D) -> void:
	can_chase = false

func _on_grab_rat_timer_timeout() -> void:
	pass
	$GrabRatTimer.wait_time = randf_range(3, 5)
	grab_rat()

func _on_grab_others_area_entered(area: Area2D) -> void:
	grab_rat()

func grab_rat():
	var bodies: Array = grabOthersAreas.get_overlapping_areas()\
			.filter(func (x): return x.is_in_group("EnemyRatSolo"))\
			.map(func (x): return x.get_parent())
		
	if (len(bodies) > 0):
		#add_rat_to_this_pack(bodies.pick_random())
		bodies.sort_custom(sort_bodies_distance)
		add_rat_to_this_pack(bodies[0])

func sort_bodies_distance(a: Node2D, b: Node2D):
	if a.position.distance_squared_to(self.position) < b.position.distance_squared_to(self.position):
		return true
	return false

func _on_attack_radius_body_entered(body: Node2D) -> void:
	if !body.is_in_group("EnemyRatProjectile"):
		print("hi")
		can_attack = true

func _on_attack_radius_body_exited(body: Node2D) -> void:
	can_attack = false

func _on_attack_timer_timeout() -> void:
	$AttackTimer.wait_time = randf_range(0, 1)
	if can_attack:
		if num_rats > 3:
			var dir = target_creature.global_position - global_position
			current_rotation = rotation
			target_rotation = 5 * PI * -sign(dir.x)
			is_rotating = true
			shoot_rat(dir)


func damage():
	var rat_bodies = ratBodies.get_children()
	var i = randi_range(0, len(rat_bodies) - 1)
	var rat_body: CollisionObject2D = rat_bodies[i]
	
	
	var rat_grab_collider = grabOthersAreas.get_child(i) ## Grab Colliders
	var rat_physics_collider = get_tree().get_nodes_in_group(group_name)[i] ## Physics Collider
	
	rat_physics_collider.reparent(rat_body)
	rat_grab_collider.reparent(rat_body.grabOthersArea)
	rat_body.reparent(get_parent())
	
	rat_body.queue_free()
	num_rats -= 1
	
	update_rat_transforms()
