## ENEMY IDLE STATE - When the Enemy is Just Standing Around
##
## This is the "default" state when the enemy isn't doing anything special.
## The enemy is just standing there, playing their idle animation, and watching for the player.
##
## What it does:
## - Stops the enemy from moving (sets velocity to zero)
## - Plays the idle animation that matches which direction they're facing
## - Constantly checks if the player comes within detection range
## - Switches to chase state when player gets too close
##
## It's like the "home base" state that other enemy states return to when they're done.

class_name EnemyIdleState
extends "res://Enemies/Scripts/EnemyState.gd"

func enter(_from):
	# Stop the enemy from moving and play the standing animation
	enemy.velocity = Vector2.ZERO
	enemy.play_anim("idle")

func update(_dt):
	# Constantly check if the player has come within detection range
	if enemy.can_see_player():
		# Player spotted! Switch to chase mode
		enemy.change_state(enemy.chase_state)

func physics_update(_dt):
	# Stay still during idle
	enemy.velocity = Vector2.ZERO
