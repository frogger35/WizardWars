extends Node2D

onready var Globals = get_node("/root/Game")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var cardid = null
var mouse_inside = false
var cardinfo = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cardid != null:
		get_node("Label").text = String(cardid)
	pass

func _input(event):
	if event.is_action_pressed("card picked") and mouse_inside:
		if Globals.debug:
			print("playing " + cardid)
		else:
			Globals.send_message("card_played",String(cardid))
		#Globals.get_node(p1)
		


func _on_ColorRect_mouse_exited():
	mouse_inside = false
	get_node("ToolTip").visible = false
	get_node("ToolTip").set_z_index(VisualServer.CANVAS_ITEM_Z_MIN)
	pass # Replace with function body.


func _on_ColorRect_mouse_entered():
	mouse_inside = true
	get_node("ToolTip").visible = true
	get_node("ToolTip").set_z_index(VisualServer.CANVAS_ITEM_Z_MAX)
	pass # Replace with function body.

func updateInfo():
	if Globals.debug:
		get_node("ToolTip/Rect/Label2").text = "Card"
	else:
		var label = get_node("ToolTip/Rect/Label2")
		for x in Globals.cards_in_game:
			if x.id == cardid:
				cardinfo = x
		
		#label.text = String(cardinfo["cardName"])
		label.text = String(cardinfo["cardName"]) + "\n" + effect_label(cardinfo["effect"],cardinfo["target"]) + "\n" + String(abs(cardinfo["value"]))+ "\n" + resource_cost(cardinfo["resource"], cardinfo["cost"]) 
		add_child(set_background(cardinfo["resource"]))
	pass
	

func effect_label(effect,target):
	#target 0 self 1 enemy
	#effect 0 dam/heal 1 mana shield 2 resource 3 resource gen
	var text = "tooltip"
	if target == 0:
		if effect == 0:
			text = "Heal for "
		elif effect == 1:
			text = "Shield for "
		elif effect == 2:
			text = "Gain "
		elif effect == 3:
			text = "Gain "
	else:
		text = "Enemy "
		if effect == 0:
			text = "Damage enemy for "
		elif effect == 2:
			text = "Destroy "
		elif effect == 3:
			text = "Destroy "
	
	return(text)
	
	
	pass

func resource_cost(resource,cost):
	#resouce = what it takes to buy 0 ice 1 fire 2 arcane
	#cost = how much to buy
	var element = "error"
	if resource == 0:
		element = "ice"
	elif resource == 1:
		element = "fire"
	elif resource == 2:
		element = "arcane"
	
	return("Costs " + String(cost) + " " + element)
	
	pass
	
func set_background(resource):
	var back = Sprite.new()
	if resource == 0:
		back.set_texture(Globals.card_background_ice)
	elif resource == 1:
		back.set_texture(Globals.card_background_fire)
	elif resource == 2:
		back.set_texture(Globals.card_background_arcane)
	back.set_z_index(-1)
	back.set_scale(Vector2(.05,.05))
	return(back)
	pass
