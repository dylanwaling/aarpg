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

# ─────────── WHEN STARTING TO CHASE PLAYER ───────────
func enter(_from):
	# Play running/walking animation to show enemy is actively chasing
	enemy.play_anim("walk")

# ─────────── CHASE DECISIONS EVERY FRAME ───────────
func update(_dt):
	# Check if we've gotten close enough to attack the player
	if enemy.can_attack_player():
		# Player is in attack range and cooldown is finished - attack!
		enemy.change_state(enemy.attack_state)
		return
	
	# Check if player has escaped and is now too far away
	var distance = enemy.distance_to_player()
	if distance > enemy.detection_range * 1.5:  # 1.5x gives buffer to prevent flickering
		# Player got away - stop chasing and go back to wandering
		enemy.change_state(enemy.wander_state)
		return

# ─────────── CHASE MOVEMENT PHYSICS ───────────
func physics_update(_dt):
	# Point enemy toward player's current position
	enemy.direction = enemy.direction_to_player()
	
	# Don't override knockback if enemy is being hit by player
	if enemy.knockback_timer > 0:
		return  # Let knockback physics control movement
	
	# Move toward player at full speed (aggressive chase)
	enemy.velocity = enemy.direction * enemy.move_speed
