## HURTBOX SYSTEM - Receives Damage and Interactions
##
## This is the "receiving" side of the damage system. While Hitboxes DEAL damage,
## HurtBoxes RECEIVE damage. Think of it like this:
## - Hitbox = Sword that can cut things
## - HurtBox = Body part that can be cut by swords
##
## The HurtBox detects when enemy attacks, projectiles, or environmental hazards
## hit the player/enemy and processes what should happen (take damage, get knocked back, etc.)
##
## This system works with your existing collision layers:
## - Player HurtBox on layer 1 (gets hit by enemy attacks on layer 9)
## - Enemy HurtBox on layer 9 (gets hit by player attacks on layer 1)

extends Area2D

# ─────────── HURTBOX CONFIGURATION ───────────
@export var max_health: int = 100               # Maximum health points
@export var current_health: int = 100           # Current health (can be damaged)
@export var defense: int = 0                    # Damage reduction (subtracted from incoming damage)
@export var invincibility_time: float = 0.5     # Seconds of immunity after taking damage
@export var knockback_resistance: float = 0.0   # 0.0 = full knockback, 1.0 = no knockback

# ─────────── DAMAGE REACTION SETTINGS ───────────
@export var damage_flash_color: Color = Color.RED   # Color to flash when taking damage
@export var damage_flash_duration: float = 0.1      # How long the damage flash lasts
@export var death_animation: String = "death"       # Animation to play when health reaches 0

# ─────────── INTERNAL TRACKING ───────────
var _invincible: bool = false                   # Currently immune to damage
var _invincible_timer: float = 0.0             # Countdown for invincibility
var _original_modulate: Color                  # Store original sprite color for damage flash
var _owner_body: Node = null                   # The CharacterBody2D or other node that owns this hurtbox

# ─────────── SIGNALS FOR COMMUNICATION ───────────
signal health_changed(new_health: int, max_health: int)  # When health goes up/down
signal damage_taken(damage_amount: int, attacker_position: Vector2)  # When hurt
signal died()                                            # When health reaches 0
signal knockback_applied(knockback_force: Vector2)       # When pushed around

# ─────────── SETUP AND INITIALIZATION ───────────
func _ready():
	# Connect collision detection
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Find the owner (parent CharacterBody2D, RigidBody2D, etc.)
	_owner_body = get_parent()
	
	# Store original sprite color for damage flashing
	var sprite = _find_sprite_node()
	if sprite:
		_original_modulate = sprite.modulate
	
	# Make sure current health doesn't exceed max
	current_health = min(current_health, max_health)
	
	# Emit initial health signal
	health_changed.emit(current_health, max_health)

func _process(delta):
	# Handle invincibility timer
	if _invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			_invincible = false

# ─────────── COLLISION DETECTION ───────────
func _on_area_entered(area):
	"""Called when a Hitbox or other Area2D touches this HurtBox"""
	# Only process if it's actually a hitbox that can hurt us
	if area.has_method("_get_area_collision_layer"):
		_process_incoming_hit(area)

func _on_body_entered(body):
	"""Called when a CharacterBody2D touches this HurtBox (like projectiles)"""
	# Check if this body can damage us (has damage properties)
	if body.has_method("get_damage") or body.has_signal("damage_dealt"):
		_process_incoming_hit(body)

# ─────────── DAMAGE PROCESSING ───────────
func _process_incoming_hit(attacker):
	"""Handle what happens when something tries to hurt us"""
	# Skip if we're currently invincible
	if _invincible:
		return
	
	# Try to get damage amount from the attacker
	var damage_amount = _extract_damage_from_attacker(attacker)
	if damage_amount <= 0:
		return
	
	# Get attacker position for knockback direction
	var attacker_pos = attacker.global_position
	
	# Apply the damage
	take_damage(damage_amount, attacker_pos)
	
	# Try to get knockback from the attacker
	var knockback_force = _extract_knockback_from_attacker(attacker)
	if knockback_force > 0:
		apply_knockback_from_position(attacker_pos, knockback_force)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	"""Main method for receiving damage from any source"""
	# Skip if already dead or invincible
	if current_health <= 0 or _invincible:
		return
	
	# Apply defense (damage reduction)
	var final_damage = max(1, amount - defense)  # Always take at least 1 damage
	
	# Subtract health
	current_health = max(0, current_health - final_damage)
	
	# Emit signals so other systems know what happened
	damage_taken.emit(final_damage, source_position)
	health_changed.emit(current_health, max_health)
	
	# Start invincibility period
	_become_invincible()
	
	# Show damage effects
	_show_damage_effects()
	
	# Check if we died
	if current_health <= 0:
		_handle_death()

func heal(amount: int):
	"""Restore health points"""
	if current_health <= 0:  # Can't heal if dead
		return
	
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

# ─────────── KNOCKBACK SYSTEM ───────────
func apply_knockback_from_position(attacker_position: Vector2, force: float):
	"""Push the owner away from an attacker's position"""
	if knockback_resistance >= 1.0:
		return  # Completely resistant to knockback
	
	# Calculate direction from attacker to us
	var knockback_direction = (global_position - attacker_position).normalized()
	var final_force = force * (1.0 - knockback_resistance)
	var knockback_vector = knockback_direction * final_force
	
	# Apply knockback to the owner
	apply_knockback(knockback_vector)

func apply_knockback(knockback_force: Vector2):
	"""Apply a specific knockback vector to the owner"""
	if not _owner_body:
		return
	
	# Apply knockback based on the owner's type
	if _owner_body.has_method("apply_knockback"):
		_owner_body.apply_knockback(knockback_force)
	elif _owner_body is CharacterBody2D:
		# Direct velocity modification
		_owner_body.velocity += knockback_force
	elif _owner_body is RigidBody2D:
		# Physics-based push
		_owner_body.apply_central_impulse(knockback_force)
	
	# Emit signal for other systems
	knockback_applied.emit(knockback_force)

# ─────────── VISUAL EFFECTS ───────────
func _show_damage_effects():
	"""Flash red when taking damage"""
	var sprite = _find_sprite_node()
	if not sprite:
		return
	
	# Flash red
	sprite.modulate = damage_flash_color
	
	# Return to normal color after flash duration
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", _original_modulate, damage_flash_duration)

func _become_invincible():
	"""Start invincibility period with visual feedback"""
	_invincible = true
	_invincible_timer = invincibility_time
	
	# Optional: Make sprite blink during invincibility
	var sprite = _find_sprite_node()
	if sprite:
		var blink_tween = create_tween()
		blink_tween.set_loops(int(invincibility_time / 0.1))
		blink_tween.tween_property(sprite, "modulate:a", 0.5, 0.05)
		blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.05)

# ─────────── DEATH HANDLING ───────────
func _handle_death():
	"""Called when health reaches 0"""
	# Emit death signal
	died.emit()
	
	# Try to play death animation
	var anim_player = _find_animation_player()
	if anim_player and anim_player.has_animation(death_animation):
		anim_player.play(death_animation)
	
	# Disable further damage
	monitoring = false
	
	# You can add more death logic here like:
	# - Drop items
	# - Play death sound
	# - Remove from scene after animation
	# - Respawn logic

# ─────────── HELPER METHODS ───────────
func _extract_damage_from_attacker(attacker) -> int:
	"""Try to find how much damage the attacker deals"""
	# Try different common damage property names
	if attacker.has_method("get_damage"):
		return attacker.get_damage()
	elif "damage" in attacker:
		return attacker.damage
	elif attacker.has_method("get_attack_damage"):
		return attacker.get_attack_damage()
	else:
		return 10  # Default damage if we can't find it

func _extract_knockback_from_attacker(attacker) -> float:
	"""Try to find how much knockback the attacker applies"""
	if "knockback_force" in attacker:
		return attacker.knockback_force
	elif "knockback" in attacker:
		return attacker.knockback
	elif attacker.has_method("get_knockback"):
		return attacker.get_knockback()
	else:
		return 50.0  # Default knockback

func _find_sprite_node() -> Node:
	"""Find the sprite node for visual effects"""
	# Look in common locations for sprites
	if _owner_body:
		var sprite = _owner_body.get_node_or_null("Sprite2D")
		if sprite:
			return sprite
		sprite = _owner_body.get_node_or_null("AnimatedSprite2D")
		if sprite:
			return sprite
	return null

func _find_animation_player() -> AnimationPlayer:
	"""Find the animation player for death animations"""
	if _owner_body:
		return _owner_body.get_node_or_null("AnimationPlayer")
	return null

# ─────────── PUBLIC API METHODS ───────────
func is_dead() -> bool:
	"""Check if this entity is dead"""
	return current_health <= 0

func is_invincible() -> bool:
	"""Check if currently immune to damage"""
	return _invincible

func get_health_percentage() -> float:
	"""Get health as a percentage (0.0 to 1.0)"""
	return float(current_health) / float(max_health)

func set_max_health(new_max: int):
	"""Change maximum health and adjust current health if needed"""
	max_health = new_max
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)
