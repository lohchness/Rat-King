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
@onready var ratBodies = $BasicRatBodies
var num_rats = 0
var last_rat_added: BasicRat

func _ready() -> void:
	curr_speed = base_speed
	curr_accel = base_accel
	
	## Add initial rat
	var firstrat = BasicRat.instantiate()
	ratBodies.add_child(firstrat)
	
	firstrat.call_deferred("add_to_pack", self) ## Wait for tree to finish initializing
	add_rat_to_this_pack(firstrat)

func _physics_process(delta: float) -> void:
	#if num_rats == 1:
		#last_rat_added.position = last_rat_added.center.position
		#last_rat_added.physicsCollider.position = last_rat_added.center.position
		#last_rat_added.sprites.position = last_rat_added.center.position
	
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
		
		if (len(bodies) > 0):
			#add_rat_to_this_pack(bodies.pick_random())
			bodies.sort_custom(sort_bodies_distance)
			add_rat_to_this_pack(bodies[0])

func sort_bodies_distance(a: Node2D, b: Node2D):
	if a.position.distance_squared_to(self.position) < b.position.distance_squared_to(self.position):
		return true
	return false

## Reparents the BasicRat and its nodes.
## The BasicRat CharacterBody2D will be a direct child of the RatPack.
func add_rat_to_this_pack(body: BasicRat):
	last_rat_added = body
	num_rats += 1
	body.add_to_pack(self)
	
	#print("Pack local position: " + str(position))
	#print("Pack global position: " + str(global_position))
	
	body.reparent(self)
	body.add_to_group("PlayerRatCharacterBodies")
	
	## APPEARANCE
	body.sprites.reparent(ratBodies)
	
	## COLLISION AND AREAS
	var collision: CollisionPolygon2D = body.physicsCollider
	collision.reparent(self)
	collision.add_to_group("PlayerRatCollider")
	
	## Get CollisionShape of GrabOthersRadius
	## This will be put into GrabOthers Area2D to detect other rats to grab.
	var grab_shape = body.grabOthersCollider
	grab_shape.reparent(grabOthersAreas)
	
	update_rat_transforms()

## Called when GrabOthers collides with another Area.
func _on_grab_others_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyRatSolo"):
		area.get_parent().call("entered_player_grab_radius")

func _on_grab_others_area_exited(area: Area2D) -> void:
	if area.is_in_group("EnemyRatSolo"):
		area.get_parent().call("exited_player_grab_radius")

func update_rat_transforms():
	
	# ACCESSING CHILDREN AND INDICES
	#var rats = grabOthersAreas.get_children()
	#var sprites = ratBodies.get_children()
	#assert(len(sprites) == ratBodies.get_child_count())
	#for i in range(len(rats)):
		#sprites[i].modulate = Color(1, 1, 1, (sprites[i].get_index() + 1 / float(len(sprites))))
	
	## BasicRatBodies   Sprites
	## GrabOthers       CollisionPolygon2Ds
	## 
	
	var rat_bodies = ratBodies.get_children() ## Rat Sprites
	var rat_grab_areas = grabOthersAreas.get_children() ## Grab Colliders
	var rat_colliders = get_tree().get_nodes_in_group("PlayerRatCollider") ## Physics Collider
	var rat_characters = get_tree().get_nodes_in_group("PlayerRatCharacterBodies")
	
	assert(len(rat_colliders) == len(rat_bodies) and len(rat_bodies) == len(rat_grab_areas))
	
	for i in range(len(rat_bodies)):
		var pack_rotation: float = 2 * PI * i / len(rat_colliders)
		#rat_bodies[i].global_rotation = pack_rotation
		#rat_grab_areas[i].global_rotation = pack_rotation
		#rat_colliders[i].global_rotation = pack_rotation
		#
		#rat_bodies[i].global_position = position
		#rat_grab_areas[i].global_position = position
		#rat_colliders[i].global_position = position
		rat_characters[i].pack_update_transform(pack_rotation)
		
		print_debug("here")
