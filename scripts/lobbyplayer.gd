extends KinematicBody2D

signal hit

var speed = 200 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
var current_anim = ""
var bomb_index = 0
var prev_bombing = false


func _ready():
	screen_size = get_viewport_rect().size
	puppet_pos = position
	set_player_name("")

func _physics_process(_delta):
	var direction = Vector2.ZERO
	var velocity = Vector2()
	direction.x =  Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	velocity.x = direction.x * speed
	velocity.y = direction.y * speed

	# var velocity = Vector2()
	# if Input.is_action_pressed("move_left"):
	# 	velocity += Vector2(-1, 0)
	# if Input.is_action_pressed("move_right"):
	# 	velocity += Vector2(1, 0)
	# if Input.is_action_pressed("move_up"):
	# 	velocity += Vector2(0, -1)
	# if Input.is_action_pressed("move_down"):
	# 	velocity += Vector2(0, 1)

	var new_anim = "standing"
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

		# elif velocity.x < 0:
		# 	new_anim = "walk_left"
		# elif velocity.x > 0:
		# 	new_anim = "walk_right"

	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)
	
	move_and_slide(velocity)
	
	var lobby = get_node("/root/Lobby")

	var bounds_y_bot = lobby.rect_size.y  
	var bounds_x_right = lobby.rect_size.x 
	
	global_position.y = clamp(global_position.y, 0, bounds_y_bot)
	global_position.x = clamp(global_position.x, 0, bounds_x_right)
#	
#	for i in get_slide_count():
#		var collision = get_slide_collision(i)
#		print("Collided with: ", collision.collider.name)
	
	var bombing = Input.is_action_pressed("set_bomb")
	if bombing and not prev_bombing:
		var bomb_name = String(get_name()) + str(bomb_index)
		var bomb_pos = position
		setup_bomb(bomb_name, bomb_pos)
	prev_bombing = bombing

func set_player_name(new_name):
	get_node("label").set_text(new_name)
	
func setup_bomb(bomb_name, pos):
	var bomb = preload("res://scenes/bomb.tscn").instance()
	bomb.set_name(bomb_name) # Ensure unique name for the bomb
	bomb.position = pos
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(bomb)
