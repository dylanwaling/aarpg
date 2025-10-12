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
	else:
		print("Warning: Attack effect animation '", effect_anim_name, "' not found")

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
	# Keep facing locked by re-applying it each frame (prevents Player.update_facing from changing it).
	if lock_facing:
		player.facing = _locked_facing
		# Also ensure sprite flipping matches the locked facing direction
		player.sprite.flip_h = (_locked_facing == Vector2.LEFT)
		# Update sprite offset to match the locked direction
		if _locked_facing == Vector2.LEFT:
			player.sprite.offset.x = -1
		else:
			player.sprite.offset.x = 0

	# Handle movement during attack (slow movement if not stopped)
	if not stop_movement:
		# Allow slow movement during attack
		if player.direction != Vector2.ZERO:
			player.velocity = player.direction * attack_movement_speed
		else:
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
			push_warning("No hitbox scene found! Create a Hitbox.tscn in GeneralNodes/Hitbox/")
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
	
	# Configure the hitbox damage and timing values
	_current_hitbox.damage = attack_damage
	_current_hitbox.knockback_force = knockback_strength
	_current_hitbox.hit_duration = hitbox_duration
	_current_hitbox.hit_type = _current_hitbox.HitType.COMBO
	
	# NOTE: Collision layers and masks are set in the Hitbox.tscn scene in the UI
	# This respects your preference to keep collision settings in the inspector
	
	# Activate the hitbox to start damage detection
	_current_hitbox.activate_hitbox()

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
		_current_hitbox.deactivate_hitbox()
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