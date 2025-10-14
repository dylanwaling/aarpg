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

func deactivate():
	"""Deactivate hitbox"""
	_is_active = false
	monitoring = false

func _on_area_entered(area: Area2D):
	"""When we hit a hurtbox"""
	if not _is_active:
		return
		
	# Only hit hurtboxes
	if not area.has_method("take_hit"):
		return
		
	# Don't hit the same target twice
	var target_owner = area.get_parent()
	if target_owner in _targets_hit:
		return
	
	# Deal damage through the hurtbox
	area.take_hit(damage, knockback_force, global_position)
	
	# Track this target
	_targets_hit.append(target_owner)
	
	# Note: Don't auto-deactivate - let the attack state control activation/deactivation
