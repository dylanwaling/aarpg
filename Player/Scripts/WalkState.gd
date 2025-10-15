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

# ─────────── ENTERING WALK STATE ───────────
func enter(_from):
	# Start walking animation immediately
	player.play_anim("walk")

# ─────────── MOVEMENT LOGIC EVERY FRAME ───────────
func update(_dt):
	# Return to idle if movement input stops
	if player.direction == Vector2.ZERO:
		player.change_state(player.idle_state)
		return

	# Apply movement velocity based on input direction
	player.velocity = player.direction * player.move_speed

	# Update animation to match current facing direction
	player.play_anim("walk")

# ─────────── INPUT HANDLING WHILE WALKING ───────────
func handle_input(event):
	# Allow actions while walking (combat mobility)
	if event.is_action_pressed("attack"):
		# Attack (may allow movement depending on AttackState settings)
		player.change_state(player.attack_state)
	elif event.is_action_pressed("dash") and player.dash_state.can_dash():
		# Dash for quick burst movement
		player.change_state(player.dash_state)