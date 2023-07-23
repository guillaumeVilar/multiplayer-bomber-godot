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


func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_minsize()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func refresh_lobby():
	# Clear current list
	$Players/List.clear()

	# Display local player on top
	var local_player = gamestate.get_local_player()
	var ready_status_string = "Ready" if local_player["ready"] else "Not ready"
	$Players/List.add_item(local_player["name"] + " - " + ready_status_string + " - (You)")
	
	# Get all player list from gamestate object
	var players = gamestate.get_player_list()
	players.sort()
	for p in players:
		ready_status_string = "Ready" if p["ready"] else "Not ready"
		$Players/List.add_item(p["name"] + " - " + ready_status_string)

	$Players/Start.disabled = not get_tree().is_network_server()


func _on_Ready_pressed():
	print("Ready button has been pressed")
	gamestate.local_player_is_ready_to_start_from_lobby()
