## WALK STATE - When the Player is Moving Around
##
## This state handles normal movement when the player is walking around the world.
## It continuously updates the player's velocity based on which direction keys are pressed
## and plays the appropriate walking animation.
##
## What it does:
## - Sets the player's velocity so they actually move around
## - Plays walking animations that match the movement direction
## - Switches back to idle when the player stops pressing movement keys
## - Still allows attacks and dashes while moving
##
## The key job is translating "player is holding W" into "move the character forward"
## and making sure the right animation plays.

class_name WalkState
extends "res://Player/Scripts/PlayerState.gd"

func enter(_from):
	# Start playing the walking animation right away
	player.play_anim("walk")

func update(_dt):
	# If the player stopped pressing movement keys, go back to idle
	if player.direction == Vector2.ZERO:
		player.change_state(player.idle_state)
		return

	# Make the player actually move by setting their velocity
	# direction is which way they want to go, move_speed is how fast
	player.velocity = player.direction * player.move_speed

	# Keep updating the animation in case they changed direction while walking
	player.play_anim("walk")

func handle_input(event):
	# Player can still attack or dash while walking
	if event.is_action_pressed("attack"):
		# Switch to attack state (which will handle stopping movement if needed)
		player.change_state(player.attack_state)
	elif event.is_action_pressed("dash") and player.dash_state.can_dash():
		# Switch to dash state for a quick burst of speed
		player.change_state(player.dash_state)