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

# ─────────── DASH SETTINGS YOU CAN ADJUST ───────────
@export var dash_speed: float = 300.0       # How fast the dash moves (much faster than walking)
@export var dash_duration: float = 0.2      # How long the dash lasts in seconds
@export var dash_cooldown: float = 1.0      # How many seconds before you can dash again
@export var lock_direction: bool = true     # If true, you can't change direction during dash

# ─────────── INTERNAL DASH TRACKING ───────────
var _time_left: float = 0.0                # Counts down from dash_duration to 0
var _dash_direction: Vector2 = Vector2.ZERO # Which direction we're dashing (locked in)
var _can_dash: bool = true                  # Whether dash is off cooldown and available

func enter(_from):
	# Check if dash is available (not on cooldown)
	if not _can_dash:
		# Dash is on cooldown, so we can't dash right now
		# Go back to whatever the player should be doing instead
		if player.direction != Vector2.ZERO:
			# Player is trying to move, so switch to walking
			player.change_state(player.walk_state)
		else:
			# Player isn't moving, so go back to idle
			player.change_state(player.idle_state)
		return
	
	# Lock in the dash direction based on which way the player is currently facing
	_dash_direction = player.facing
	# Start the dash timer
	_time_left = dash_duration
	
	# Set initial dash velocity
	player.velocity = _dash_direction * dash_speed
	
	# Play appropriate animation (walk for now, can be changed to "dash" later)
	player.play_anim("walk")
	
	# Start cooldown
	_can_dash = false
	_start_cooldown()

func update(delta):
	# Keep facing locked during dash if enabled
	if lock_direction:
		player.facing = _dash_direction
	
	# Count down dash timer
	_time_left -= delta
	
	# End dash when timer expires
	if _time_left <= 0.0:
		# Transition based on current input
		if player.direction != Vector2.ZERO:
			player.change_state(player.walk_state)
		else:
			player.change_state(player.idle_state)

func physics_update(_delta):
	# Maintain dash velocity throughout the dash
	player.velocity = _dash_direction * dash_speed

func _start_cooldown():
	var cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.wait_time = dash_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_reset_dash_availability)
	cooldown_timer.start()

func _reset_dash_availability():
	_can_dash = true

func can_dash() -> bool:
	return _can_dash

func handle_input(_event):
	# No input handling during dash
	pass

func exit(_to):
	# No special cleanup needed
	pass
