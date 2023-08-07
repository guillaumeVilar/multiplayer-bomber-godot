# Launch this test script with: godot --script scripts/test.gd
extends SceneTree

var player_labels = {}


func get_number_of_player_alive_and_name_last_player():
	var number_of_player_alive = 0
	var player_name_alive = ""
	for player in player_labels:
		if player_labels[player].health > 0:
			number_of_player_alive += 1
			player_name_alive = player_labels[player].name
	return {"nb_player_alive": number_of_player_alive, "last_alive_player_name": player_name_alive}



func _init():

    player_labels[1] = { name = "riri", label = "label", score = 0, health = 0 }
    player_labels[2] = { name = "bibi", label = "label", score = 0, health = 0 }
    print("toto")
    print(1 in player_labels)
    # print(player_labels.size())
    # for key in player_labels:
        # print(key)
    # print(get_number_of_player_alive_and_name_last_player())
    quit()