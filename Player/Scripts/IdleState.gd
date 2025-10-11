# The player is not moving. We ensure velocity is zero and play the idle anim.
# Transitions:
#   - to WalkState when there is any input direction.

class_name IdleState
extends "res://Player/Scripts/PlayerState.gd"

func enter(from):
	# Ensure we are not drifting if we came from Walk/Dash/etc.
	player.velocity = Vector2.ZERO
	player.play_anim("idle")

func update(delta):
	# If any input direction exists, start walking.
	if player.direction != Vector2.ZERO:
		player.change_state(player.WalkState)
