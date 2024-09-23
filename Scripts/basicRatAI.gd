extends CharacterBody2D
class_name BasicRat

@onready var ratScene = preload("res://Scenes/BasicRat.tscn")
@onready var stateChart: StateChart = $StateChart
var rng = RandomNumberGenerator.new()

@onready var sprites: Node2D = $Sprites
@onready var physicsCollider: CollisionPolygon2D = $Collision
@onready var grabOthersCollider: CollisionShape2D = $GrabOtherArea/CollisionShape2D

@onready var grabCenter = $Sprites/GrabCenter
@onready var grabOthersArea: Area2D = $GrabOtherArea
@onready var getTakenArea: Area2D = $GetTakenArea

## By default this is a solo enemy rat.
## Default groups and settings are directly set in the editor.
func _ready() -> void:
	pass

#################### SOLO ##############################

## GetTakenRadius is enabled only when solo.

var direction: Vector2
var speed = 100
var max_speed = 250
var accel = 10

var near_player = false
@onready var outline = $Sprites/Outline
@onready var center = $Sprites/Center

## FOR TESTING ONLY
@onready var WanderTimer = $WanderTimer

var is_fleeing = false
var is_moving = true

func _on_solo_state_entered() -> void:
	WanderTimer.start()
	speed = randi_range(50, 150)
	change_direction() ## RANDOM MOVEMENT
	
	#getTakenArea.add_to_group("EnemyRatSolo")
	getTakenArea.monitorable = true

func _on_solo_state_processing(delta: float) -> void:
	outline.visible = near_player

func _on_solo_state_physics_processing(delta: float) -> void:
	
	if is_fleeing:
		var desired_velocity = (global_position - pack.position).normalized() * max_speed
		var steering = desired_velocity - velocity
		direction = steering.normalized()
	
	
	rotation = lerp_angle(rotation, velocity.angle(), 10 * delta)
	velocity = direction * speed
	
	move_and_slide()

func _on_solo_state_exited() -> void:
	WanderTimer.stop()
	outline.visible = false
	
	getTakenArea.remove_from_group("EnemyRatSolo")
	getTakenArea.monitorable = false

func change_direction():
	var angle = rng.randf_range(0, 2 * PI)
	direction = Vector2(cos(angle), sin(angle))

func _on_timer_timeout() -> void:
	if !is_fleeing:
		
		change_direction()
		$WanderTimer.wait_time = randf_range(0, 3)
	

## An enemy Rat will be near a player if the GetTakenRadius is 
## colliding with PlayerRat's GrabOtherRadius.
## self.GetTakenRadius   EnemyRatSolo
## area                  PlayerRat
func entered_player_grab_radius():
	near_player = true

func exited_player_grab_radius():
	near_player = false

func entered_pack_flee_radius(p):
	pack = p
	is_fleeing = true

func exited_pack_flee_radius():
	$FleeTimer.start()

func _on_flee_timer_timeout() -> void:
	is_fleeing = false

#################### PACK (PLAYER) ##############################

## Rats controlled by the player. Here, all movement and physics is handled by
## the RatPack class. As far as this BasicRat is concerned, they are being
## controlled by an outside entity - movement, position, appearance, etc.

## RatPack will handle reparenting the following nodes:
## - This Rat's Physics CollisionPolygon2D
## - This Rat's GrabOtherRadius 

## GrabOtherRadius is enabled only when in a pack.

## Which Pack this Rat belongs to
var pack: CharacterBody2D

func add_to_pack(body: CharacterBody2D, num: int, is_first = false):
	pack = body
	
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	
	stateChart.send_event("added_to_pack")

func _on_pack_state_entered() -> void:
	grabOthersArea.monitoring = true
	getTakenArea.visible = false

func _on_pack_state_physics_processing(delta: float) -> void:
	pass # Replace with function body.

## The Sprites, CollisionShapes, and Areas have their own properties set in the editor.
func pack_update_transform(angle: float, pack_number: int):
	pass


#################### PROJECTILE ##############################


var projectile_direction
var projectile_speed = 1000
var friction = 500

@onready var projectileArea = $Projectile

func projectile_settings(dir: Vector2):
	projectile_direction = dir

func _on_projectile_state_entered() -> void:
	projectileArea.monitoring = true
	projectileArea.monitorable = true
	
	velocity = projectile_direction * projectile_speed

func _on_projectile_state_physics_processing(delta: float) -> void:
	
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	#rotate(10 * delta)
	move_and_slide()
	
	if velocity.length() < 0.01:
		stateChart.send_event("on_throw_end")

func _on_projectile_body_entered(body: Node2D) -> void:
	print("Hit something at " + str(position))
	queue_free()

func _on_projectile_state_exited() -> void:
	var t = ratScene.instantiate()
	t.position = position
	t.rotation = rotation
	add_sibling(t)
	queue_free()
