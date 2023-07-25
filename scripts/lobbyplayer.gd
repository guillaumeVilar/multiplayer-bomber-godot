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
	var velocity = Vector2()
	if Input.is_action_pressed("move_left"):
		velocity += Vector2(-1, 0)
	if Input.is_action_pressed("move_right"):
		velocity += Vector2(1, 0)
	if Input.is_action_pressed("move_up"):
		velocity += Vector2(0, -1)
	if Input.is_action_pressed("move_down"):
		velocity += Vector2(0, 1)

	var new_anim = "standing"
	if velocity.y < 0:
		new_anim = "walk_up"
	elif velocity.y > 0:
		new_anim = "walk_down"
	elif velocity.x < 0:
		new_anim = "walk_left"
	elif velocity.x > 0:
		new_anim = "walk_right"

	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)
	
	move_and_slide(velocity*speed)
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		print("Collided with: ", collision.collider.name)
	
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
	

	
func _on_Area2D_area_entered(area):
	#$CollisionShape2D.set_deferred("disabled", true)

	var current_name = get_node("label").text
	var areas = area.get_overlapping_areas()
	#var overlapping_areas = areas.filter(is_letter_area)
	#var overlapping_areas = areas.filter((func(overlapping_area): "letter_name" in overlapping_area))
	for overlapping_area in areas:
		if "letter_name" in overlapping_area: 
			var letter_area = overlapping_area
			var new_name = current_name + letter_area.letter_name
			set_player_name(new_name)
			get_node("/root/Lobby/Connect/Name").set_text(new_name)

func _on_Area2D_area_exited(area):
	pass

func is_letter_area(overlapping_area):
	 return "letter_name" in overlapping_area
