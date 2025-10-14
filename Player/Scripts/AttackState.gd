## ATTACK STATE - Handles Everything That Happens During an Attack
##
## When the player presses the attack button, this state takes over and handles:
## - Playing the correct attack animation (up/down/side based on facing direction)
## - Showing visual attack effects (sword swooshes, etc.) that match the animation
## - Playing attack sound effects
## - Preventing the player from changing direction mid-attack (no spinning around)
## - Optionally allowing slow movement or stopping completely during attacks
## - Timing how long the attack lasts, then returning to idle or walking
##
## This keeps attacks feeling consistent and prevents weird behavior like
## starting an attack facing right but ending up facing left halfway through.

class_name AttackState
extends "res://Player/Scripts/PlayerState.gd"

# ─────────── ATTACK SETTINGS YOU CAN TWEAK ───────────
@export var attack_duration: float = 0.35           # How long the attack lasts in seconds
@export var stop_movement: bool = false             # If true, player can't move during attacks
@export var attack_movement_speed: float = 30.0     # If movement allowed, how fast (slower than normal)
@export var lock_facing: bool = true                # If true, player can't turn around mid-attack

# ─────────── DAMAGE AND HITBOX SETTINGS ───────────
# ── COMBAT STATS (EASY TO ADJUST) ──
@export var attack_damage: int = 15                 # How much damage each attack deals
@export var knockback_strength: float = 100.0       # How hard enemies get knocked back
@export var hitbox_delay: float = 0.1               # Delay before hitbox becomes active (wind-up time)
@export var hitbox_duration: float = 0.15           # How long the damage hitbox stays active
@export var attack_range: float = 70.0              # Attack range - distance to center of hitbox (adjustable for buffs/upgrades)
@export var hitbox_scene: PackedScene               # Drag your Hitbox.tscn here in the inspector

# ─────────── INTERNAL TRACKING VARIABLES ───────────
var _time_left: float = 0.0                # Counts down from attack_duration to 0
var _locked_facing: Vector2 = Vector2.DOWN  # Remembers which way player was facing when attack started
var _current_hitbox: Node = null           # Reference to the active damage hitbox
var _hitbox_created: bool = false          # Tracks if we've already created the hitbox this attack



func enter(_from):
	# Remember which direction the player was facing when the attack started
	# This prevents them from spinning around mid-attack which looks weird
	if lock_facing:
		_locked_facing = player.facing

	# Decide if the player can move during the attack
	if stop_movement:
		player.velocity = Vector2.ZERO  # Stop completely
	# If stop_movement is false, we'll handle slow movement in the update() function

	# Start the character's attack animation (attack_up, attack_down, or attack_side)
	player.play_anim("attack")
	
	# Show the visual effects (like sword swoosh) and play attack sounds
	_show_and_play_attack_effects()
	
	# Set up the damage hitbox with a slight delay for wind-up
	_setup_attack_hitbox()

	# Start counting down the attack timer
	_time_left = attack_duration
	_hitbox_created = false

func _show_and_play_attack_effects():
	# Get references to the attack effects nodes
	var attack_fx_anim = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer")
	var attack_fx_sprite = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite")
	
	# Make the attack effects visible
	attack_fx_sprite.visible = true
	
	# Determine which effect animation to play based on facing direction
	var effect_anim_name := ""
	if _locked_facing == Vector2.UP:
		effect_anim_name = "attack_up"
	elif _locked_facing == Vector2.DOWN:
		effect_anim_name = "attack_down"
	else: # LEFT or RIGHT
		effect_anim_name = "attack_side"
	
	# Play the attack effect animation
	if attack_fx_anim.has_animation(effect_anim_name):
		attack_fx_anim.play(effect_anim_name)
		
		# Play attack sound effect if available
		_play_attack_sound()

func _play_attack_sound():
	# Try to find an AudioStreamPlayer2D node for attack sounds
	# You can add this to your player scene if you want sound effects
	var audio_player = player.get_node_or_null("AttackAudio")
	if audio_player and audio_player is AudioStreamPlayer2D:
		audio_player.play()
	else:
		# Alternatively, create a temporary AudioStreamPlayer2D for the sound
		var temp_audio = AudioStreamPlayer2D.new()
		temp_audio.stream = preload("res://Player/Audio/SwordSwoosh.wav")
		player.add_child(temp_audio)
		temp_audio.play()
		# Clean up after the sound finishes
		temp_audio.finished.connect(func(): temp_audio.queue_free())

func _update_attack_effects():
	# Get reference to the AttackFX parent node (this is what we'll transform)
	var attack_fx_node = player.get_node("Sprite2D/AttackFX")
	
	# Professional method: Use scale transformation for flipping
	# This works WITH the animation system, not against it
	if _locked_facing == Vector2.LEFT or _locked_facing == Vector2.RIGHT:
		if player.sprite.flip_h:  # Facing left
			attack_fx_node.scale.x = -1  # Flip horizontally around parent center
		else:  # Facing right
			attack_fx_node.scale.x = 1   # Normal scale
	else:  # Up/down attacks
		attack_fx_node.scale.x = 1       # Always normal scale for up/down

func update(delta):
	# Handle movement during attack (slow movement if not stopped)
	if not stop_movement:
		# Allow movement during attack with dodge boost for retreat
		if player.direction != Vector2.ZERO:
			var movement_velocity = player.direction * attack_movement_speed
			
			# Attack-dodge: if moving opposite to attack direction, give speed boost
			if _is_retreat_movement(player.direction, _locked_facing):
				# Retreat movement is much faster for tactical dodging
				movement_velocity = player.direction * (player.move_speed * 1.5)
				
				# Update sprite and redirect attack when dodge starts
				var new_dodge_direction = Vector2.ZERO
				
				# Handle horizontal dodging (left/right)
				if player.direction.x < 0:  # Moving left
					player.facing = Vector2.LEFT
					player.sprite.flip_h = true
					player.sprite.offset.x = -1
					player.play_anim("attack")  # Update animation immediately
					_update_attack_effects()  # Update sword animation for new direction
					new_dodge_direction = Vector2.LEFT
				elif player.direction.x > 0:  # Moving right
					player.facing = Vector2.RIGHT
					player.sprite.flip_h = false
					player.sprite.offset.x = 0
					player.play_anim("attack")  # Update animation immediately
					_update_attack_effects()  # Update sword animation for new direction
					new_dodge_direction = Vector2.RIGHT
				# Handle vertical dodging (up/down) - switch animations mid-swing
				elif player.direction.y < 0:  # Moving up
					player.facing = Vector2.UP
					player.sprite.flip_h = false
					player.sprite.offset.x = 0
					# Seamlessly switch to attack_up animation at current progress
					var current_position = player.anim.current_animation_position
					player.anim.play("attack_up", -1, 1.0, false)
					player.anim.advance(current_position)  # Jump directly to position without reset
					
					# Seamlessly switch attack effects animation to match new direction
					var attack_fx_anim = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer")
					var fx_current_position = attack_fx_anim.current_animation_position
					attack_fx_anim.play("attack_up", -1, 1.0, false)
					attack_fx_anim.advance(fx_current_position)  # Jump directly to position without reset
					
					_update_attack_effects()  # Update sword positioning for new direction
					new_dodge_direction = Vector2.UP
				elif player.direction.y > 0:  # Moving down  
					player.facing = Vector2.DOWN
					player.sprite.flip_h = false
					player.sprite.offset.x = 0
					# Seamlessly switch to attack_down animation at current progress
					var current_position = player.anim.current_animation_position
					player.anim.play("attack_down", -1, 1.0, false)
					player.anim.advance(current_position)  # Jump directly to position without reset
					
					# Seamlessly switch attack effects animation to match new direction
					var attack_fx_anim = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer")
					var fx_current_position = attack_fx_anim.current_animation_position
					attack_fx_anim.play("attack_down", -1, 1.0, false)
					attack_fx_anim.advance(fx_current_position)  # Jump directly to position without reset
					
					_update_attack_effects()  # Update sword positioning for new direction
					new_dodge_direction = Vector2.DOWN
				
				# Redirect existing attack hitbox to new dodge direction
				if _current_hitbox and is_instance_valid(_current_hitbox):
					_redirect_hitbox_to_direction(new_dodge_direction)
			else:
				# Normal attack movement - keep sprite locked to attack direction
				if lock_facing:
					player.facing = _locked_facing
				player.sprite.flip_h = (_locked_facing == Vector2.LEFT)
				if _locked_facing == Vector2.LEFT:
					player.sprite.offset.x = -1
				else:
					player.sprite.offset.x = 0
			
			player.velocity = movement_velocity
		else:
			# No movement - keep sprite locked to attack direction
			if lock_facing:
				player.facing = _locked_facing
			player.sprite.flip_h = (_locked_facing == Vector2.LEFT)
			if _locked_facing == Vector2.LEFT:
				player.sprite.offset.x = -1
			else:
				player.sprite.offset.x = 0
			player.velocity = Vector2.ZERO

	# Handle attack effects transformation (scale-based flipping)
	_update_attack_effects()

	# Your attack is time-based; count down until it's over.
	_time_left -= delta
	if _time_left > 0.0:
		return

	# When the attack finishes, decide what to do next based on player input
	if player.direction != Vector2.ZERO:
		# Player is still trying to move, so go to walking state
		player.change_state(player.walk_state)
	else:
		# Player isn't trying to move, so go back to idle
		player.change_state(player.idle_state)

func handle_input(_event):
	# (Optional) If you later want to buffer combo inputs, you'd read them here.
	# For now, we ignore all inputs until the attack finishes.
	pass

func physics_update(_delta):
	# No special physics needed; Player.gd will still call move_and_slide().
	# If you want slight "lunge" movement during attack, set player.velocity here.
	pass

func exit(_to):
	# Clean up any active hitbox
	_cleanup_hitbox()
	
	# Hide the attack effects when exiting the attack state
	var attack_fx_sprite = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite")
	attack_fx_sprite.visible = false
	
	# Stop any playing attack effect animation
	var attack_fx_anim = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer")
	attack_fx_anim.stop()
	
	# Reset scale transformation (professional cleanup)
	var attack_fx_node = player.get_node("Sprite2D/AttackFX")
	attack_fx_node.scale.x = 1

# ─────────── HITBOX SYSTEM METHODS ───────────
func _setup_attack_hitbox():
	"""Prepares the hitbox system (called when attack starts)"""
	# Load default hitbox if none assigned in inspector
	if not hitbox_scene:
		hitbox_scene = preload("res://GeneralNodes/Hitbox/Hitbox.tscn")
		if not hitbox_scene:
			return
	
	# Create the hitbox with delay for attack wind-up timing
	get_tree().create_timer(hitbox_delay).timeout.connect(_create_damage_hitbox)

func _create_damage_hitbox():
	"""Creates and activates the damage hitbox"""
	if not hitbox_scene:
		return
		
	# Create the hitbox instance and add to player scene
	_current_hitbox = hitbox_scene.instantiate()
	player.add_child(_current_hitbox)
	
	# Position the hitbox based on attack direction
	_position_hitbox_for_direction()
	
	# Set up collision layers for player attacks
	# Layer 3 = Player Attacks: 2^(3-1) = 2^2 = 4
	# Mask 12 = Enemy Hurtboxes: 2^(12-1) = 2^11 = 2048
	_current_hitbox.collision_layer = 4  # Layer 3 
	_current_hitbox.collision_mask = 2048  # Detects Layer 12
	
	# Set up damage values using new professional system
	_current_hitbox.damage = attack_damage
	_current_hitbox.knockback_force = knockback_strength
	
	# Activate the hitbox to start damage detection
	_current_hitbox.activate()

func _position_hitbox_for_direction():
	"""Position the hitbox in front of the player based on attack direction"""
	if not _current_hitbox:
		return
		
	var hitbox_offset = Vector2.ZERO
	var hitbox_half_distance = attack_range * 0.5  # Position hitbox so it extends from player to attack_range
	
	# Position hitbox closer to player - the far edge reaches attack_range distance
	match _locked_facing:
		Vector2.UP:
			hitbox_offset = Vector2(0, -hitbox_half_distance)
		Vector2.DOWN:
			hitbox_offset = Vector2(0, hitbox_half_distance)
		Vector2.LEFT:
			hitbox_offset = Vector2(-hitbox_half_distance, 0)
		Vector2.RIGHT:
			hitbox_offset = Vector2(hitbox_half_distance, 0)
	
	# Use sprite center position instead of collision shape center (feet)
	# The sprite is positioned at (0, -20) relative to the player origin
	var sprite_center_position = player.global_position + player.sprite.position
	_current_hitbox.global_position = sprite_center_position + hitbox_offset

func _cleanup_hitbox():
	"""Remove the active hitbox when attack ends"""
	if _current_hitbox and is_instance_valid(_current_hitbox):
		_current_hitbox.deactivate()
		_current_hitbox.queue_free()
		_current_hitbox = null

# ─────────── ATTACK RANGE MODIFICATION METHODS ───────────
func set_attack_range(new_range: float):
	"""Set attack range - useful for buffs, upgrades, or different weapons"""
	attack_range = new_range

func get_attack_range() -> float:
	"""Get current attack range"""
	return attack_range

func multiply_attack_range(multiplier: float):
	"""Multiply attack range by a factor - useful for temporary buffs"""
	attack_range *= multiplier

func add_attack_range_bonus(bonus: float):
	"""Add flat bonus to attack range - useful for equipment/upgrades"""
	attack_range += bonus

# ─────────── ATTACK-DODGE HELPER ───────────
func _is_retreat_movement(movement_dir: Vector2, attack_dir: Vector2) -> bool:
	"""Check if player is moving opposite to attack direction (attack-dodge retreat)"""
	# For side attacks, check if moving in opposite horizontal direction
	if attack_dir == Vector2.LEFT and movement_dir.x > 0.3:
		return true  # Attacking left, moving right (retreat dodge)
	if attack_dir == Vector2.RIGHT and movement_dir.x < -0.3:
		return true  # Attacking right, moving left (retreat dodge)
	
	# For vertical attacks, check if moving in opposite vertical direction  
	if attack_dir == Vector2.UP and movement_dir.y > 0.3:
		return true  # Attacking up, moving down (retreat dodge)
	if attack_dir == Vector2.DOWN and movement_dir.y < -0.3:
		return true  # Attacking down, moving up (retreat dodge)
	
	return false

func _redirect_hitbox_to_direction(new_direction: Vector2):
	"""Redirect the existing attack hitbox to the new dodge direction"""
	if not _current_hitbox or not is_instance_valid(_current_hitbox):
		return
	
	# Calculate new hitbox position based on new direction
	var hitbox_offset = Vector2.ZERO
	var hitbox_half_distance = attack_range * 0.5
	
	match new_direction:
		Vector2.UP:
			hitbox_offset = Vector2(0, -hitbox_half_distance)
		Vector2.DOWN:
			hitbox_offset = Vector2(0, hitbox_half_distance)
		Vector2.LEFT:
			hitbox_offset = Vector2(-hitbox_half_distance, 0)
		Vector2.RIGHT:
			hitbox_offset = Vector2(hitbox_half_distance, 0)
	
	# Move existing hitbox to new position
	var sprite_center_position = player.global_position + player.sprite.position
	_current_hitbox.global_position = sprite_center_position + hitbox_offset
