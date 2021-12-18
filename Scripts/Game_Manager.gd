extends Node

# The URL we will connect to.
onready var enemy_prefab = preload("res://Scenes/Enemy.tscn")
onready var player_prefab = preload("res://Scenes/Player.tscn")
onready var card_prefab = preload("res://Scenes/Card.tscn")
onready var card_background_fire = preload("res://Images/fire.png")
onready var card_background_ice = preload("res://Images/ice.png")
onready var card_background_arcane = preload("res://Images/arcane.png")
onready var card_cost_element_ice = preload("res://Images/ice_crystal.png")
onready var card_cost_element_fire = preload("res://Images/fire_crystal.png")
onready var card_cost_element_arcane = preload("res://Images/arcane_crystal.png")
export var websocket_url = "ws://localhost:8080"
var my_id = null
var cards_in_game = {}
var escape_menu = true
var me = null
var enemy = null
var matchId = null
var playerTurn = null
var turnCounter = null
var playerOne = null
var playerTwo = null
var players = null
var first_person = 0
var card_count = 0
var debug = false
# Our WebSocketClient instance.
var _client = WebSocketClient.new()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_node("Menu").visible = escape_menu
		if !escape_menu:
			escape_menu = true
		else:
			escape_menu = false

func _process(_delta):
	_client.poll()

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)

func _on_data():
	var test = _client.get_peer(1).get_packet().get_string_from_ascii()
	var results = JSON.parse(test).result
	if(results.msg == "sync"):
		sync_data(results)
	elif results.msg == "matchFound":
		setup_game(results)
	elif results.msg == "card-played":
		update_game(results)
	elif results.msg == "error":
		print("error from server")

func _on_Find_Match_pressed():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	pass 

func sync_data(data):
	my_id = data.socketId
	cards_in_game = data.cards
	send_message("sync","null")
	pass

func _on_send_test_data_pressed():
	var data = {"msg":"queue"}
	var jstr = JSON.print(data).to_ascii()
	_client.get_peer(1).put_packet(jstr)
	pass # Replace with function body.
	
func send_message(msg,info):
	var data = null
	if msg == "sync":
		data = {"msg":"queue"}
		get_node("Menu").visible = false
		get_node("Finding Game").visible = true
	if msg == "card_played":
		data = {"msg": "play-card", "cardId": info, "matchId": String(matchId)}
		
	var jstr = JSON.print(data).to_ascii()
	_client.get_peer(1).put_packet(jstr)
	
	
func setup_game(data):
	get_node("Finding Game").visible = false
	get_node("Menu").visible = false
	#get_node("ReadyFight").play()
	playerTurn = data.playerTurn
	turnCounter = data.turnCounter
	players = data.players
	if matchId == null:
		get_node("GameScreen").visible = true
		if	data.players[0].socketId == my_id:
			first_person = 0
		else:
			first_person = 1
	for x in players:
		if(x.socketId == my_id):
			playerOne = x
		else:
			playerTwo = x
	matchId = data.matchId
	var me = player_prefab.instance()
	var enemy = enemy_prefab.instance()
	me.init(playerOne.health, playerOne.shield,playerOne.socketId, playerOne.resources,"red")
	enemy.init(playerTwo.health, playerTwo.shield,playerTwo.socketId, playerTwo.resources,"purp")
	get_node("GameScreen/players").add_child(me)
	get_node("GameScreen/players").add_child(enemy)
	pass

func update_game(info):
	for x in players:
		if(x.socketId == my_id):
			playerOne = x
		else:
			playerTwo = x
	me.update(playerOne.health, playerOne.shield,playerOne.socketId, playerOne.resources,"red")
	enemy.update
	pass

func update_players():
	for x in range(get_node("GameScreen/players").get_child_count()):
		get_node("GameScreen/players").get_child(x).queue_free()
	
	me.health = playerOne.health
	me.shield = playerOne.shield
	me.id = playerOne.socketId
	for x in playerOne.resources:
		if x.type == "ice":
			me.ice_g = x.genRate 
			me.ice_v = x.value
		if x.type == "fire":
			me.fire_g = x.genRate
			me.fire_v = x.value
		if x.type == "arcane":
			me.arcane_g = x.genRate
			me.arcane_v = x.value
	get_node("GameScreen/players").add_child(me)
	var enemy = enemy_prefab.instance()
	enemy.position = Vector2(700,200)
	enemy.health = playerTwo.health
	enemy.id = playerTwo.socketId
	enemy.shield = playerTwo.shield
	for x in playerTwo.resources:
		if x.type == "ice":
			enemy.ice_g = x.genRate 
			enemy.ice_v = x.value
		if x.type == "fire":
			enemy.fire_g = x.genRate
			enemy.fire_v = x.value
		if x.type == "arcane":
			enemy.arcane_g = x.genRate
			enemy.arcane_v = x.value
	get_node("GameScreen/players").add_child(enemy)
	pass

func draw_deck():
	for x in range(get_node("GameScreen/Hand").get_child_count()):
		get_node("GameScreen/Hand").get_child(x).queue_free()
	var card
	card_count = 0
	for x in playerOne.cards:
		card = card_prefab.instance()
		get_node("GameScreen/Hand").add_child(card)
		card.cardid = x
		card.position = Vector2(100+(200*card_count),700)
		card_count +=1
		card.count = card_count
		card.updateInfo()
	pass
	
func draw_resources():
	print("resource")
	pass

func update_turns():
	print("update turns")
	if(playerTurn == first_person):
		print("my turn")
	else:
		print("enemy turn")
	pass


func _on_Button_pressed():
	send_message("card_played","fire1")
	pass # Replace with function body.

func _on_Exit_Button_pressed():
	_client.disconnect_from_host()
	get_tree().quit()

func _on_Exit_Game_pressed():
	get_tree().quit()
	pass # Replace with function body.


func _on_ServerInfo_text_changed():
	websocket_url = "ws://" + get_node("Menu/ServerInfo").text
	pass # Replace with function body.

func winner(data):
	get_node("Menu").visible = false
	get_node("GameScreen").visible = false
	get_node("Exit Game").visible = true
	if data.winner == my_id:
		get_node("Winner").visible = true
		get_node("Winning").play()
	if data.winner != my_id:
		get_node("Loser").visible = true
		get_node("Losing").play()
	pass
