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
@export var attack_duration: float = 1.5             # How long the attack lasts in seconds
@export var attack_cooldown: float = 2.0             # How long to wait before attacking again
@export var stop_movement: bool = true               # If true, enemy can't move during attacks
@export var lock_facing: bool = true                 # If true, enemy can't turn around mid-attack

# ─────────── INTERNAL TRACKING VARIABLES ───────────
var _time_left: float = 0.0                # Counts down from attack_duration to 0
var _locked_facing: Vector2 = Vector2.DOWN  # Remembers which way enemy was facing when attack started
var _attack_activated: bool = false         # Tracks if we've activated the damage hitbox
var _can_attack_again: bool = true          # Cooldown flag to prevent rapid attacks

func enter(_from):
	# Check if we're still in cooldown from previous attack
	if not _can_attack_again:
		# Still in cooldown, can't attack yet
		enemy.change_state(enemy.idle_state)
		return
	
	# Set cooldown flag and start attack
	_can_attack_again = false
	# Set the main attack cooldown timer to prevent immediate re-attacking
	enemy.attack_cooldown_timer = attack_cooldown
	
	# Remember which direction the enemy was facing when the attack started
	if lock_facing:
		_locked_facing = enemy.facing

	# Stop the enemy from moving during attack
	if stop_movement:
		enemy.velocity = Vector2.ZERO

	# Start the enemy's attack animation (attack_up, attack_down, or attack_side)
	enemy.play_anim("attack")
	
	# Don't activate hitbox immediately - wait for wind-up
	# _activate_attack_hitbox() will be called later in update()

	# Start counting down the attack timer
	_time_left = attack_duration
	_attack_activated = false

func update(dt):
	# Count down the attack timer
	_time_left -= dt
	
	# Activate hitbox partway through the attack (after wind-up) - only once per attack
	var wind_up_time = attack_duration * 0.4  # 40% of attack is wind-up
	if not _attack_activated and _time_left <= (attack_duration - wind_up_time):
		_activate_attack_hitbox()
		_attack_activated = true
	
	# When attack is finished, decide what to do next
	if _time_left <= 0.0:
		# Enter special post-attack idle that ignores player for 2 seconds
		enemy.change_state(enemy.idle_state)
		# Set a flag to make idle ignore player detection
		enemy.post_attack_recovery = true
		# Clear the flag after attack_cooldown seconds
		get_tree().create_timer(attack_cooldown).timeout.connect(_enable_next_attack)
		return

func _enable_next_attack():
	"""Called after cooldown timer expires to allow attacking again"""
	_can_attack_again = true
	enemy.post_attack_recovery = false
	
	# Resume appropriate behavior based on player proximity
	if enemy.can_see_player():
		enemy.change_state(enemy.chase_state)  # Continue chasing if player nearby
	else:
		enemy.change_state(enemy.wander_state)  # Return to wandering if player left

func physics_update(_dt):
	# Preserve knockback physics - don't override velocity during knockback
	if enemy.knockback_timer > 0.0:
		return
	
	# Attack state doesn't move the enemy - they stay in place during attack
	enemy.velocity = Vector2.ZERO

func _activate_attack_hitbox():
	"""Activate the enemy's damage hitbox to hurt the player"""
	# Use the new professional hitbox system
	if enemy.hitbox:
		# Damage is already synced in Enemy._ready() - just activate
		enemy.hitbox.activate()

func _deactivate_attack_hitbox():
	"""Disable the enemy's damage hitbox"""
	# Use the new professional hitbox system
	if enemy.hitbox:
		enemy.hitbox.deactivate()

func exit(_to):
	# Make sure hitbox is disabled when leaving attack state
	_deactivate_attack_hitbox()
	
	# Always go to idle after attack to add natural spacing
	if _to != enemy.idle_state:
		enemy.change_state(enemy.idle_state)
