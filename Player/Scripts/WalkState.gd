# The player is actively moving.
# Responsibilities:
#   - set velocity each frame based on Player.direction and move_speed
#   - keep the proper walk animation playing as facing changes
# Transitions:
#   - to IdleState when input direction returns to zero.

class_name WalkState
extends "res://Player/Scripts/PlayerState.gd"

func enter(from):
	# Safe to call here; we'll also call it each frame so anim follows facing.
	player.play_anim("walk")

func update(delta):
	# If player released movement, go idle.
	if player.direction == Vector2.ZERO:
		player.change_state(player.IdleState)
		return

	# Movement: CharacterBody2D uses velocity in pixels/second.
	player.velocity = player.direction * player.move_speed

	# Keep walk animation in sync with current facing (up/down/side).
	# This only restarts if the name changes, so it's cheap.
	player.play_anim("walk")

func physics_update(_delta):
	# Optional per-state physics (not needed for basic walk).
	pass
