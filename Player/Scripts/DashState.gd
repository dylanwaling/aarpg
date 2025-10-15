## DASH STATE - Handles Quick Burst Movement
##
## When the player presses the dash button, this state makes them zoom forward quickly.
## It's like a short burst of super-speed in whatever direction they're facing.
##
## Features:
## - Much faster movement than normal walking (like 3x speed)
## - Short duration (only lasts a fraction of a second)
## - Cooldown system so players can't spam it constantly
## - Direction locking so you commit to the dash direction
## - Automatically returns to walking or idle when the dash ends
##
## This creates tactical movement where players have to decide when to use their dash
## since they can't use it again immediately.

class_name DashState
extends "res://Player/Scripts/PlayerState.gd"

# ─────────── DASH BEHAVIOR YOU CAN TWEAK ───────────
@export var dash_speed: float = 300.0           # Speed during dash (3x normal walking speed)
@export var dash_duration: float = 0.2          # How long dash lasts in seconds
@export var dash_cooldown: float = 1.0          # Cooldown before next dash is allowed
@export var lock_direction: bool = true         # Whether to lock facing direction during dash

# ─────────── INTERNAL DASH STATE (DON'T MODIFY) ───────────
var _time_left: float = 0.0                     # Countdown timer for dash duration
var _dash_direction: Vector2 = Vector2.ZERO     # Direction locked in when dash starts
var _can_dash: bool = true                      # Whether dash is available (not on cooldown)
var _cooldown_timer: Timer                      # Reusable timer for cooldown management

# ─────────── STARTING A DASH ───────────
func enter(_from):
	# Check if dash is available (not on cooldown)
	if not _can_dash:
		# Dash is on cooldown - return to appropriate state
		if player.direction != Vector2.ZERO:
			player.change_state(player.walk_state)  # Keep moving
		else:
			player.change_state(player.idle_state)  # Stand still
		return
	
	# Lock in dash direction based on current facing direction
	_dash_direction = player.facing
	_time_left = dash_duration
	
	# Set dash velocity for immediate movement
	player.velocity = _dash_direction * dash_speed
	
	# Play movement animation (can change to "dash" animation if available)
	player.play_anim("walk")
	
	# Start cooldown period
	_can_dash = false
	_start_cooldown()

# ─────────── DASH TIMING EVERY FRAME ───────────
func update(delta):
	# Lock facing direction during dash if enabled
	if lock_direction:
		player.facing = _dash_direction
	
	# Count down remaining dash time
	_time_left -= delta
	
	# End dash when timer expires
	if _time_left <= 0.0:
		# Transition to next state based on current input
		if player.direction != Vector2.ZERO:
			player.change_state(player.walk_state)
		else:
			player.change_state(player.idle_state)

# ─────────── DASH MOVEMENT PHYSICS ───────────
func physics_update(_delta):
	# Maintain consistent dash velocity throughout duration
	player.velocity = _dash_direction * dash_speed

# ─────────── COOLDOWN MANAGEMENT ───────────
func _start_cooldown():
	# ─────────── EFFICIENT TIMER MANAGEMENT ───────────
	# Create a reusable timer (only once) instead of making new timers each dash
	# This prevents memory waste from creating hundreds of timer objects
	if not _cooldown_timer:
		_cooldown_timer = Timer.new()  # Create the timer object
		add_child(_cooldown_timer)      # Add it to the scene tree
		_cooldown_timer.one_shot = true  # Timer only fires once, doesn't repeat
		_cooldown_timer.timeout.connect(_reset_dash_availability)  # When timer ends, allow dashing again
	
	# Configure and start the cooldown countdown
	_cooldown_timer.wait_time = dash_cooldown  # How long to wait (set in inspector)
	_cooldown_timer.start()  # Begin counting down

func _reset_dash_availability():
	# Dash cooldown finished - allow dashing again
	_can_dash = true

# ─────────── DASH AVAILABILITY CHECK ───────────
func can_dash() -> bool:
	# Returns true if dash is available (not on cooldown)
	return _can_dash

# ─────────── INPUT HANDLING DURING DASH ───────────
func handle_input(_event):
	# Player is locked into dash - no input changes allowed
	pass

# ─────────── WHEN LEAVING DASH STATE ───────────
func exit(_to):
	# Dash state is self-contained - no cleanup needed
	pass
