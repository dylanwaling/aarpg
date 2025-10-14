## HITBOX - Deals Damage to Targets
##
## Simple, focused responsibility: When activated, find targets and damage them once.
## No complex timing, no state management - just pure damage dealing.

extends Area2D
class_name Hitbox

# ─────────── CONFIGURATION ───────────
@export var damage: int = 10
@export var knockback_force: float = 50.0

# ─────────── INTERNAL STATE ───────────
var _is_active: bool = false
var _targets_hit: Array[Node] = []

func _ready():
	# Start disabled
	set_deferred("monitoring", false)
	
	# Connect collision signal
	area_entered.connect(_on_area_entered)

func activate():
	"""Activate hitbox to start dealing damage"""
	_is_active = true
	_targets_hit.clear()
	monitoring = true
	print("Hitbox activated: damage=", damage, " Layer=", collision_layer, " Mask=", collision_mask)
	
	# Debug: Check what areas are currently overlapping
	var overlapping = get_overlapping_areas()
	print("Currently overlapping with ", overlapping.size(), " areas: ", overlapping)

func deactivate():
	"""Deactivate hitbox"""
	_is_active = false
	monitoring = false
	print("Hitbox deactivated after hitting ", _targets_hit.size(), " targets")

func _on_area_entered(area: Area2D):
	"""When we hit a hurtbox"""
	print("Hitbox detected collision with: ", area.name, " - Active: ", _is_active)
	
	if not _is_active:
		print("Hitbox not active, ignoring collision")
		return
		
	# Only hit hurtboxes
	if not area.has_method("take_hit"):
		print("Area ", area.name, " doesn't have take_hit method")
		return
		
	# Don't hit the same target twice
	var target_owner = area.get_parent()
	if target_owner in _targets_hit:
		print("Already hit target: ", target_owner.name)
		return
		
	print("Hitbox hitting: ", area.name)
	
	# Deal damage through the hurtbox
	area.take_hit(damage, knockback_force, global_position)
	
	# Track this target
	_targets_hit.append(target_owner)
	
	# Note: Don't auto-deactivate - let the attack state control activation/deactivation
