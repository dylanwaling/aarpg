## UNIVERSAL HITBOX SYSTEM - Completely Modular Damage Dealer
##
## This hitbox DEALS damage to anything it touches that can receive damage.
## It works the same way for player attacks, enemy attacks, environmental hazards, etc.
## 
## How it works:
## 1. Configure collision layers (what this hitbox is on, what it can hit)
## 2. Set damage amount, knockback, duration, etc.
## 3. Activate it (starts detecting collisions)
## 4. When it hits something, it looks for Health components and damages them
##
## The key: EVERYTHING uses Health components to receive damage.
##
## Scene Configuration:
## Set collision_layer and collision_mask in the editor - this script reads those values
## collision_layer = what layer this hitbox is on
## collision_mask = what layers this hitbox can detect/damage

extends Area2D
class_name UniversalHitbox

# ─────────── DAMAGE CONFIGURATION ───────────
@export var damage: int = 10                    # How much damage this deals
@export var knockback_force: float = 100.0      # Knockback strength
@export var hit_duration: float = 0.1           # How long hitbox stays active
@export var destroy_on_hit: bool = false        # Destroy after first hit

# ─────────── COLLISION CONFIGURATION ───────────  
# Note: collision_layer and collision_mask are set in the scene editor

# ─────────── INTERNAL STATE ───────────
var _active: bool = false
var _hit_targets: Array = []

func _ready():
	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Debug scene settings
	print("Hitbox initialized - Layer: ", collision_layer, " Mask: ", collision_mask)
	
	# Start inactive
	_active = false
	monitoring = false



# ─────────── ACTIVATION SYSTEM ───────────
func activate_hitbox():
	"""Start dealing damage"""
	_active = true
	monitoring = true
	_hit_targets.clear()
	
	print("Hitbox activated: damage=", damage, " scene_layer=", collision_layer, " scene_mask=", collision_mask)
	print("Hitbox position: ", global_position)
	
	# Debug: Check what's nearby
	_debug_nearby_objects()
	
	# Auto-deactivate after duration
	if hit_duration > 0:
		await get_tree().create_timer(hit_duration).timeout
		deactivate_hitbox()

func deactivate_hitbox():
	"""Stop dealing damage"""
	_active = false
	monitoring = false
	print("Hitbox deactivated - hit ", _hit_targets.size(), " targets")

# ─────────── COLLISION DETECTION ───────────
func _on_area_entered(area):
	"""Hit an Area2D (like a HurtBox)"""
	if not _active:
		return
	
	# Check if we already hit this area or its parent
	if area in _hit_targets:
		return
	var parent = area.get_parent()
	if parent and parent in _hit_targets:
		return
		
	print("Hitbox hit area: ", area.name, " on node: ", area.get_parent().name if area.get_parent() else "no parent")
	_process_hit(area)
	
	# Also track the parent to prevent multiple hits
	if parent:
		_hit_targets.append(parent)

func _on_body_entered(body):
	"""Hit a CharacterBody2D directly"""  
	if not _active:
		return
		
	if body in _hit_targets:
		return
		
	print("Hitbox hit body: ", body.name)
	_process_hit(body)

# ─────────── UNIVERSAL DAMAGE SYSTEM ───────────
func _process_hit(target):
	"""Deal damage using the universal Health system"""
	_hit_targets.append(target)
	
	# Find a Health component to damage
	var health_component = _find_health_component(target)
	if health_component:
		print("Dealing ", damage, " damage to health component")
		health_component.take_damage(damage)
		_apply_knockback(target, health_component)
	else:
		print("No health component found on target: ", target.name)
	
	if destroy_on_hit:
		deactivate_hitbox()

func _find_health_component(target) -> Node:
	"""Find a Health component on the target or its parent"""
	# Check the target itself for a Health component
	for child in target.get_children():
		if child.has_method("take_damage") and child.has_method("get_health"):
			return child
	
	# Check the target's parent for a Health component
	var parent = target.get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("take_damage") and child.has_method("get_health"):
				return child
	
	# Check if target itself is a health component
	if target.has_method("take_damage") and target.has_method("get_health"):
		return target
		
	return null

func _apply_knockback(target, health_component):
	"""Apply knockback force"""
	if knockback_force <= 0:
		return
		
	var knockback_direction = (target.global_position - global_position).normalized()
	var knockback_vector = knockback_direction * knockback_force
	
	# Try to apply knockback to the entity that owns the health component
	var entity = health_component.get_parent()
	if entity and entity.has_method("apply_knockback"):
		print("Applying knockback via method: ", knockback_vector)
		entity.apply_knockback(knockback_vector)
	elif entity and entity is CharacterBody2D:
		print("Applying direct knockback to CharacterBody2D: ", knockback_vector)
		# Set velocity directly instead of adding to prevent infinite sliding
		entity.velocity = knockback_vector
		# Add a timer to stop the knockback
		_stop_knockback_after_delay(entity, 0.2)

func _stop_knockback_after_delay(entity: CharacterBody2D, delay: float):
	"""Stop knockback velocity after a delay"""
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(entity):
		print("Stopping knockback for: ", entity.name)
		# Set velocity back to zero to stop sliding
		entity.velocity = Vector2.ZERO

# ─────────── SETUP METHODS ───────────
func setup_player_attack(damage_amount: int = 10, knockback: float = 15.0):
	"""Setup as player attack - uses scene collision settings"""
	damage = damage_amount
	knockback_force = knockback
	print("Player attack setup - damage: ", damage, " scene_layer: ", collision_layer, " scene_mask: ", collision_mask)

func setup_enemy_attack(damage_amount: int = 5, knockback: float = 25.0):
	"""Setup as enemy attack - uses scene collision settings"""
	damage = damage_amount
	knockback_force = knockback
	destroy_on_hit = true  # Enemy attacks should deactivate after first hit
	print("Enemy attack setup - damage: ", damage, " scene_layer: ", collision_layer, " scene_mask: ", collision_mask)

func configure_custom(_layer: int, _targets: Array, damage_amount: int = 10):
	"""Setup with custom configuration - ignores layer/targets, uses scene settings"""
	damage = damage_amount
	print("Custom setup - damage: ", damage, " scene_layer: ", collision_layer, " scene_mask: ", collision_mask)

func _debug_nearby_objects():
	"""Debug what objects are nearby"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 0xFFFFFFFF  # Check all layers
	
	var results = space_state.intersect_point(query, 10)
	print("Objects at hitbox position: ", results.size())
	for result in results:
		var obj = result.collider
		# Only access collision_layer if the object has it
		var layer_info = ""
		if "collision_layer" in obj:
			layer_info = " layer: " + str(obj.collision_layer)
		print("  Found: ", obj.name, layer_info)

# ─────────── LEGACY COMPATIBILITY METHODS ───────────
func setup_player_attack_hitbox(attack_damage: int = 10, knockback: float = 50.0):
	"""Setup for player attack hitboxes - deals damage to enemies"""
	setup_player_attack(attack_damage, knockback)

func setup_enemy_attack_hitbox(attack_damage: int = 5, knockback: float = 75.0):
	"""Setup for enemy attack hitboxes - deals damage to player"""
	setup_enemy_attack(attack_damage, knockback)

func setup_as_player_hurtbox(damage_amount: int = 5):
	"""Legacy: Player hurts enemies here"""
	setup_player_attack(damage_amount)

func setup_as_enemy_hurtbox(damage_amount: int = 1):
	"""Legacy: Enemy hurts player here"""
	setup_enemy_attack(damage_amount)
# End of file
