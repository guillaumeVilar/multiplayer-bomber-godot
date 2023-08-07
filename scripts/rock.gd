extends CharacterBody2D


# Sent to everyone else
@rpc func do_explosion():
	$"AnimationPlayer".play("explode")


# Received by owner of the rock
The master and mastersync rpc behavior is not officially supported anymore. Try using another keyword or making custom logic using get_multiplayer().get_remote_sender_id()
@rpc func exploded(by_who):
	rpc("do_explosion") # Re-sent to puppet rocks
	$"../../Score".rpc("increase_score", by_who)
	do_explosion()
