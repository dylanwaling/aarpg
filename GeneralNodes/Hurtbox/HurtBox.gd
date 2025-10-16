## HURTBOX COMPONENT - Receives and Processes Incoming Damage
##
## This component acts as a "damage receiver" for any entity that can take damage.
## When hit by attacks, it finds the Health component and forwards the damage.
##
## Key Features:
## - Receives damage from Hitbox attacks via take_hit() interface
## - Automatically finds and communicates with Health component
## - Applies knockback physics to parent entity (Player/Enemy/etc.)
## - Damage immunity system prevents rapid-fire damage exploitation
## - Collision detection configured in scene inspector, not hardcoded
##
## Usage: Add HurtBox.tscn to any entity, configure collision layers in inspector.
## Make sure entity has Health component and optionally apply_knockback() method.

class_name HurtBox
extends Area2D

# ─────────── DAMAGE PROTECTION SETTINGS YOU CAN TWEAK ───────────
@export var damage_immunity_duration: float = 0.5    # Immunity period after taking damage (prevents spam)
@export var knockback_multiplier: float = 1.0        # Modify incoming knockback force (1.0 = normal, 0.5 = half, 2.0 = double)

# ─────────── INTEGRATION SETTINGS (SCENE-FIRST) ───────────
@export var environment_group_name: String = "environment"     # Group name for entities that don't receive knockback
# Direct method calls used for optimal performance (apply_knockback)
# Direct method calls used for optimal performance (take_damage, get_health)

# ─────────── INTERNAL COMPONENT STATE (DON'T MODIFY) ───────────
var _health_component: Node = null                 # Reference to the Health component we forward damage to
var _damage_immunity_timer: float = 0.0            # Countdown timer for damage immunity period

# ─────────── HURTBOX INITIALIZATION ───────────
func _ready():
	# Locate and connect to the Health component automatically
	_find_health_component()

func _process(delta):
	# ─────────── DAMAGE IMMUNITY COUNTDOWN ───────────
	# Count down the immunity timer (prevents rapid damage from same source)
	if _damage_immunity_timer > 0.0:
		_damage_immunity_timer -= delta

# ─────────── MAIN DAMAGE INTERFACE ───────────
func take_hit(damage_amount: int, knockback_force: float, source_position: Vector2):
	"""Process incoming damage from Hitbox attacks - this is the main entry point"""
	# ─────────── VALIDATION CHECKS ───────────
	# Can't take damage without a health component
	if not _health_component:
		push_warning("HurtBox: No health component found - cannot process damage")
		return
		
	# Check if we're in immunity period (prevents rapid-fire damage exploitation)
	if _damage_immunity_timer > 0.0:
		return  # Still immune from previous damage
		
	# ─────────── DAMAGE PROCESSING ───────────
	# Start immunity period to prevent damage spam
	_damage_immunity_timer = damage_immunity_duration
	
	# Forward damage to the Health component (optimized direct call)
	_health_component.take_damage(damage_amount)
	
	# ─────────── KNOCKBACK PHYSICS ───────────
	# Apply knockback to parent entity (if it supports knockback and isn't in environment group)
	var parent = get_parent()
	if parent and parent.has_method("apply_knockback") and knockback_force > 0 and not parent.is_in_group(environment_group_name):
		# Calculate knockback direction: FROM attacker TO victim (pushes away)
		var direction = (global_position - source_position).normalized()
		# Apply multiplier for different entity types (heavy enemies = less knockback)
		var final_knockback_force = knockback_force * knockback_multiplier
		var knockback_vector = direction * final_knockback_force
		# Send knockback to parent (Player, Enemy, etc.)
		parent.apply_knockback(knockback_vector)

func _find_health_component():
	"""Automatically locate the Health component this HurtBox should work with"""
	# ─────────── SEARCH STRATEGY 1: CHECK HURTBOX CHILDREN ───────────
	# Look for Health component as child of this HurtBox
	for child in get_children():
		if child.has_method("take_damage") and child.has_method("get_health"):
			_health_component = child
			return
	
	# ─────────── SEARCH STRATEGY 2: CHECK SIBLING NODES ───────────
	# Look for Health component as sibling (other children of same parent)
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("take_damage") and child.has_method("get_health"):
				_health_component = child
				return
	
	# ─────────── ERROR HANDLING ───────────
	# No Health component found - this HurtBox won't be able to process damage
	push_error("HurtBox: No Health component found! Entity won't be able to take damage.")



# ─────────── UTILITY METHODS FOR OTHER SYSTEMS ───────────
func get_health_component() -> Node:
	"""Get reference to the connected Health component"""
	return _health_component

func is_alive() -> bool:
	"""Check if the entity is still alive (has health > 0)"""
	if not _health_component:
		push_warning("HurtBox: No health component found when checking if alive")
		return true  # Assume alive if no health component
	
	if _health_component.has_method("is_alive"):
		return _health_component.is_alive()
	else:
		# Fallback: check health directly if is_alive method doesn't exist
		return get_current_health() > 0

func get_current_health() -> int:
	"""Get current health points from the Health component"""
	if not _health_component:
		push_warning("HurtBox: No health component found when getting health")
		return 0
	
	if _health_component.has_method("get_health"):
		return _health_component.get_health()
	else:
		push_warning("HurtBox: Health component missing get_health() method")
		return 0

func validate_integration() -> bool:
	"""Validate that Health and HurtBox are properly integrated - call this for debugging"""
	if not _health_component:
		push_error("HurtBox Integration: No Health component found!")
		return false
	
	# Check Health component has required methods
	if not _health_component.has_method("take_damage"):
		push_error("HurtBox Integration: Health component missing take_damage() method!")
		return false
	
	if not _health_component.has_method("get_health"):
		push_error("HurtBox Integration: Health component missing get_health() method!")
		return false
	
	# Check if parent has knockback support
	var parent = get_parent()
	if parent and not parent.has_method("apply_knockback"):
		push_warning("HurtBox Integration: Parent missing apply_knockback() method - no knockback physics")
	
	# Check Health component's parent connection
	if _health_component.get("auto_connect_to_parent") and parent:
		if not parent.has_method("_on_health_died"):
			push_warning("HurtBox Integration: Parent missing _on_health_died method - death won't be handled")
	
	print("HurtBox Integration: All systems properly connected")
	return true

# HurtBox system complete - all configuration via scene inspector, no hardcoded values
