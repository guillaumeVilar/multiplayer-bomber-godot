extends Node2D

var players = null


# Called when the node enters the scene tree for the first time.
func _ready():
	players = gamestate.players
	init_world()


# Get spawn positions for each player
func get_spawn_points(players):
	var spawn_points = {}
	# spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 0
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	return spawn_points


# Initialize the world for every peer
func init_world():
	var spawn_points = get_spawn_points(players)
	var player_scene = load("res://scenes/player.tscn")

	for p_id in spawn_points:
		var spawn_pos = get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()
		# Instantiate the character sprite chosen
		player.init(players[p_id]["char_index"])

		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position=spawn_pos
		player.set_network_master(p_id) # set unique id as master.

		player.set_player_name(players[p_id]["name"]) # set player's name

		get_node("Players").add_child(player)

	# Set up score.
	for pn in players:
		get_node("Score").add_player(pn, players[pn]["name"])