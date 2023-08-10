extends HBoxContainer


var player_labels = {}
const MAX_HEALTH = 5
var is_showing_game_over_screen = false

func _process(_delta):
	if is_showing_game_over_screen == true:
		return
	
	var rocks_left = $"../Rocks".get_child_count()
	if rocks_left == 0:
		var winner_name = ""
		var winner_score = 0
		for p in player_labels:
			if player_labels[p].score > winner_score:
				winner_score = player_labels[p].score
				winner_name = player_labels[p].name

		$"../Winner".set_text("THE WINNER IS:\n" + winner_name)
		$"../Winner".show()
		is_showing_game_over_screen = true
		gamestate.end_game_on_server()

	var number_of_player_alive_and_name_last_player = get_number_of_player_alive_and_name_last_player()
	if number_of_player_alive_and_name_last_player["nb_player_alive"] == 1 && player_labels.size() != 1:
		$"../Winner".set_text("THE WINNER IS:\n" + number_of_player_alive_and_name_last_player["last_alive_player_name"])
		$"../Winner".show()
		is_showing_game_over_screen = true
		gamestate.end_game_on_server()
	if number_of_player_alive_and_name_last_player["nb_player_alive"] == 0:
		$"../Winner".set_text("THERE IS NO WINNER IN THIS GAME")
		$"../Winner".show()
		is_showing_game_over_screen = true
		gamestate.end_game_on_server()

func get_number_of_player_alive_and_name_last_player():
	var number_of_player_alive = 0
	var player_name_alive = ""
	for player in player_labels:
		if player_labels[player].health > 0:
			number_of_player_alive += 1
			player_name_alive = player_labels[player].name
	return {"nb_player_alive": number_of_player_alive, "last_alive_player_name": player_name_alive}

# Return the label to display.
func get_score_label_for_player(player_id):
	var player = player_labels[player_id]
	return player.name + "\n score:" + str(player.score) + "\n health:" + str(player.health)

func refresh_score_and_health_for_player(player_id):
	var pl = player_labels[player_id]
	pl.label.set_text(get_score_label_for_player(player_id))

@rpc("any_peer", "call_local") func increase_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	refresh_score_and_health_for_player(for_who)

@rpc("any_peer", "call_local") 
func modify_health(player_id, new_health):
	print("player_id: " + str(player_id))
	print("player_labels: " + str(player_labels))
	assert(player_id in player_labels)
	var pl = player_labels[player_id]
	pl.health = new_health
	refresh_score_and_health_for_player(player_id)


func add_player(id, new_player_name):
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# l.set_align(Label.ALIGNMENT_CENTER)
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = preload("res://assets/montserrat.otf")
	l.set("custom_fonts/font", font)
	l.set("custom_font_size/font_size", 18)
	add_child(l)

	player_labels[id] = { name = new_player_name, label = l, score = 0, health = MAX_HEALTH }
	refresh_score_and_health_for_player(id)


func _ready():
	$"../Winner".hide()
	is_showing_game_over_screen = false
	set_process(true)


func _on_exit_game_pressed():
	gamestate.end_game()
