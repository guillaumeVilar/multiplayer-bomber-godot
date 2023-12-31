extends Control

var index_char_selected = 1

var lobby_player_id = null

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	if "--server" in OS.get_cmdline_args():
		print("Server starting up detected in lobby - disabling UI!")
		server_disable_UI()
# 	if OS.has_feature('JavaScript'):
# 		# var js_return = JavaScriptBridge.eval("navigator.userAgent;")
# 		var user_agent = JavaScript.eval("navigator.userAgent;")
# 		var width = JavaScript.eval("window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;")
# 		var debug_message = "User agent:" + str(user_agent) + " - Width screen:" + str(width)
# 		print(debug_message)
# 		debug(debug_message)

# func debug(message):
# 	$Connect/ErrorLabel.text = message

func get_lobby_player():
	if lobby_player_id == null:
		return get_node("lobbyPlayer")
	print(lobby_player_id)
	return get_node("lobbyPlayer" + str(lobby_player_id))

func disable_keyboard_zones(node:Node) -> void:
	node.pause_mode = true
	node.hide()
	node.set_physics_process(false)
	for child in node.get_children():
		child.set_deferred("monitoring", false)
		child.set_deferred("monitorable", false)

	
func enable_keyboard_zones(node:Node) -> void:
	node.pause_mode = false
	node.show()
	node.set_physics_process(true)
	for child in node.get_children():
		child.set_deferred("monitoring", true)
		child.set_deferred("monitorable", true)

func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Join.disabled = true
	
	free_lobby_player()
	disable_keyboard_zones($keyboardZones)
	$TextureRect.hide()

	var player_name = $Connect/Name.text
	$Connect/ErrorLabel.text = "Loading..."
	gamestate.join_game(player_name)

func _on_connection_success():
	$Connect.hide()
	$Players.show()
	print("Connection is a success - add local player to server")
	gamestate.addLocalPlayerToServer()


func _on_connection_failed():
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed")

func server_disable_UI():
	print("Server instance - disabling UI components")
	$Connect/Name.hide()
	$Connect/ErrorLabel.text = "SERVER INSTANCE"
	$Connect/NameLabel.text = "SERVER INSTANCE"
	$Connect/Join.disabled = true
	

func _on_game_ended():
	show()
	$Connect/ErrorLabel.set_text("")
	$Connect.show()
	$Players.hide()
	$Connect/Join.disabled = false
	instanciate_lobby_player()
	enable_keyboard_zones($keyboardZones)
	$TextureRect.show()
	


func _on_game_error(errtxt):
	$Connect/ErrorLabel.text = errtxt
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

func reset_all_other_character_selected_and_call_gamestate():
	var index_char = 1
	for button in $Players/Character_Choice.get_children():
		if index_char != index_char_selected:
			button.pressed = false
		index_char = index_char + 1
	gamestate.local_player_change_character(index_char_selected)
		
func _on_Char1_pressed():
	print("Char 1 selected")
	index_char_selected = 1
	reset_all_other_character_selected_and_call_gamestate()

func _on_Char2_pressed():
	print("Char 2 selected")
	index_char_selected = 2
	reset_all_other_character_selected_and_call_gamestate()

func do_bomb_collision(area, areaName):
	if area.name != "BombAreaCollision":
		return
	var current_name = get_lobby_player().get_node("label").text
	if current_name.length() >= 16:
		return
	if current_name.length() <= 0:
		areaName = areaName.to_upper()
		
	var new_name = current_name + areaName
	get_lobby_player().set_player_name(new_name)
	get_node("/root/Lobby/Connect/Name").set_text(new_name)
	
func free_lobby_player():
	get_lobby_player().queue_free()

func instanciate_lobby_player():
	var scene = load("res://scenes/lobbyplayer.tscn")
	var instance = scene.instance()
	lobby_player_id = instance.get_instance_id()
	instance.set_name("lobbyPlayer" + str(lobby_player_id))
	add_child(instance, true)

	
func _on_A_area_entered(area):
	do_bomb_collision(area, "a")
func _on_D_area_entered(area):
	do_bomb_collision(area, "d")
func _on_S_area_entered(area):
	do_bomb_collision(area, "s")
func _on_Q_area_entered(area):
	do_bomb_collision(area, "q")
func _on_W_area_entered(area):
	do_bomb_collision(area, "w")
func _on_E_area_entered(area):
	do_bomb_collision(area, "e")
func _on_R_area_entered(area):
	do_bomb_collision(area, "r")
func _on_T_area_entered(area):
	do_bomb_collision(area, "t")
func _on_Y_area_entered(area):
	do_bomb_collision(area, "y")
func _on_U_area_entered(area):
	do_bomb_collision(area, "u")
func _on_I_area_entered(area):
	do_bomb_collision(area, "i")
func _on_F_area_entered(area):
	do_bomb_collision(area, "f")
func _on_O_area_entered(area):
	do_bomb_collision(area, "o")
func _on_G_area_entered(area):
	do_bomb_collision(area, "g")
func _on_H_area_entered(area):
	do_bomb_collision(area, "h")
func _on_M_area_entered(area):
	do_bomb_collision(area, "m")
func _on_N_area_entered(area):
	do_bomb_collision(area, "n")
func _on_9_area_entered(area):
	do_bomb_collision(area, "9")
func _on_8_area_entered(area):
	do_bomb_collision(area, "8")
func _on_7_area_entered(area):
	do_bomb_collision(area, "7")
func _on_6_area_entered(area):
	do_bomb_collision(area, "6")
func _on_5_area_entered(area):
	do_bomb_collision(area, "5")
func _on_4_area_entered(area):
	do_bomb_collision(area, "4")
func _on_3_area_entered(area):
	do_bomb_collision(area, "3")
func _on_2_area_entered(area):
	do_bomb_collision(area, "2")
func _on_P_area_entered(area):
	do_bomb_collision(area, "p")
func _on_L_area_entered(area):
	do_bomb_collision(area, "l")
func _on_B_area_entered(area):
	do_bomb_collision(area, "b")
func _on_C_area_entered(area):
	do_bomb_collision(area, "c")
func _on_X_area_entered(area):
	do_bomb_collision(area, "x")
func _on_Z_area_entered(area):
	do_bomb_collision(area, "z")
func _on_K_area_entered(area):
	do_bomb_collision(area, "k")
func _on_J_area_entered(area):
	do_bomb_collision(area, "j")
func _on_1_area_entered(area):
	do_bomb_collision(area, "1")
func _on_0_area_entered(area):
	do_bomb_collision(area, "0")
func _on_V_area_entered(area):
	do_bomb_collision(area, "v")

func _on_Enter_area_entered(area):
	if area.name != "BombAreaCollision":
		return
	_on_join_pressed()
