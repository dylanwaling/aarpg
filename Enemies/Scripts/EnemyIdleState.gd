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

# ─────────── IDLE BEHAVIOR SETTINGS ───────────
@export var idle_duration: float = 1.5              # How long to stay idle before wandering

# ─────────── INTERNAL TRACKING ───────────
var _idle_timer: float = 0.0                        # Countdown timer for idle duration

func enter(_from):
	# Stop the enemy from moving and play the standing animation
	enemy.velocity = Vector2.ZERO
	enemy.play_anim("idle")
	
	# Start the idle timer
	_idle_timer = idle_duration

func update(dt):
	# Only check for player if not in post-attack recovery
	if not enemy.post_attack_recovery and enemy.can_see_player():
		# Player spotted! Switch to chase mode
		enemy.change_state(enemy.chase_state)
		return
	
	# Count down idle timer
	_idle_timer -= dt
	if _idle_timer <= 0.0:
		# Idle period finished - start wandering
		enemy.change_state(enemy.wander_state)

func physics_update(_dt):
	# Don't override knockback during knockback period
	if enemy.knockback_timer > 0.0:
		return
	
	# Idle state: enemy doesn't move
	enemy.velocity = Vector2.ZERO
