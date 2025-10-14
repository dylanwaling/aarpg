## HURTBOX - Receives Damage and Forwards to Health
##
## Simple interface: take_hit() method that finds health component and applies damage.
## No complex collision logic - just clean damage forwarding.

extends Area2D
class_name HurtBox

# ─────────── INTERNAL REFERENCES ───────────
var _health_component: Node = null
var _damage_immunity_timer: float = 0.0
var _damage_immunity_duration: float = 0.5  # Half second of immunity after taking damage

func _ready():
	# Find the Health component
	_find_health_component()

func _process(delta):
	# Count down immunity timer
	if _damage_immunity_timer > 0.0:
		_damage_immunity_timer -= delta

func take_hit(damage_amount: int, knockback_force: float, source_position: Vector2):
	"""Main interface - called by hitboxes to deal damage"""
	if not _health_component:
		print("HurtBox: No health component found!")
		return
		
	# Check damage immunity
	if _damage_immunity_timer > 0.0:
		print("HurtBox: Still immune to damage (" + str(_damage_immunity_timer) + "s left)")
		return
		
	# Start immunity period
	_damage_immunity_timer = _damage_immunity_duration
	
	# Apply damage
	_health_component.take_damage(damage_amount)
	
	# Apply knockback to parent
	var parent = get_parent()
	if parent and parent.has_method("apply_knockback") and knockback_force > 0:
		var direction = (global_position - source_position).normalized()
		var knockback_vector = direction * knockback_force
		parent.apply_knockback(knockback_vector)

func _find_health_component():
	"""Find the Health component on this node or parent"""
	# Check children of this hurtbox
	for child in get_children():
		if child.has_method("take_damage") and child.has_method("get_health"):
			_health_component = child
			return
	
	# Check siblings (other children of parent)
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("take_damage") and child.has_method("get_health"):
				_health_component = child
				return



# ─────────── UTILITY METHODS ───────────
func get_health_component() -> Node:
	"""Get reference to the health component"""
	return _health_component

func is_alive() -> bool:
	"""Check if the entity is still alive"""
	if _health_component and _health_component.has_method("is_alive"):
		return _health_component.is_alive()
	return true

func get_current_health() -> int:
	"""Get current health from the health component"""
	if _health_component and _health_component.has_method("get_health"):
		return _health_component.get_health()
	return 0

# ─────────── MODULAR SETUP METHODS ───────────
# Setup methods for different entity types - now just for debugging
func setup_player_hurtbox():
	"""Configure this hurtbox to receive damage as a player"""
	print("Player HurtBox setup called - Scene Layer: ", collision_layer, " Scene Mask: ", collision_mask)

func setup_enemy_hurtbox():
	"""Configure this hurtbox to receive damage as an enemy"""
	print("Enemy HurtBox setup called - Scene Layer: ", collision_layer, " Scene Mask: ", collision_mask)

func setup_environment_hurtbox():
	"""Configure this hurtbox for environment objects (plants, etc.)"""
	print("Environment HurtBox setup called - Scene Layer: ", collision_layer, " Scene Mask: ", collision_mask)

# Note: Visual effects and death handling are now managed by the Health component

# End of modular HurtBox system
