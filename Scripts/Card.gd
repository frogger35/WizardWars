extends Node2D

onready var Globals = get_node("/root/Game")
var cardid = null
var count = null
var mouse_inside = false
var cardinfo = null

func _input(event):
	if event.is_action_pressed("card picked") and mouse_inside:
		if Globals.debug:
			print("playing " + cardid)
		else:
			Globals.send_message("card_played",String(cardid))
		


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
		add_child(set_card_image(cardinfo["resource"],cardinfo["cost"],cardinfo["cardName"],cardid))
		
		if(count>4):
			get_node("ToolTip").position -= Vector2(145,0)
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
	
func set_card_image(resource,cost,cardName,id):
	var back = Sprite.new()
	var topImage = Sprite.new()
	var card_element
	var image_to_load = "res://Images/" + String(id) + ".png"
	topImage.set_texture(load(image_to_load))
	if resource == 0:
		back.set_texture(Globals.card_background_ice)
		card_element = Globals.card_cost_element_ice
		get_node("BottomSquare/ColorType").color = Color("03d7f1")
	elif resource == 1:
		back.set_texture(Globals.card_background_fire)
		card_element = Globals.card_cost_element_fire
		get_node("BottomSquare/ColorType").color = Color("bc0b22")
	elif resource == 2:
		back.set_texture(Globals.card_background_arcane)
		card_element = Globals.card_cost_element_arcane
		get_node("BottomSquare/ColorType").color = Color("bb00a4")
	get_node("BottomSquare/Name/Label").text = cardName
	get_node("BottomSquare/Name/Label").set_scale(Vector2(1,1))
	get_node("BottomSquare/Cost/Label").text = String(cost)
	get_node("BottomSquare/Cost/Sprite").set_texture(card_element)
	back.add_child(topImage)
	back.set_z_index(-1)
	back.set_scale(Vector2(.075,.075))
	return(back)
	pass
