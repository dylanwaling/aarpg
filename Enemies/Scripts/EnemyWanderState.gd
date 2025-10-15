## ENEMY WANDER STATE - When the Enemy Randomly Walks Around
##
## This state makes the enemy move around randomly when the player isn't nearby.
## The enemy will pick random directions to walk in, pause occasionally, and 
## constantly check if the player comes within detection range.
##
## What it does:
## - Picks random directions and distances to walk
## - Pauses between movements for natural behavior
## - Plays appropriate walking animations
## - Switches to chase state when player gets too close
##
## This creates more dynamic and interesting enemy behavior instead of just standing still.

class_name EnemyWanderState
extends "res://Enemies/Scripts/EnemyState.gd"

# ─────────── WANDERING BEHAVIOR YOU CAN TWEAK ───────────
@export var wander_speed_multiplier: float = 0.5    # Speed when wandering (0.5 = half of chase speed)
@export var min_wander_distance: float = 32.0       # Shortest distance to walk before pausing
@export var max_wander_distance: float = 96.0       # Longest distance to walk before pausing
@export var min_pause_time: float = 1.0             # Shortest time to stand still between walks
@export var max_pause_time: float = 3.0             # Longest time to stand still between walks
@export var direction_change_chance: float = 0.3    # Probability to pick new direction when hitting wall

# ─────────── INTERNAL WANDER STATE (DON'T MODIFY) ───────────
var _wander_direction: Vector2 = Vector2.ZERO       # Direction enemy is currently walking
var _wander_distance_left: float = 0.0              # How much further to walk before next pause
var _pause_timer: float = 0.0                       # Countdown timer for standing still
var _is_paused: bool = false                        # Whether enemy is currently pausing or walking
var _wander_speed: float                             # Actual movement speed (calculated from enemy speed)

# ─────────── STARTING TO WANDER ───────────
func enter(_from):
	# Calculate how fast to move while wandering (slower than chasing)
	_wander_speed = enemy.move_speed * wander_speed_multiplier
	
	# Begin with a pause (like "looking around" before moving)
	_start_pause()

# ─────────── WANDER LOGIC EVERY FRAME ───────────
func update(dt):
	# Always watch for player - highest priority
	if enemy.can_see_player():
		# Player spotted! Drop everything and start chasing
		enemy.change_state(enemy.chase_state)
		return
	
	# If currently pausing between movements
	if _is_paused:
		_pause_timer -= dt
		if _pause_timer <= 0.0:
			_start_wandering()  # Pause finished - start walking
		return
	
	# If currently walking in a direction
	if _wander_distance_left > 0.0:
		# Keep moving in current direction
		enemy.direction = _wander_direction
		var distance_moved = _wander_speed * dt
		_wander_distance_left -= distance_moved
		
		# Show walking animation while moving
		enemy.play_anim("walk")
	else:
		# Finished walking current distance - time for a pause
		_start_pause()

# ─────────── WANDER MOVEMENT PHYSICS ───────────
func physics_update(_dt):
	# Don't interfere with knockback if enemy is being hit
	if enemy.knockback_timer > 0.0:
		return  # Let knockback system control movement
	
	# Move in wandering direction at calculated speed
	enemy.velocity = _wander_direction * _wander_speed

# ─────────── WHEN LEAVING WANDER STATE ───────────
func exit(_to):
	# Stop all movement when transitioning to next state
	enemy.velocity = Vector2.ZERO
	enemy.direction = Vector2.ZERO

# ─────────── WANDER HELPER FUNCTIONS ───────────
func _start_wandering():
	# Switch from pausing to walking mode
	_is_paused = false
	
	# Pick a completely random direction (any angle from 0 to 360 degrees)
	var angle = randf() * 2 * PI
	_wander_direction = Vector2.from_angle(angle).normalized()
	
	# Pick how far to walk before next pause (random between min/max)
	_wander_distance_left = randf_range(min_wander_distance, max_wander_distance)

func _start_pause():
	# Switch from walking to pausing mode
	_is_paused = true
	_wander_distance_left = 0.0
	enemy.direction = Vector2.ZERO
	
	# Pick how long to stand still (random between min/max pause time)
	_pause_timer = randf_range(min_pause_time, max_pause_time)
	
	# Show idle animation while standing still
	enemy.play_anim("idle")

func _handle_collision():
	# Called if enemy hits a wall or obstacle while wandering
	# Sometimes pick new direction, sometimes just pause and wait
	if randf() < direction_change_chance:
		_start_wandering()  # Try a different direction
	else:
		_start_pause()      # Stop and wait before trying again
