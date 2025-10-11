# Player is standing still.
# This state keeps the player from moving and plays the idle animation.
# It transitions to WalkState when movement input is detected.

class_name IdleState
extends "res://Player/Scripts/PlayerState.gd"

func enter(from):
	# Stop all motion when entering idle
	player.velocity = Vector2.ZERO
	player.play_anim("idle")

func update(_dt):
	# If the player gives movement input, switch to walk
	if player.direction != Vector2.ZERO:
		player.change_state(player.WalkState)

func handle_input(event):
	if event.is_action_pressed("attack"):
		player.change_state(player.AttackState)
