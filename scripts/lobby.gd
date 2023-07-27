extends Control


func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")


func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	gamestate.join_game(player_name)

func _on_connection_success():
	$Connect.hide()
	$Players.show()
	print("Connection is a success - add local player to server")
	gamestate.addLocalPlayerToServer()


func _on_connection_failed():
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed - a game is already running.")


func _on_game_ended():
	show()
	$Connect/ErrorLabel.set_text("")
	$Connect.show()
	$Players.hide()
	$Connect/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_minsize()
	$Connect/Join.disabled = false
	$Connect.show()
	$Players.hide()


func refresh_lobby():
	# Clear current list
	$Players/List.clear()

	# Display local player on top
	var local_player_id = gamestate.get_local_player_id()

	# Get all player list from gamestate object
	var players = gamestate.get_player_dict()
	for p_id in players:
		var status_string = "Ready" if players[p_id]["ready"] else "Not ready"
		if p_id == local_player_id:
			status_string = status_string + " - (You)"

		$Players/List.add_item(players[p_id]["name"] + " - " + status_string)


func _on_Ready_pressed():
	print("Ready button has been pressed")
	gamestate.local_player_is_ready_to_start_from_lobby()
