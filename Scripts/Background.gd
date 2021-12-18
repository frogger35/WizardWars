extends Node2D

onready var cloud_scene = preload("res://Scenes/Cloud.tscn")
var clouds = 30
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	for x in range(clouds):
		var new_cloud = cloud_scene.instance()
		add_child(new_cloud)
		new_cloud.speed = rand_range(0,40)
		pass
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

