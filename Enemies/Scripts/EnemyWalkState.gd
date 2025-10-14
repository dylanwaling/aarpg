## ENEMY WALK STATE - When the Enemy is Moving Around Randomly
##
## This state handles basic wandering movement when the enemy is patrolling.
## It makes the enemy move in random directions, creating natural-looking patrol behavior.
##
## What it does:
## - Sets the enemy's velocity so they actually move around
## - Plays walking animations that match the movement direction  
## - Picks random directions to walk in (simple patrol AI)
## - Still watches for the player and switches to chase when spotted
## - Returns to idle after walking for a while
##
## This creates enemies that feel "alive" by wandering around instead of just standing still.

class_name EnemyWalkState
extends "res://Enemies/Scripts/EnemyState.gd"

# ─────────── WALK SETTINGS ───────────
var walk_time: float = 0.0              # How long we've been walking
var max_walk_time: float = 2.0          # How long to walk before going idle
var walk_direction: Vector2 = Vector2.ZERO  # Which direction we're walking

func enter(_from):
	# Pick a random direction to walk in
	walk_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	# Reset walk timer
	walk_time = 0.0
	# Start playing the walking animation right away
	enemy.play_anim("walk")

func update(dt):
	# Always check for player first (highest priority)
	if enemy.can_see_player():
		# Player spotted! Switch to chase mode immediately
		enemy.change_state(enemy.chase_state)
		return
	
	# Count how long we've been walking
	walk_time += dt
	
	# If we've walked long enough, go back to idle
	if walk_time >= max_walk_time:
		enemy.change_state(enemy.idle_state)
		return

func physics_update(_dt):
	# Make the enemy actually move by setting their velocity
	# walk_direction is which way to go, move_speed is how fast
	enemy.direction = walk_direction
	# Move toward destination at walking speed (preserve knockback)
	if enemy.knockback_timer > 0.0:
		print("Walk state [", enemy.name, "]: knockback active, preserving knockback")
		return  # Don't override knockback during knockback period
	
	# Move towards target
	enemy.velocity = walk_direction * enemy.move_speed

	# Keep updating the animation in case direction changed
	enemy.play_anim("walk")
