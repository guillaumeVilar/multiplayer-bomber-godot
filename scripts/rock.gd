extends CharacterBody2D

@rpc("call_local")
func exploded(by_who):
	print("Rock.gd - in exploded")
	$"AnimationPlayer".play("explode")
	$"../../Score".rpc("increase_score", by_who)
