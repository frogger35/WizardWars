extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var speed = 50
var intial_pos_x


# Called when the node enters the scene tree for the first time.
func _ready():
	rand_seed(int(OS.get_time().second))
	position.y = rand_range(-10,50)
	position.x = rand_range(-100,1100)
	scale.x = rand_range(1,1.5)
	scale.y = rand_range(1,1.5)
	intial_pos_x = position.x
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += speed*delta
	if(position.x > 1100):
		position.x = -50
	pass
