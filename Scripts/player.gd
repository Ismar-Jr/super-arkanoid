extends CharacterBody2D

@export var speed = 400
	
	
func _physics_process(delta):
	
	velocity.x = 0
	
	if Input.is_action_pressed("left") and GameManager.started:
		velocity.x -= speed
		
	if Input.is_action_pressed("right") and GameManager.started:
		velocity.x += speed
	
	move_and_collide(velocity * delta)
		
		
