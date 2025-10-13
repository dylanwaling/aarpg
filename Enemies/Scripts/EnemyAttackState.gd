## ENEMY ATTACK STATE - Handles Everything That Happens During an Enemy Attack
##
## When the enemy gets close enough to the player, this state takes over and handles:
## - Playing the correct attack animation (up/down/side based on facing direction)
## - Activating damage hitboxes that can hurt the player
## - Preventing the enemy from moving during attacks (committed to the attack)
## - Timing how long the attack lasts, then returning to chase or idle
##
## This keeps enemy attacks feeling consistent and dangerous while preventing
## weird behavior like attacking while running away.

class_name EnemyAttackState
extends "res://Enemies/Scripts/EnemyState.gd"

# ─────────── ATTACK SETTINGS YOU CAN TWEAK ───────────
@export var attack_duration: float = 0.5             # How long the attack lasts in seconds
@export var attack_cooldown: float = 1.0             # How long to wait before attacking again
@export var stop_movement: bool = true               # If true, enemy can't move during attacks
@export var lock_facing: bool = true                 # If true, enemy can't turn around mid-attack

# ─────────── INTERNAL TRACKING VARIABLES ───────────
var _time_left: float = 0.0                # Counts down from attack_duration to 0
var _locked_facing: Vector2 = Vector2.DOWN  # Remembers which way enemy was facing when attack started
var _attack_activated: bool = false         # Tracks if we've activated the damage hitbox

func enter(_from):
	# Remember which direction the enemy was facing when the attack started
	if lock_facing:
		_locked_facing = enemy.facing

	# Stop the enemy from moving during attack
	if stop_movement:
		enemy.velocity = Vector2.ZERO

	# Start the enemy's attack animation (attack_up, attack_down, or attack_side)
	enemy.play_anim("attack")
	
	# Activate the damage hitbox if enemy has one
	_activate_attack_hitbox()

	# Start counting down the attack timer
	_time_left = attack_duration
	_attack_activated = false

func update(dt):
	# Count down the attack timer
	_time_left -= dt
	
	# When attack is finished, decide what to do next
	if _time_left <= 0.0:
		# Always go to idle after attack to prevent immediate re-attacking
		enemy.change_state(enemy.idle_state)
		return

func physics_update(_dt):
	# Stay still during attack (if stop_movement is true)
	if stop_movement:
		enemy.velocity = Vector2.ZERO

func _activate_attack_hitbox():
	"""Activate the enemy's damage hitbox to hurt the player"""
	# Try to find a hurtbox (damage dealer) on the enemy
	if enemy.hurtbox:
		# Enable the hurtbox so it can detect collision with player
		enemy.hurtbox.monitoring = true
		enemy.hurtbox.monitorable = true
		
		# Set up a timer to disable it after a short time
		get_tree().create_timer(0.2).timeout.connect(_deactivate_attack_hitbox)

func _deactivate_attack_hitbox():
	"""Disable the enemy's damage hitbox"""
	if enemy.hurtbox:
		enemy.hurtbox.monitoring = false
		enemy.hurtbox.monitorable = false

func exit(_to):
	# Make sure hitbox is disabled when leaving attack state
	_deactivate_attack_hitbox()
	
	# Add a brief cooldown before the enemy can attack again
	# This prevents the attack-chase-attack loop
	if _to == enemy.chase_state:
		# Go to idle briefly instead of immediately chasing again
		enemy.change_state(enemy.idle_state)
		# Set a timer to resume chasing after cooldown
		get_tree().create_timer(attack_cooldown).timeout.connect(func(): 
			if enemy.can_see_player():
				enemy.change_state(enemy.chase_state)
		)
