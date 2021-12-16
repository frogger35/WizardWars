extends Node

# The URL we will connect to.
onready var enemy_prefab = preload("res://Enemy.tscn")
onready var player_prefab = preload("res://Player.tscn")
onready var card_prefab = preload("res://Card.tscn")
onready var card_background_fire = preload("res://fire.png")
onready var card_background_ice = preload("res://ice.png")
onready var card_background_arcane = preload("res://arcane.png")
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

func _ready():
	# Connect base signals to get notified of connection open, close, and errors.
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_node("Menu").visible = escape_menu
		if !escape_menu:
			escape_menu = true
		else:
			escape_menu = false

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("Closed, clean: ", was_clean)
	set_process(false)


func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected with protocol: ", proto)
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	#_client.get_peer(1).put_packet("Test packet".to_utf8())


func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var test = _client.get_peer(1).get_packet().get_string_from_ascii()
	var results = JSON.parse(test).result
	if(results.msg == "sync"):
		sync_data(results)
	elif results.msg == "matchFound" or results.msg == "card-played" :
		play_game(results)
	elif results.msg == "error":
		print("error from server")


func _process(_delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()


func _on_Exit_Button_pressed():
	_client.disconnect_from_host()
	get_tree().quit()
	pass # Replace with function body.


func _on_Find_Match_pressed():
	if !debug:
		_client.connect("connection_closed", self, "_closed")
		_client.connect("connection_error", self, "_closed")
		_client.connect("connection_established", self, "_connected")
		_client.connect("data_received", self, "_on_data")

		# Initiate connection to the given URL.
		var err = _client.connect_to_url(websocket_url)
		if err != OK:
			print("Unable to connect")
			set_process(false)
	else:
		play_game("data")
	pass # Replace with function body.

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
	print("sending message ")
	var data = null
	if msg == "sync":
		data = {"msg":"queue"}
		print("queing up")
		get_node("Menu").visible = false
		get_node("Finding Game").visible = true
	if msg == "card_played":
		print("played card")
		data = {"msg": "play-card", "cardId": info, "matchId": String(matchId)}
	var jstr = JSON.print(data).to_ascii()
	_client.get_peer(1).put_packet(jstr)
	
	
func play_game(data):
	if debug:
		get_node("Menu").visible = false
		get_node("GameScreen").visible = true
		draw_debug()
	else:
		get_node("Finding Game").visible = false
		if data.winner == null:
			get_node("Menu").visible = false
			get_node("ReadyFight").play()
			playerTurn = data.playerTurn
			turnCounter = data.turnCounter
			players = data.players
			if matchId == null:
				get_node("GameScreen").visible = true
				print("setting up game")
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
			print("playing game")
			update_turns()
			draw_players()
			draw_deck()
			draw_resources()
		else:
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

func draw_debug():
	var cards = ["red1","red1","red1","red1","ice1","ice1","ice1","ice1"]
	for x in range(get_node("GameScreen/players").get_child_count()):
		get_node("GameScreen/players").get_child(x).queue_free()
	var p1 = player_prefab.instance()
	var p2 = player_prefab.instance()
	p1.position = Vector2(300,200)
	p2.position = Vector2(700,200)
	get_node("GameScreen/players").add_child(p1)
	get_node("GameScreen/players").add_child(p2)
	for x in range(get_node("GameScreen/Hand").get_child_count()):
		get_node("GameScreen/Hand").get_child(x).queue_free()
	var card
	card_count = 0
	for x in cards:
		card = card_prefab.instance()
		get_node("GameScreen/Hand").add_child(card)
		card.cardid = x
		card.position = Vector2(65+(115*card_count),450)
		card_count +=1
		card.updateInfo()
	pass

func draw_players():
	for x in range(get_node("GameScreen/players").get_child_count()):
		get_node("GameScreen/players").get_child(x).queue_free()
	var me = player_prefab.instance()
	me.position = Vector2(300,200)
	me.health = playerOne.health
	me.shield = playerOne.shield
	me.id = playerOne.socketId
	for x in playerOne.resources:
		print(x.type)
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
	print("deck")
	for x in range(get_node("GameScreen/Hand").get_child_count()):
		get_node("GameScreen/Hand").get_child(x).queue_free()
	var card
	card_count = 0
	print(playerOne.cards)
	for x in playerOne.cards:
		card = card_prefab.instance()
		get_node("GameScreen/Hand").add_child(card)
		card.cardid = x
		card.position = Vector2(65+(115*card_count),450)
		card_count +=1
		card.updateInfo()
	pass
	
func draw_resources():
	print("resource")
	pass

func update_turns():
	print("update turns")
	if(playerTurn == first_person):
		get_node("GameScreen/ColorRect/Player_Turn").text = "Red Wizard"
	else:
		get_node("GameScreen/ColorRect/Player_Turn").text = "Purple Wizard"
	
	get_node("GameScreen/ColorRect/Turn_Counter").text = String(turnCounter)
	pass


func _on_Button_pressed():
	send_message("card_played","fire1")
	pass # Replace with function body.


func _on_Exit_Game_pressed():
	get_tree().quit()
	pass # Replace with function body.



func _on_ServerInfo_text_changed():
	websocket_url = "ws://" + get_node("Menu/ServerInfo").text
	pass # Replace with function body.
