extends CharacterBody2D
class_name BasicRat

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
var accel = 10

var near_player = false
@onready var outline = $Sprites/Outline
@onready var center = $Sprites/Center

## FOR TESTING ONLY
@onready var WanderTimer = $WanderTimer

func _on_solo_state_entered() -> void:
	WanderTimer.start()
	change_direction() ## RANDOM MOVEMENT
	
	#getTakenArea.add_to_group("EnemyRatSolo")
	getTakenArea.monitorable = true

func _on_solo_state_processing(delta: float) -> void:
	outline.visible = near_player

func _on_solo_state_physics_processing(delta: float) -> void:
	return
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
	change_direction()

## An enemy Rat will be near a player if the GetTakenRadius is 
## colliding with PlayerRat's GrabOtherRadius.
## self.GetTakenRadius   EnemyRatSolo
## area                  PlayerRat
func entered_player_grab_radius():
	near_player = true

func exited_player_grab_radius():
	near_player = false

#################### PACK (PLAYER) ##############################

## Rats controlled by the player. Here, all movement and physics is handled by
## the RatPack class. As far as this BasicRat is concerned, they are being
## controlled by an outside entity - movement, position, appearance, etc.

## RatPack will handle reparenting the following nodes:
## - This Rat's Physics CollisionPolygon2D
## - This Rat's GrabOtherRadius 

## GrabOtherRadius is enabled only when in a pack.

## Which Pack this Rat belongs to
var pack: RatPack

func add_to_pack(body: RatPack, num: int, is_first = false):
	pack = body
	stateChart.send_event("added_to_pack")

func _on_pack_state_entered() -> void:
	grabOthersArea.monitoring = true
	getTakenArea.visible = false

func _on_pack_state_physics_processing(delta: float) -> void:
	pass # Replace with function body.

## The Sprites, CollisionShapes, and Areas have their own properties set in the editor.
func pack_update_transform(angle: float, pack_number: int):
	pass
