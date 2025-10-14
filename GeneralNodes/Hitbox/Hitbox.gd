## PROFESSIONAL HITBOX SYSTEM - Deals Damage via Clean Interface
##
## Core Responsibilities:
## • Detects collisions with HurtBox components when activated
## • Calls hurtbox.take_hit(damage, knockback, source_pos) for each target
## • Prevents hitting the same target multiple times per activation
## • Completely controlled via activate()/deactivate() methods
## • Collision layers set dynamically by AttackState or configured in scene
##
## Usage: Set damage/knockback_force properties, then call activate() to start dealing damage.
## Automatically deactivates when appropriate or call deactivate() manually.

extends Area2D
class_name Hitbox

# ─────────── DAMAGE CONFIGURATION ───────────
@export var damage: int = 10                    # Damage dealt to each target hit
@export var knockback_force: float = 50.0       # Knockback strength applied to targets

# ─────────── INTERNAL STATE (DO NOT MODIFY) ───────────
var _is_active: bool = false                    # Whether hitbox is currently dealing damage
var _targets_hit: Array[Node] = []              # Prevents hitting same target multiple times

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
