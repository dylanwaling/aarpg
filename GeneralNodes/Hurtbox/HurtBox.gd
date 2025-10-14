## MODULAR HURTBOX SYSTEM - Receives Damage and Forwards to Health Component
##
## This is a simple collision detector that finds incoming damage and forwards it
## to a Health component. It does NOT manage health itself - that's the Health component's job.
##
## How it works:
## 1. Detects collisions from enemy attacks/hazards (based on scene collision settings)
## 2. Finds the Health component (on self or parent)
## 3. Tells the Health component to take damage
## 4. Applies knockback to the parent entity
##
## Scene Configuration:
## Set collision_layer and collision_mask in the editor - this script reads those values

extends Area2D
class_name ModularHurtBox

# ─────────── CONFIGURATION ───────────
@export var knockback_strength: float = 100.0

# ─────────── INTERNAL REFERENCES ───────────
var _owner_body: Node = null                   # The CharacterBody2D or other node that owns this hurtbox
var _health_component: Node = null             # Reference to the Health component

# ─────────── SIGNALS FOR COMMUNICATION ───────────
signal damage_received(damage_amount: int, source_position: Vector2)  # When this hurtbox gets hit
signal knockback_applied(knockback_force: Vector2)                    # When pushed around

func _ready():
	# Connect collision detection
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Find the owner (parent entity)
	_owner_body = get_parent()
	
	# Find the Health component
	_find_health_component()
	
	# Debug current scene settings
	print("HurtBox initialized - Layer: ", collision_layer, " Mask: ", collision_mask)

func _find_health_component():
	"""Find the Health component on this node or parent"""
	# Check children of this hurtbox
	for child in get_children():
		if child.has_method("take_damage") and child.has_method("get_health"):
			_health_component = child
			return
	
	# Check siblings (other children of parent)
	if _owner_body:
		for child in _owner_body.get_children():
			if child.has_method("take_damage") and child.has_method("get_health"):
				_health_component = child
				return



# ─────────── COLLISION DETECTION ───────────
func _on_area_entered(area):
	"""Called when a Hitbox touches this HurtBox"""
	print("HurtBox hit by: ", area.name, " from: ", area.get_parent().name if area.get_parent() else "no parent")
	_process_incoming_hit(area)

func _on_body_entered(body):
	"""Called when a CharacterBody2D touches this HurtBox"""
	print("HurtBox hit by body: ", body.name)
	_process_incoming_hit(body)

# ─────────── DAMAGE PROCESSING ───────────
func _process_incoming_hit(attacker):
	"""Handle what happens when something tries to hurt us"""
	# Get damage from attacker
	var damage_amount = _extract_damage_from_attacker(attacker)
	if damage_amount <= 0:
		print("No damage from attacker: ", attacker.name)
		return
	
	print("Taking ", damage_amount, " damage")
	
	# Forward damage to Health component
	if _health_component:
		_health_component.take_damage(damage_amount)
	else:
		print("No health component found!")
	
	# Emit signal for other systems
	damage_received.emit(damage_amount, attacker.global_position)
	
	# Apply knockback
	var knockback_force = _extract_knockback_from_attacker(attacker)
	if knockback_force > 0:
		apply_knockback_from_position(attacker.global_position, knockback_force)

func _extract_damage_from_attacker(attacker) -> int:
	"""Get damage amount from the attacking object"""
	if "damage" in attacker:
		return attacker.damage
	elif attacker.has_method("get_damage"):
		return attacker.get_damage()
	else:
		return 0

func _extract_knockback_from_attacker(attacker) -> float:
	"""Get knockback force from the attacking object"""
	if "knockback_force" in attacker:
		return attacker.knockback_force
	elif attacker.has_method("get_knockback"):
		return attacker.get_knockback()
	else:
		return 0.0

# ─────────── KNOCKBACK SYSTEM ───────────
func apply_knockback_from_position(attacker_position: Vector2, force: float):
	"""Push the owner away from an attacker's position"""
	# Calculate direction from attacker to us
	var knockback_direction = (global_position - attacker_position).normalized()
	var knockback_vector = knockback_direction * force
	
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
