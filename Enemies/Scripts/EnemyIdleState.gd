## ENEMY IDLE STATE - Brief Pause Before Wandering
##
## This is a short transitional state when the enemy first spawns or after losing the player.
## The enemy stands still briefly, then starts wandering around randomly.
##
## What it does:
## - Stops the enemy from moving (sets velocity to zero)  
## - Plays the idle animation that matches which direction they're facing
## - Constantly checks if the player comes within detection range
## - Switches to chase state when player gets too close
## - Transitions to wander state after a short delay
##
## This creates a brief "looking around" moment before the enemy starts patrolling.

class_name EnemyIdleState
extends "res://Enemies/Scripts/EnemyState.gd"

# ─────────── IDLE TIMING YOU CAN TWEAK ───────────
@export var idle_duration: float = 1.5              # How long to stand still before starting to wander

# ─────────── INTERNAL TIMER (DON'T MODIFY) ───────────
var _idle_timer: float = 0.0                        # Counts down from idle_duration to zero

# ─────────── WHEN ENTERING IDLE STATE ───────────
func enter(_from):
	# Stop enemy movement completely and show idle animation
	enemy.velocity = Vector2.ZERO
	enemy.play_anim("idle")
	
	# Reset the idle countdown timer
	_idle_timer = idle_duration

# ─────────── EVERY FRAME WHILE IDLE ───────────
func update(dt):
	# Always watch for player unless in post-attack recovery period
	if not enemy.post_attack_recovery and enemy.can_see_player():
		# Player came within range! Start chasing immediately
		enemy.change_state(enemy.chase_state)
		return
	
	# Count down time remaining in idle state
	_idle_timer -= dt
	if _idle_timer <= 0.0:
		# Idle time is up - start wandering around
		enemy.change_state(enemy.wander_state)

# ─────────── PHYSICS WHILE IDLE ───────────
func physics_update(_dt):
	# If enemy is being knocked back, let knockback control movement
	if enemy.knockback_timer > 0.0:
		return
	
	# Otherwise, idle state means no movement at all
	enemy.velocity = Vector2.ZERO

# ─────────── WHEN LEAVING IDLE STATE ───────────
func exit(_to):
	# Make sure enemy stops moving when transitioning to next state
	enemy.velocity = Vector2.ZERO
