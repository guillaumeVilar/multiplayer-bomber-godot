extends Node


# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer = null

# Name for my player.
var local_player = {"name": "The Warrior", "ready": false}

# Names for remote players in {id:{name: <name>, ready: <true/false>}} format.
var players = {}
var players_ready = []

# Instanciate server and client to null
var server = null
var client = null

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	if "--server" in OS.get_cmdline_args():
		# Run your server startup code here...
		# Using this check, you can start a dedicated server by running
		# a Godot binary (headless or not) with the `--server` command-line argument.
		# var lobby = load("res://scenes/lobby.tscn").instance()
		print("Server starting up detected!")
		host_game()
		# lobby.get_node("Lobby")._on_host_pressed()

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
	emit_signal("player_list_changed")

	# If this node is the server, does not send any extra information to the new peer connected
	if get_tree().get_network_unique_id() == 1:
		print("This is the server doing nothing here.")
		return
	print("Player connected ID: " + str(id))
	# Called on both clients and server when a peer connects. Send local info to the new peer.
	rpc_id(id, "register_player", local_player["name"])	


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if get_tree().is_network_server():
			# TODO: To fix to support new format.
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print(id)
	players[id] = {"name": new_player_name, "ready": false}
	print("Player with id: " + str(id) + " - adding the name: " + new_player_name)
	emit_signal("player_list_changed")


func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game(spawn_points):
	# Change scene.
	var world = load("res://scenes/world.tscn").instance()
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("Lobby").hide()

	var player_scene = load("res://scenes/player.tscn")

	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()

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
	world.get_node("Score").add_player(get_tree().get_network_unique_id(), local_player["name"])
	for pn in players:
		world.get_node("Score").add_player(pn, players[pn]["name"])

	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()


remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func are_all_players_ready():
	for p in players:
		if players[p]["ready"] == false:
			return false
	return true

# Run on the server and all peers to update the list of player. The caller is now ready.
remote func update_player_list_ready_from_lobby(player):
	var id = get_tree().get_rpc_sender_id()
	print("On remote - function update player with id: " + str(id))
	players[id] = player
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
	local_player["ready"] = !local_player["ready"]
	# Run update_player_list_ready_from_lobby on all other peers to update info for local player
	rpc("update_player_list_ready_from_lobby", local_player)
	# Refreshing locally list of player
	emit_signal("player_list_changed")


func host_game():
	server = WebSocketServer.new();
	server.listen(DEFAULT_PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server)
	


func join_game(new_player_name):
	local_player["name"] = new_player_name
	client = WebSocketClient.new();
	# var url = "wss://" + ip + ":" + str(DEFAULT_PORT) 
	# We are connecting here to the websocket behind the GCP app run deployment
	# This is done so we have a secure web socket with the security automatically handled by the GCP App run environment.
	var url = "wss://multiplayer-bomberman-server-hwyxubwqlq-ew.a.run.app:443"
	var error = client.connect_to_url(url, PoolStringArray(), true);
	print(error)
	get_tree().set_network_peer(client);


func get_player_list():
	return players.values()


func get_local_player():
	return local_player


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


func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()
