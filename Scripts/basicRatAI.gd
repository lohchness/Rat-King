extends CharacterBody2D

@onready var stateChart: StateChart = get_node("StateChart")
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	pass

#################### SOLO ##############################

var speed = 100
var accel = 10

var near_player = false
@onready var outline = $Outline
@onready var WanderTimer = $WanderTimer

func _on_solo_state_entered() -> void:
	WanderTimer.start()
	change_direction()	

func _on_solo_state_processing(delta: float) -> void:
	outline.visible = near_player

func _on_solo_state_physics_processing(delta: float) -> void:
	rotation = lerp_angle(rotation, velocity.angle(), 20 * delta)
	move_and_slide()

func _on_solo_state_exited() -> void:
	WanderTimer.stop()
	outline.visible = false

func change_direction():
	var angle = rng.randf_range(0, 2 * PI)
	velocity = Vector2(cos(angle), sin(angle)) * speed

func _on_timer_timeout() -> void:
	change_direction()

## If a player's rat is near an enemy rat
func _on_get_taken_radius_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerRat"):
		near_player = true

func _on_get_taken_radius_area_exited(area: Area2D) -> void:
	if area.is_in_group("PlayerRat"):
		near_player = false

#################### PACK (PLAYER) ##############################

## Rats controlled by the player. Here, all movement and physics is handled by
## the RatPack class. This Rat's Collision polygon will be reparented to RatPack
## and will be deleted here.

var pack: RatPack

func add_to_pack(r: RatPack):
	pack = r
	stateChart.send_event("added_to_pack")
	
	## 
	$GrabOtherRadius.add_to_group("PlayerRat")

func _on_pack_state_entered() -> void:
	pass

## Polling
func _on_pack_state_input(event: InputEvent) -> void:
	
	pass # Replace with function body.
