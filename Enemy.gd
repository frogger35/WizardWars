extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var health = "100"
var shield = "0"
var id = "0"
var ice_g = "0"
var ice_v = "0"
var fire_g = "0"
var fire_v = "0"
var arcane_g = "0"
var arcane_v = "0"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("health").text = String(health) #+ String(id)
	get_node("Shield").text = String(shield)
	get_node("Fire").text = String(fire_g) + " / " + String(fire_v)
	get_node("Ice").text = String(ice_g) + " / " + String(ice_v)
	get_node("Arcane").text = String(arcane_g) + " / " + String(arcane_v)
	pass
