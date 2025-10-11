# Player attacks once, then returns to Idle or Walk depending on input.
# - Plays: attack_up / attack_down / attack_side (via player.play_anim("attack"))
# - Locks facing for the whole attack (so diagonals won't flip mid-swing)
# - Optional: stops movement during attack (default true)
# - Simple duration-based end (no need to wire animation_finished unless you want to)

class_name AttackState
extends "res://Player/Scripts/PlayerState.gd"

@export var attack_duration: float = 0.35  # seconds; adjust to your clip length
@export var stop_movement: bool = true     # true = set velocity to 0 while attacking
@export var lock_facing: bool = true       # true = keep facing fixed for entire attack

var _time_left: float = 0.0
var _locked_facing: Vector2 = Vector2.DOWN

func enter(from):
	# Snapshot facing so the animation direction won't change mid-attack.
	if lock_facing:
		_locked_facing = player.facing

	# Optionally freeze motion during the attack.
	if stop_movement:
		player.velocity = Vector2.ZERO

	# Play the attack animation that matches current facing (up/down/side).
	player.play_anim("attack")

	# Start the attack timer.
	_time_left = attack_duration

func update(delta):
	# Keep facing locked by re-applying it each frame (prevents Player.update_facing from changing it).
	if lock_facing:
		player.facing = _locked_facing

	# Your attack is time-based; count down until it's over.
	_time_left -= delta
	if _time_left > 0.0:
		return

	# When done: if player is still giving movement input, go to Walk; otherwise go Idle.
	if player.direction != Vector2.ZERO:
		player.change_state(player.WalkState)
	else:
		player.change_state(player.IdleState)

func handle_input(event):
	# (Optional) If you later want to buffer combo inputs, you'd read them here.
	# For now, we ignore all inputs until the attack finishes.
	pass

func physics_update(_delta):
	# No special physics needed; Player.gd will still call move_and_slide().
	# If you want slight "lunge" movement during attack, set player.velocity here.
	pass

func exit(to):
	# Nothing to clean up right now. If you enabled a hitbox or trail, disable it here.
	pass
