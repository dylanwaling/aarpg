## PROFESSIONAL HURTBOX SYSTEM - Receives Damage via Clean Interface
##
## Core Responsibilities:
## • Receives damage through take_hit(damage, knockback, source_pos) method calls
## • Automatically finds and forwards damage to Health component  
## • Applies knockback to parent entity (Player/Enemy/Plant)
## • Provides damage immunity period to prevent rapid-fire damage
## • Collision layers configured in scene editor, not hardcoded in script
##
## Usage: Just add to scene and configure collision layers in inspector. Everything else is automatic.

extends Area2D
class_name HurtBox

# ─────────── DAMAGE IMMUNITY SETTINGS ───────────
@export var damage_immunity_duration: float = 0.5  # Seconds of immunity after taking damage
@export var knockback_multiplier: float = 1.0       # Multiplier for knockback force received

# ─────────── INTERNAL REFERENCES ───────────
var _health_component: Node = null
var _damage_immunity_timer: float = 0.0

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
		return
		
	# Check damage immunity (prevents rapid damage from same source)
	if _damage_immunity_timer > 0.0:
		return
		
	# Start immunity period
		# Apply immunity period (prevents rapid-fire damage)
	_damage_immunity_timer = damage_immunity_duration
	
	# Apply damage
	_health_component.take_damage(damage_amount)
	
	# Apply knockback to parent (skip for plants and environment objects)
	var parent = get_parent()
	if parent and parent.has_method("apply_knockback") and knockback_force > 0 and not parent.is_in_group("environment"):
		# Direction FROM source TO target (pushes away from attacker)
		var direction = (global_position - source_position).normalized()
		var final_knockback_force = knockback_force * knockback_multiplier
		var knockback_vector = direction * final_knockback_force
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

# End of HurtBox system - all configuration handled via scene inspector
