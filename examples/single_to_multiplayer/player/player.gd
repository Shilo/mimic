extends CharacterBody2D

## Movement speed in pixels per second.
@export var speed: int = 300


func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	move_and_slide()
