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

# ─────────── WANDER BEHAVIOR SETTINGS ───────────
@export var wander_speed_multiplier: float = 0.5    # How fast to move while wandering (slower than chasing)
@export var min_wander_distance: float = 32.0       # Minimum distance to walk in one direction
@export var max_wander_distance: float = 96.0       # Maximum distance to walk in one direction
@export var min_pause_time: float = 1.0             # Minimum time to pause between movements
@export var max_pause_time: float = 3.0             # Maximum time to pause between movements
@export var direction_change_chance: float = 0.3    # Chance to change direction when hitting a wall

# ─────────── INTERNAL WANDER TRACKING ───────────
var _wander_direction: Vector2 = Vector2.ZERO       # Current direction we're wandering toward
var _wander_distance_left: float = 0.0              # How much further to walk in current direction
var _pause_timer: float = 0.0                       # Countdown timer for pausing between movements
var _is_paused: bool = false                        # Whether we're currently paused
var _wander_speed: float = 30.0                     # Actual speed while wandering

func enter(_from):
	# Calculate wander speed based on enemy's normal speed
	_wander_speed = enemy.move_speed * wander_speed_multiplier
	
	# Start with a pause, then begin wandering
	_start_pause()

func update(dt):
	# Always check if the player has come within detection range
	if enemy.can_see_player():
		# Player spotted! Switch to chase mode
		enemy.change_state(enemy.chase_state)
		return
	
	# Handle pausing between movements
	if _is_paused:
		_pause_timer -= dt
		if _pause_timer <= 0.0:
			_start_wandering()
		return
	
	# Handle active wandering movement
	if _wander_distance_left > 0.0:
		# Move in the wander direction
		enemy.direction = _wander_direction
		var distance_moved = _wander_speed * dt
		_wander_distance_left -= distance_moved
		
		# Play walking animation
		enemy.play_anim("walk")
	else:
		# Finished current wander - start a pause
		_start_pause()

func physics_update(_dt):
	# Preserve knockback physics - don't override velocity during knockback
	if enemy.knockback_timer > 0.0:
		return  # Allow knockback system to control velocity
	
	# Move in wander direction (use cached speed)
	enemy.velocity = _wander_direction * _wander_speed

func exit(_to):
	# Clean up when leaving wander state
	enemy.velocity = Vector2.ZERO
	enemy.direction = Vector2.ZERO

# ─────────── WANDER BEHAVIOR HELPERS ───────────
func _start_wandering():
	"""Pick a new random direction and distance to wander"""
	_is_paused = false
	
	# Pick a random direction (8 directions: N, NE, E, SE, S, SW, W, NW)
	var angle = randf() * 2 * PI
	_wander_direction = Vector2.from_angle(angle).normalized()
	
	# Pick a random distance to walk
	_wander_distance_left = randf_range(min_wander_distance, max_wander_distance)

func _start_pause():
	"""Stop moving and pause for a random amount of time"""
	_is_paused = true
	_wander_distance_left = 0.0
	enemy.direction = Vector2.ZERO
	
	# Pick a random pause duration
	_pause_timer = randf_range(min_pause_time, max_pause_time)
	
	# Play idle animation while paused
	enemy.play_anim("idle")

func _handle_collision():
	"""Called when the enemy hits a wall while wandering"""
	# Chance to change direction when hitting obstacles
	if randf() < direction_change_chance:
		_start_wandering()  # Pick new direction
	else:
		_start_pause()      # Just pause and try again later
