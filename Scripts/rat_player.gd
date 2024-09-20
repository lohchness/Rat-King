extends CharacterBody2D

var base_speed = 500
var base_accel = 50

var curr_speed
var curr_accel

func _ready() -> void:
	curr_speed = base_speed
	curr_accel = base_accel

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity.x = move_toward(velocity.x, curr_speed * direction.x, curr_accel)
	velocity.y = move_toward(velocity.y, curr_speed * direction.y, curr_accel)
	move_and_slide()
	
	if (direction != Vector2.ZERO):
		rotation = lerp(rotation, velocity.angle(), 20 * delta)
