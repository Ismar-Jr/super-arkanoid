extends Area2D

@export var speed = 400

func _physics_process(delta):
	global_position.y -= speed*delta

#Confere se houve colisão entre bullet and blocks
func _on_body_entered(body: Node2D) -> void:
	body.queue_free() #exclui os blocos
	queue_free() #apaga os tiros
