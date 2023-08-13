extends Node


# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_ended_on_server()
signal game_error(what)

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer = null

var isGameCurrentlyRunning = false

# Name for my player.
var local_player = {"name": "The Warrior", "ready": false}

# Names for remote players in {id:{"name": <name>, "ready": <true/false>, "char_index": 1}} format.
remote var players = {}
var players_ready = []

# Instanciate server and client to null
var server = null
var client = null

# Web socket connection to the backend server - to run in local swap the 2 below lines
# var url = "ws://localhost:10567"
var url = "wss://multiplayer-bomberman-server-hwyxubwqlq-ew.a.run.app:443"

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	var joystick_ui = load("res://joystick/UI_Joystick.tscn").instance()
	get_tree().get_root().call_deferred("add_child", joystick_ui)
	if "--server" in OS.get_cmdline_args():
		# Run your server startup code here...
		# Using this check, you can start a dedicated server by running
		# a Godot binary (headless or not) with the `--server` command-line argument.
		# var lobby = load("res://scenes/lobby.tscn").instance()
		print("Server starting up detected!")
		host_game()
		# lobby.get_node("Lobby")._on_host_pressed()
	elif "--local" in OS.get_cmdline_args():
		url = "ws://localhost:10567"

func _process(delta):
	# Pulling information as a server:
	if server != null:
		if server.is_listening(): # is_listening is true when the server is active and listening
			var error = server.poll();
	else:
		if client != null:
			if (client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
				client.poll();


# Callback from SceneTree.
func _player_connected(id):
	print("Player connected ID: " + str(id))

	# # If this node is the server check if the game is currently running - if yes, disconnect the new client
	# if get_tree().get_network_unique_id() == 1:
	# 	# From server, send information if the game has already started and disconnect client
	# 	if isGameCurrentlyRunning:
	# 		print("Disconnecting client with id: " + str(id))
	# 		rpc_id(id, "disconnectClient")
	# 		return


remote func addPlayer(new_player_name):
	# If the game is not running - the server will send to the rest of the client the information. 
	if not get_tree().is_network_server() || isGameCurrentlyRunning:
		return
	var id = get_tree().get_rpc_sender_id()
	players[id] = {"name": new_player_name, "ready": false, "char_index": 1}
	print("Player with id: " + str(id) + " - adding the name: " + new_player_name)
	# Sync the players var among all the clients
	rset("players", players)
	for p in players:
		rpc_id(p, "check_current_players")


# Callback from SceneTree.
func _player_disconnected(id):
	print("Player disconnected with id: " + str(id))
	print("Is /root/World present? " + str(has_node("/root/World")))
	print("Current players dict: " + str(players) + " - result of bool: " + str(id in players))

	# End game if game is in progress and a player disconnected
	if has_node("/root/World") && id in players: 
		var error_message = "Player " + players[id]["name"] + " disconnected"
		print("Game Error - " + error_message)
		if get_tree().is_network_server():
			end_game_on_server()
		# Ending game on client in case of another peer disconnecting
		else:
			end_game()
		emit_signal("game_error", error_message)
	else: # Game was not in progress.
		# Unregister the disconnected player.
		unregister_player(id)


# Client function to let the customer check if able to login
func client_wait_for_server_confirmation():
	rpc_id(1, "server_check_client_authorize_to_connect")

# Server function to check if the client is authorize to connect.
# If yes, continue as normal
# If no, disconnect the clien with an error message
remote func server_check_client_authorize_to_connect():
	var id_sender = get_tree().get_rpc_sender_id()
	print("Checking if client [" + str(id_sender) + "] is authorize to join - game currently running: " + str(isGameCurrentlyRunning))
	# If the game is already running - disconnect the client
	if isGameCurrentlyRunning:
		var reason = "Game is already running"
		rpc_id(id_sender, "is_client_authorize_from_server", false, reason)
		print("Disconnecting peer with id: [" + str(id_sender) + "] - reason: " + reason)
		# server.disconnect_peer(id_sender, 1000, reason)
	else:
		# Client authorize to continue to connect
		print("Client [" + str(id_sender) + "] is authorize to join")
		rpc_id(id_sender, "is_client_authorize_from_server", true, "")
		emit_signal("connection_succeeded")


# Client function to disconnect the client from the server or continue connection
remote func is_client_authorize_from_server(is_client_authorize, reason):
	# If client is not authorize, disconnect and display error message
	print("Client is authorize to join from server: " + str(is_client_authorize) + " - reason: " + reason)
	if !is_client_authorize:
		# This is not an ideal way to disconnect client - however it is the only way for the server not to crash.
		# Things that I tried: client.disconnect_from_host and server.disconnect_peer.
		# To check if that is fixed in 4.0 or 4.1 - in the meantime we will use that in the client side. 
		# This is not cheat safe (as basically we are telling the client to disconnect instead of disconnecting from server).
		get_tree().network_peer = null
		# client.disconnect_from_host(1000, reason)
		emit_signal("game_error", reason)
	# If client is authorize, emit signal connection succeeded and carry on
	else:
		emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	print("Connection ok on server")
	client_wait_for_server_confirmation()
	# emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()

func _client_disconnected(id, was_clean_close):
	print("Client with id: [" + str(id) + "] disconnected - was_clean_close: " + str(was_clean_close))


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.
remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print("player id: " + str(id))
	players[id] = {"name": new_player_name, "ready": false}
	print("Player with id: " + str(id) + " - adding the name: " + new_player_name)
	emit_signal("player_list_changed")


func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game(spawn_points):
	print("Starting game with player list: " + str(players))
	# Change scene.
	var world = load("res://scenes/world.tscn").instance()
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("Lobby").hide()

	var player_scene = load("res://scenes/player.tscn")

	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()
		# Instantiate the character sprite chosen
		player.init(players[p_id]["char_index"])

		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position=spawn_pos
		player.set_network_master(p_id) #set unique id as master.

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(local_player["name"])
		else:
			# Otherwise set name from peer.
			player.set_player_name(players[p_id]["name"])

		world.get_node("Players").add_child(player)

	# Set up score.
	for pn in players:
		world.get_node("Score").add_player(pn, players[pn]["name"])

	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())


# The readyness is done - not allowing new players to join until the game is finished
remote func ready_to_start(id):
	assert(get_tree().is_network_server())
	print("On server - not allowing any new connection until the game ends")
	isGameCurrentlyRunning = true
	# get_tree().set_refuse_new_network_connections(true)

func are_all_players_ready():
	for p in players:
		if players[p]["ready"] == false:
			return false
	return true

# Run on the server and all peers to update the list of player. The caller is now ready.
remote func update_players_dict_on_server(players_from_client):
	var id = get_tree().get_rpc_sender_id()
	print("On server - function update player with id: " + str(id))
	players[id] = players_from_client[id]

	# Sync the players var among all the clients
	rset("players", players)
	for p in players:
		rpc_id(p, "check_current_players")

	# Refreshing on remote end with new list of player
	emit_signal("player_list_changed")

	if get_tree().is_network_server():
		# Checking if all the players are ready to start the game
		print("Checking on readyness of player dict: " + str(players))
		if are_all_players_ready() == true:
			print("Beginning the game")
			begin_game()


# Called when the ready button is pressed in the lobby. 
# This will tell all peers that the local player is ready.
func local_player_is_ready_to_start_from_lobby():
	# local_player["ready"] = !local_player["ready"]
	var local_id = get_tree().get_network_unique_id()
	players[local_id]["ready"] = !players[local_id]["ready"]
	print("players: " + str(players))
	# Run update_player_list_ready_from_lobby on all other peers to update info for local player
	rpc_id(1, "update_players_dict_on_server", players)
	# Refreshing locally list of player
	emit_signal("player_list_changed")


func local_player_change_character(char_selected):
	print("local player - new character selected: " + str(char_selected))
	var local_id = get_tree().get_network_unique_id()
	players[local_id]["char_index"] = char_selected
	# Run update_player_list_ready_from_lobby on all other peers to update info for local player
	rpc_id(1, "update_players_dict_on_server", players)


func host_game():
	server = WebSocketServer.new();
	server.listen(DEFAULT_PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server)
	


func join_game(new_player_name):
	local_player["name"] = new_player_name
	client = WebSocketClient.new();
	# We are connecting here to the websocket behind the GCP app run deployment
	# This is done so we have a secure web socket with the security automatically handled by the GCP App run environment.
	print("Connecting to url: " + url)
	var error = client.connect_to_url(url, PoolStringArray(), true);
	print("Error: " + str(error))
	get_tree().set_network_peer(client);


func get_player_dict():
	return players


func get_local_player_id():
	return get_tree().get_network_unique_id()


func begin_game():
	assert(get_tree().is_network_server())

	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	# spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 0
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points.
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)

	pre_start_game(spawn_points)

func end_game_on_server():
	if get_tree().is_network_server():
		rpc("disconnectClient")
		end_game()
	emit_signal("game_ended_on_server")

func end_game():
	print("Game is finished - allowing new players to join")
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()
	isGameCurrentlyRunning = false
	players_ready = []
	# get_tree().set_refuse_new_network_connections(false)

# Disconnect the client from the server
remote func disconnectClient():
	client.disconnect_from_host()

func addLocalPlayerToServer():
	print("Adding local player to server: " + str(local_player))
	rpc_id(1, "addPlayer", local_player["name"])

remote func check_current_players():
	print("Current players: " + str(players))
	emit_signal("player_list_changed")

