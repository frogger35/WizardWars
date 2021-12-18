extends Node2D

var health = "100"
var id = "0"
var shield = "0"
var ice_g = "0"
var ice_v = "0"
var fire_g = "0"
var fire_v = "0"
var arcane_g = "0"
var arcane_v = "0"
var resource = null
var color = null
var isTurn = false

func _process(delta):
	get_node("health").text = String(health) #+ String(id)
	get_node("Shield").text = String(shield)
	get_node("Fire").text = String(fire_g) + " / " + String(fire_v)
	get_node("Ice").text = String(ice_g) + " / " + String(ice_v)
	get_node("Arcane").text = String(arcane_g) + " / " + String(arcane_v)

func init(phealth,pshield,pid,presource,pcolor):
	health = phealth
	shield = pshield
	id = pid
	resource = presource
	color = pcolor
	
