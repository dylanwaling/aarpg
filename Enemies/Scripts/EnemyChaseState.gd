## ENEMY CHASE STATE - When the Enemy is Chasing the Player
##
## This state handles aggressive pursuit when the enemy has spotted the player.
## It makes the enemy move directly toward the player's position at full speed.
##
## What it does:
## - Constantly calculates direction to the player
## - Sets maximum velocity to chase at full speed
## - Plays walking/running animations while chasing
## - Switches to attack when close enough to the player
## - Gives up chase if player gets too far away (returns to idle)
##
## This creates the core "enemy AI" behavior that makes enemies feel threatening
## and responsive to the player's presence.

class_name EnemyChaseState
extends "res://Enemies/Scripts/EnemyState.gd"

func enter(_from):
	# Start playing the chase animation (using walk animation for now)
	enemy.play_anim("walk")

func update(_dt):
	# Check if player is close enough to attack
	if enemy.can_attack_player():
		# Switch to attack state when in range
		enemy.change_state(enemy.attack_state)
		return
	
	# Check if player has gotten too far away (give up chase)
	var distance = enemy.distance_to_player()
	if distance > enemy.detection_range * 1.5:  # Buffer zone to prevent flickering
		# Player escaped! Go back to idle
		enemy.change_state(enemy.idle_state)
		return

func physics_update(_dt):
	# Calculate direction to player and move toward them at full speed
	enemy.direction = enemy.direction_to_player()
	enemy.velocity = enemy.direction * enemy.move_speed

	# Keep updating the animation to match movement direction
	enemy.play_anim("walk")
