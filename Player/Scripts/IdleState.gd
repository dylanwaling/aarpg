## IDLE STATE - When the Player is Just Standing Around
##
## This is the "default" state when nothing special is happening.
## The player is just standing there, playing their idle animation.
##
## What it does:
## - Stops the player from moving (sets velocity to zero)
## - Plays the idle animation that matches which direction they're facing
## - Watches for input to switch to other states (walk if they move, attack if they press attack)
##
## It's like the "home base" state that other states return to when they're done.

class_name IdleState
extends "res://Player/Scripts/PlayerState.gd"

func enter(_from):
	# Stop the player from moving and play the standing animation
	player.velocity = Vector2.ZERO
	player.play_anim("idle")

func update(_dt):
	# If the player starts pressing movement keys, switch to walking
	if player.direction != Vector2.ZERO:
		player.change_state(player.walk_state)

func handle_input(event):
	# Check if the player pressed any action buttons
	if event.is_action_pressed("attack"):
		# Switch to attack state to handle the attack
		player.change_state(player.attack_state)
	elif event.is_action_pressed("dash") and player.dash_state.can_dash():
		# Switch to dash state, but only if dash isn't on cooldown
		player.change_state(player.dash_state)