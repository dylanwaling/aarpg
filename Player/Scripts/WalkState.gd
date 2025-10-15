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
	# ═══════════ AUTOMATIC STATE TRANSITIONS ═══════════
	# Check if player stopped giving movement input - if so, switch to idle
	if player.direction == Vector2.ZERO:
		player.change_state(player.idle_state)
		return  # Exit early - don't do movement logic if we're switching states

	# ═══════════ MOVEMENT PHYSICS ═══════════
	# Convert input direction into actual movement velocity
	# direction is a unit vector (length 1.0), so multiply by speed to get proper velocity
	player.velocity = player.direction * player.move_speed

	# ═══════════ ANIMATION SYNC ═══════════
	# Keep the walking animation updated to match which direction we're facing
	# This handles cases where the player changes direction while walking
	player.play_anim("walk")

# ─────────── INPUT HANDLING WHILE WALKING ───────────
func handle_input(event):
	# Use shared function for common actions (attack and dash)
	handle_common_actions(event)