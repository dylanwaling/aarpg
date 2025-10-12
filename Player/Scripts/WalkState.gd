# Player is walking.
# Responsible for updating velocity and animation each frame.
# Transitions back to IdleState when movement input stops.

class_name WalkState
extends "res://Player/Scripts/PlayerState.gd"

func enter(from):
	# Start walking animation immediately when entering this state
	player.play_anim("walk")

func update(_dt):
	# If no input, return to idle
	if player.direction == Vector2.ZERO:
		player.change_state(player.IdleState)
		return

	# Set player velocity based on input direction
	player.velocity = player.direction * player.move_speed

	# Update animation every frame to match direction (up/down/side)
	player.play_anim("walk")

func handle_input(event):
	if event.is_action_pressed("attack"):
		player.change_state(player.AttackState)
	elif event.is_action_pressed("dash") and player.dash_state.can_dash():
		player.change_state(player.dash_state)