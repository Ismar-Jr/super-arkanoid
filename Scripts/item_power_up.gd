extends CharacterBody2D

@export var fall_speed: float = 80.0
@export var rotation_speed: float = 60.0

func _physics_process(delta: float) -> void:
	velocity.y = fall_speed
	rotation_degrees += rotation_speed * delta
	move_and_slide()
