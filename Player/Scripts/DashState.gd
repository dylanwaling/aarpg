# Player performs a quick dash in the current facing direction.
# - Fast movement burst with limited duration
# - Has cooldown to prevent spam
# - Transitions back to appropriate state when finished
# - Locks direction during dash for commitment

class_name DashState
extends "res://Player/Scripts/PlayerState.gd"

@export var dash_speed: float = 300.0      # Speed during dash (much faster than normal)
@export var dash_duration: float = 0.2     # How long the dash lasts (seconds)
@export var dash_cooldown: float = 1.0     # Cooldown before next dash (seconds)
@export var lock_direction: bool = true    # Lock dash direction for full duration

var _time_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _can_dash: bool = true

func enter(_from):
    # Can't dash if on cooldown
    if not _can_dash:
        if player.direction != Vector2.ZERO:
            player.change_state(player.WalkState)
        else:
            player.change_state(player.IdleState)
        return
    
    # Use current facing direction for dash
    _dash_direction = player.facing
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
            player.change_state(player.WalkState)
        else:
            player.change_state(player.IdleState)

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

