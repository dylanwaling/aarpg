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

# ─────────── ATTACK TIMING YOU CAN TWEAK ───────────
@export var attack_duration: float = 1.5             # Total time for complete attack animation
@export var wind_up_percentage: float = 0.4          # How much of attack is wind-up before damage (40%)
@export var stop_movement: bool = true               # Whether enemy stops moving during attack
@export var lock_facing: bool = true                 # Whether enemy can't turn while attacking

# ─────────── INTERNAL ATTACK STATE (DON'T MODIFY) ───────────
var _time_left: float = 0.0                # Countdown timer for attack duration
var _locked_facing: Vector2 = Vector2.DOWN  # Direction enemy was facing when attack started
var _attack_activated: bool = false         # Whether damage hitbox has been activated yet
var _can_attack_again: bool = true          # Whether enough time has passed since last attack

# ─────────── STARTING AN ATTACK ───────────
func enter(_from):
	# Check if attack cooldown is still active from previous attack
	if not _can_attack_again:
		# Can't attack yet, go back to idle and wait
		enemy.change_state(enemy.idle_state)
		return
	
	# Start attack cooldown period to prevent spam attacks
	_can_attack_again = false
	# Set enemy's main cooldown timer (used by can_attack_player())
	enemy.attack_cooldown_timer = enemy.attack_cooldown
	
	# Lock enemy facing direction so they don't spin during attack
	if lock_facing:
		_locked_facing = enemy.facing

	# Stop enemy movement so they commit to the attack
	if stop_movement:
		enemy.velocity = Vector2.ZERO

	# Play attack animation that matches enemy's facing direction
	enemy.play_anim("attack")
	
	# Don't activate damage hitbox yet - wait for wind-up period
	# Hitbox activation happens later in update() after wind-up period

	# Initialize attack timing
	_time_left = attack_duration
	_attack_activated = false

# ─────────── ATTACK TIMING EVERY FRAME ───────────
func update(dt):
	# Count down remaining attack time
	_time_left -= dt
	
	# Activate damage hitbox after wind-up period (only once per attack)
	var wind_up_time = attack_duration * wind_up_percentage
	if not _attack_activated and _time_left <= (attack_duration - wind_up_time):
		_activate_attack_hitbox()  # Turn on damage dealing
		_attack_activated = true
	
	# When attack animation finishes, transition to recovery
	if _time_left <= 0.0:
		# Go to idle state but ignore player briefly (recovery period)
		enemy.change_state(enemy.idle_state)
		# Make idle state ignore player detection temporarily
		enemy.post_attack_recovery = true
		# After cooldown, allow attacking again and resume normal behavior
		get_tree().create_timer(enemy.attack_cooldown).timeout.connect(_enable_next_attack)
		return

# ─────────── COOLDOWN RECOVERY ───────────
func _enable_next_attack():
	# Attack cooldown has finished - enemy can attack again
	_can_attack_again = true
	# End the post-attack recovery period
	enemy.post_attack_recovery = false
	
	# Decide what to do next based on where player is now
	if enemy.can_see_player():
		enemy.change_state(enemy.chase_state)  # Keep chasing if player still nearby
	else:
		enemy.change_state(enemy.wander_state)  # Go back to wandering if player left

# ─────────── PHYSICS DURING ATTACK ───────────
func physics_update(_dt):
	# Don't interfere with knockback physics if enemy is being hit
	if enemy.knockback_timer > 0.0:
		return
	
	# During attack, enemy stays completely still (committed to attack)
	enemy.velocity = Vector2.ZERO

# ─────────── DAMAGE HITBOX CONTROL ───────────
func _activate_attack_hitbox():
	# Turn on enemy's hitbox so it can damage the player
	if enemy.hitbox:
		enemy.hitbox.activate()  # Hitbox handles damage amount automatically

func _deactivate_attack_hitbox():
	# Turn off enemy's hitbox so it stops damaging player
	if enemy.hitbox:
		enemy.hitbox.deactivate()

# ─────────── WHEN LEAVING ATTACK STATE ───────────
func exit(_to):
	# Always turn off damage hitbox when attack ends
	_deactivate_attack_hitbox()
	
	# Force transition to idle for natural recovery period
	if _to != enemy.idle_state:
		enemy.change_state(enemy.idle_state)
