extends KinematicBody2D


const MOTION_SPEED = 150.0
const MAX_HEALTH = 5
const CHARACTER_INDEX_TO_PATH = {
	1: "res://assets/charwalk.png",
	2: "res://assets/betty.png"
}

puppet var puppet_pos = Vector2()
puppet var puppet_velocity = Vector2()
puppet var puppet_anim = "standing"

export var stunned = false

var current_anim = ""
var prev_bombing = false
var bomb_index = 0
var current_health = MAX_HEALTH


func init(index_char):
	var file_path_character = CHARACTER_INDEX_TO_PATH[index_char]
	get_node("sprite").texture = load(file_path_character)


func _ready():
	stunned = false
	puppet_pos = position
	gamestate.connect("game_ended_on_server", self, "_on_game_ended_on_server")


func _physics_process(_delta):
	var direction = Vector2.ZERO
	var velocity = Vector2()
	var new_anim = "standing"

	if is_network_master() && current_health >= 1:
		direction.x =  Input.get_axis("move_left", "move_right")
		direction.y = Input.get_axis("move_up", "move_down")
		var bombing = Input.is_action_pressed("set_bomb")

		if stunned:
			bombing = false
			direction = Vector2.ZERO
		if direction != Vector2.ZERO:
			direction = direction.normalized()

		velocity.x = direction.x * MOTION_SPEED
		velocity.y = direction.y * MOTION_SPEED

		if bombing and not prev_bombing:
			var bomb_name = String(get_name()) + str(bomb_index)
			var bomb_pos = position
			rpc("setup_bomb", bomb_name, bomb_pos, get_tree().get_network_unique_id())

		prev_bombing = bombing

		# Animation part
		new_anim = "standing"
		if direction != Vector2.ZERO:
			var value = velocity.y
			if velocity.y < 0:
				new_anim = "walk_up"
			elif velocity.y > 0:
				new_anim = "walk_down"
			if abs(velocity.x) > abs(velocity.y):
				if velocity.x < 0:
					new_anim = "walk_left"
				else:
					new_anim = "walk_right"

		# Setting variables on puppets
		rset("puppet_velocity", velocity)
		rset("puppet_pos", position)
		rset("puppet_anim", new_anim)
	else:
		position = puppet_pos
		velocity = puppet_velocity
		new_anim = puppet_anim

	if stunned:
		new_anim = "stunned"

	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)

	# FIXME: Use move_and_slide
	move_and_slide(velocity)
	if not is_network_master():
		puppet_pos = position # To avoid jitter


# Use sync because it will be called everywhere
remotesync func setup_bomb(bomb_name, pos, by_who):
	var bomb = preload("res://scenes/bomb.tscn").instance()
	bomb.set_name(bomb_name) # Ensure unique name for the bomb
	bomb.position = pos
	bomb.from_player = by_who
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(bomb)


puppet func stun():
	stunned = true
	current_health -= 1
	# Delete current node if health is 0 or below (the player is dead)
	if current_health <= 0:
		queue_free()


master func exploded(_by_who):
	if stunned:
		return
	# Update the score locally
	$"../../Score".rpc("modify_health", get_tree().get_network_unique_id(), current_health - 1)
	rpc("stun") # Stun puppets
	stun() # Stun master - could use sync to do both at once


func set_player_name(new_name):
	get_node("label").set_text(new_name)

# Delete the player object when the game is finished on the server side
func _on_game_ended_on_server():
	queue_free()
