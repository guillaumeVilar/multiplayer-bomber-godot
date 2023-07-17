extends HBoxContainer


var player_labels = {}
const MAX_HEALTH = 5

func _process(_delta):
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

# Return the label to display.
func get_score_label_for_player(player_id):
	var player = player_labels[player_id]
	return player.name + "\n score:" + str(player.score) + "\n health:" + str(player.health)

func refresh_score_and_health_for_player(player_id):
	var pl = player_labels[player_id]
	pl.label.set_text(get_score_label_for_player(player_id))

remotesync func increase_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	refresh_score_and_health_for_player(for_who)

remotesync func modify_health(player_id, new_health):
	print("player_id: " + str(player_id))
	print("player_labels: " + str(player_labels))
	assert(player_id in player_labels)
	var pl = player_labels[player_id]
	pl.health = new_health
	refresh_score_and_health_for_player(player_id)


func add_player(id, new_player_name):
	var l = Label.new()
	l.set_align(Label.ALIGN_CENTER)
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = DynamicFont.new()
	font.set_size(18)
	font.set_font_data(preload("res://assets/montserrat.otf"))
	l.add_font_override("font", font)
	add_child(l)

	player_labels[id] = { name = new_player_name, label = l, score = 0, health = MAX_HEALTH }
	refresh_score_and_health_for_player(id)


func _ready():
	$"../Winner".hide()
	set_process(true)


func _on_exit_game_pressed():
	gamestate.end_game()
