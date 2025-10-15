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

# ─────────── ENTERING IDLE STATE ───────────
func enter(_from):
	# Stop all movement and show idle animation
	player.velocity = Vector2.ZERO
	player.play_anim("idle")

# ─────────── IDLE LOGIC EVERY FRAME ───────────
func update(_dt):
	# Watch for movement input to switch to walking
	if player.direction != Vector2.ZERO:
		player.change_state(player.walk_state)

# ─────────── INPUT HANDLING WHILE IDLE ───────────
func handle_input(event):
	# Use shared function for common actions (attack and dash)
	handle_common_actions(event)