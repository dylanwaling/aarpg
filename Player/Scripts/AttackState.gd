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

# ─────────── ATTACK BEHAVIOR YOU CAN TWEAK ───────────
@export var attack_duration: float = 0.35           # Total attack animation duration in seconds
@export var stop_movement: bool = false             # Whether to stop player movement during attack
@export var attack_movement_speed: float = 30.0     # Movement speed during attack (if allowed)
@export var lock_facing: bool = true                # Whether to lock facing direction during attack

# ─────────── DAMAGE HITBOX YOU CAN TWEAK ───────────
@export var hitbox_delay: float = 0.1               # Wind-up time before damage activates
@export var hitbox_duration: float = 0.15           # How long damage hitbox stays active
@export var attack_range: float = 70.0              # Attack reach distance (upgradeable)
@export var hitbox_scene: PackedScene               # Hitbox scene file (drag from FileSystem)

# ─────────── INTERNAL ATTACK STATE (DON'T MODIFY) ───────────
var _time_left: float = 0.0                         # Countdown timer for attack duration
var _attack_sound: AudioStream                      # Cached attack sound to avoid repeated preload
var _locked_facing: Vector2 = Vector2.DOWN          # Direction locked when attack started  
var _hitbox_activated: bool = false                 # Whether hitbox has been activated this attack



# ─────────── STARTING AN ATTACK ───────────
func enter(_from):
	# Lock facing direction to prevent mid-attack spinning
	if lock_facing:
		_locked_facing = player.facing

	# Handle movement during attack
	if stop_movement:
		player.velocity = Vector2.ZERO  # Complete stop
	# Otherwise allow slow movement (handled in update())

	# Start attack animation matching facing direction
	player.play_anim("attack")
	
	# Show visual effects and play sounds
	_show_and_play_attack_effects()
	
	# Set up damage hitbox with wind-up delay
	_setup_attack_hitbox()

	# Initialize attack timing
	_time_left = attack_duration
	_hitbox_activated = false

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
	# ─────────── FLEXIBLE AUDIO SYSTEM ───────────
	# First, try to find a dedicated AttackAudio node in the player scene
	var audio_player = player.get_node_or_null("AttackAudio")
	if audio_player and audio_player is AudioStreamPlayer2D:
		# Great! Found a dedicated audio node, just play it
		audio_player.play()
	else:
		# FALLBACK: No dedicated audio node found, create a temporary one
		# This ensures attacks always have sound even if scene setup is incomplete
		var temp_audio = AudioStreamPlayer2D.new()
		# Load the sword sound file (cached to avoid repeated loading)
		if not _attack_sound:
			_attack_sound = preload("res://Player/Audio/SwordSwoosh.wav")
		temp_audio.stream = _attack_sound
		player.add_child(temp_audio)  # Add to scene so it can play
		temp_audio.play()  # Play the sound
		# CLEANUP: Remove temporary audio node when sound finishes playing
		temp_audio.finished.connect(func(): temp_audio.queue_free())

func _update_attack_effects():
	# ─────────── VISUAL EFFECTS DIRECTION SYSTEM ───────────
	# Get the container that holds all the sword swoosh/slash graphics
	var attack_fx_node = player.get_node("Sprite2D/AttackFX")
	
	# Make the attack effects face the same direction as the player
	# We use scale flipping which works perfectly with the animation system
	if _locked_facing == Vector2.LEFT or _locked_facing == Vector2.RIGHT:
		# For left/right attacks, check if player sprite is flipped
		if player.sprite.flip_h:  # Player is facing left
			attack_fx_node.scale.x = -1  # Mirror the sword effects to match
		else:  # Player is facing right
			attack_fx_node.scale.x = 1   # Keep effects normal
	else:  # Up/down attacks don't need horizontal flipping
		attack_fx_node.scale.x = 1       # Always keep up/down effects normal

# ─────────── ATTACK LOGIC EVERY FRAME ───────────
func update(delta):
	# ─────────── ATTACK MOVEMENT SYSTEM ───────────
	# Handle movement during attack (if movement isn't completely disabled)
	if not stop_movement:
		# Check if player is trying to move while attacking
		if player.direction != Vector2.ZERO:
			# Start with slow attack movement speed
			var movement_velocity = player.direction * attack_movement_speed
			
			# SPECIAL FEATURE: Attack-dodge system for tactical combat
			# If player moves OPPOSITE to attack direction, they get a speed boost for retreating
			if _is_retreat_movement(player.direction, _locked_facing):
				# Retreat movement is much faster for tactical dodging
				movement_velocity = player.direction * (player.move_speed * 1.5)
				
				# Update sprite and redirect attack when dodge starts
				var new_dodge_direction = Vector2.ZERO
				
				# ═══════════ HORIZONTAL DODGE SYSTEM ═══════════
				# When player moves left/right during attack, they can redirect mid-swing
				if player.direction.x < 0:  # Player pressing LEFT during attack
					player.facing = Vector2.LEFT  # Change character facing direction
					player.update_facing()  # Update sprite flipping and positioning
					player.play_anim("attack")  # Switch to left-facing attack animation
					_update_attack_effects()  # Make sword effects face left too
					new_dodge_direction = Vector2.LEFT  # Remember new direction for hitbox
				elif player.direction.x > 0:  # Player pressing RIGHT during attack
					player.facing = Vector2.RIGHT  # Change character facing direction
					player.update_facing()  # Update sprite flipping and positioning
					player.play_anim("attack")  # Switch to right-facing attack animation
					_update_attack_effects()  # Make sword effects face right too
					new_dodge_direction = Vector2.RIGHT  # Remember new direction for hitbox
				# ═══════════ VERTICAL DODGE SYSTEM (SEAMLESS ANIMATION SWITCHING) ═══════════
				# For up/down movement, we need to switch between different attack animations
				# The trick is to continue the animation from the SAME POINT to avoid visual jumps
				elif player.direction.y < 0:  # Player pressing UP during attack
					player.facing = Vector2.UP
					player.update_facing()  # Update sprite positioning
					
					# SEAMLESS SWITCH: Remember where we are in the current animation
					var current_position = player.anim.current_animation_position
					player.anim.play("attack_up", -1, 1.0, false)  # Start new animation
					player.anim.advance(current_position)  # Jump to same point - no restart!
					
					# SYNC VISUAL EFFECTS: Make sword animation match character animation timing
					var attack_fx_anim = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer")
					var fx_current_position = attack_fx_anim.current_animation_position
					attack_fx_anim.play("attack_up", -1, 1.0, false)  # Switch sword effect
					attack_fx_anim.advance(fx_current_position)  # Keep same timing - perfect sync!
					
					_update_attack_effects()  # Update sword visual positioning
					new_dodge_direction = Vector2.UP  # Tell hitbox system about new direction
				elif player.direction.y > 0:  # Moving down  
					player.facing = Vector2.DOWN
					player.update_facing()  # Use centralized sprite management
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
				if player.hitbox and _hitbox_activated:
					_redirect_hitbox_to_direction(new_dodge_direction)
			else:
				# Normal attack movement - keep sprite locked to attack direction
				if lock_facing:
					player.facing = _locked_facing
					player.update_facing()  # Use centralized sprite management
			
			player.velocity = movement_velocity
		else:
			# No movement - keep sprite locked to attack direction
			if lock_facing:
				player.facing = _locked_facing
				player.update_facing()  # Use centralized sprite management
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

# ─────────── INPUT HANDLING DURING ATTACK ───────────
func handle_input(_event):
	# Player is committed to attack - no input changes allowed
	# Future: Could add combo buffering here
	pass

# ─────────── ATTACK PHYSICS ───────────
func physics_update(_delta):
	# Physics handled by movement logic in update() function
	# Player.gd calls move_and_slide() automatically
	pass

# ─────────── WHEN LEAVING ATTACK STATE ───────────
func exit(_to):
	# Remove active damage hitbox
	_cleanup_hitbox()
	
	# Clean up visual effects
	var attack_fx_sprite = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite")
	var attack_fx_anim = player.get_node("Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer")
	var attack_fx_node = player.get_node("Sprite2D/AttackFX")
	
	# Hide effects and stop animations
	attack_fx_sprite.visible = false
	attack_fx_anim.stop()
	# Reset visual transformations
	attack_fx_node.scale.x = 1

# ─────────── HITBOX SYSTEM METHODS ───────────
func _setup_attack_hitbox():
	"""Prepare the attack's damage zone - delayed activation for wind-up"""
	# ═══════════ VERIFY HITBOX EXISTS ═══════════
	if not player.hitbox:
		push_error("AttackState: Player has no hitbox! Add a HitBox node to the Player scene.")
		return
	
	# Position hitbox based on attack direction IMMEDIATELY (before activation)
	_position_hitbox_for_direction()
	
	# Schedule hitbox activation after wind-up delay
	get_tree().create_timer(hitbox_delay).timeout.connect(_activate_damage_hitbox)

func _activate_damage_hitbox():
	"""Turn on damage dealing after wind-up period"""
	if not player.hitbox or _hitbox_activated:
		return
	
	# Activate the hitbox (starts detecting collisions and dealing damage)
	player.hitbox.activate()
	_hitbox_activated = true

func _position_hitbox_for_direction():
	"""Position the damage area in front of the player based on which way they're attacking"""
	if not player.hitbox:
		return
		
	# ─────────── HITBOX POSITIONING MATH ───────────
	var hitbox_offset = Vector2.ZERO
	# Position hitbox so its CENTER is halfway between player and max attack range
	# This means the hitbox extends from the player out to the full attack distance
	var hitbox_half_distance = attack_range * 0.5
	
	# Calculate offset direction based on which way the player is attacking
	match _locked_facing:
		Vector2.UP:     # Attacking upward
			hitbox_offset = Vector2(0, -hitbox_half_distance)
		Vector2.DOWN:   # Attacking downward  
			hitbox_offset = Vector2(0, hitbox_half_distance)
		Vector2.LEFT:   # Attacking to the left
			hitbox_offset = Vector2(-hitbox_half_distance, 0)
		Vector2.RIGHT:  # Attacking to the right
			hitbox_offset = Vector2(hitbox_half_distance, 0)
	
	# ─────────── IMPORTANT: USE SPRITE CENTER, NOT FEET ───────────
	# The player's collision shape is at their feet, but attacks come from their body/weapon
	# So we position hitboxes relative to the sprite center instead of the collision shape
	var sprite_center_position = player.global_position + player.sprite.position
	player.hitbox.global_position = sprite_center_position + hitbox_offset

func _cleanup_hitbox():
	"""Deactivate the hitbox when attack ends"""
	if player.hitbox:
		player.hitbox.deactivate()
	_hitbox_activated = false

# ─────────── ATTACK RANGE ACCESS (FOR SYSTEMS INTEGRATION) ───────────
func get_attack_range() -> float:
	"""Get current attack range - used by upgrade systems, AI, and UI systems"""
	# This function allows other systems to query current attack range:
	# - Upgrade systems can show current vs upgraded range
	# - Enemy AI can maintain proper distance from player attacks
	# - UI can display attack range in tooltips or stats
	return attack_range

# ─────────── ATTACK-DODGE HELPER ───────────
func _is_retreat_movement(movement_dir: Vector2, attack_dir: Vector2) -> bool:
	"""Detects if player is doing a tactical retreat dodge (moving away from attack direction)"""
	# ─────────── RETREAT DETECTION LOGIC ───────────
	# Check horizontal retreat moves (left/right attacks)
	if attack_dir == Vector2.LEFT and movement_dir.x > 0.3:
		return true  # Attacking left but moving right = backing away (retreat dodge)
	if attack_dir == Vector2.RIGHT and movement_dir.x < -0.3:
		return true  # Attacking right but moving left = backing away (retreat dodge)
	
	# Check vertical retreat moves (up/down attacks)
	if attack_dir == Vector2.UP and movement_dir.y > 0.3:
		return true  # Attacking up but moving down = backing away (retreat dodge)
	if attack_dir == Vector2.DOWN and movement_dir.y < -0.3:
		return true  # Attacking down but moving up = backing away (retreat dodge)
	
	# Not a retreat movement - could be advancing or side-stepping
	return false

func _redirect_hitbox_to_direction(new_direction: Vector2):
	"""Reposition hitbox mid-attack when player dodge-redirects their attack"""
	if not player.hitbox:
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
	player.hitbox.global_position = sprite_center_position + hitbox_offset
