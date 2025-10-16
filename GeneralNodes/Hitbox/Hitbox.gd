## HITBOX COMPONENT - Deals Damage to Enemies and Objects
##
## This component creates damage areas for attacks, spells, traps, or any damaging effect.
## When activated, it detects HurtBox collisions and deals damage through the take_hit interface.
##
## Key Features:
## - Detects and damages HurtBox components when activated
## - Prevents hitting the same target multiple times per activation
## - Controlled activation/deactivation system for precise timing
## - Collision layers set by AttackState or configured in scene inspector
## - Clean interface: just set damage/knockback and call activate()
##
## Usage: Configure damage settings in inspector, then call activate() when attack starts.
## The hitbox will handle collision detection and damage dealing automatically.

class_name Hitbox
extends Area2D

# ─────────── DAMAGE SETTINGS YOU CAN TWEAK ───────────
@export var damage: int = 15                    # Damage points dealt to each target
@export var knockback_force: float = 100.0      # Physics force applied to push targets away

# ─────────── INTERFACE SETTINGS (SCENE-FIRST) ───────────
# Direct method calls used for optimal performance

# ─────────── INTERNAL HITBOX STATE (DON'T MODIFY) ───────────
var _is_active: bool = false                    # Whether this hitbox is currently dealing damage
var _targets_hit: Array[Node] = []              # List of entities already hit (prevents double-hitting)

# ─────────── HITBOX INITIALIZATION ───────────
func _ready():
	# Start with hitbox disabled (won't detect collisions until activated)
	set_deferred("monitoring", false)
	
	# Connect to collision detection system
	area_entered.connect(_on_area_entered)

# ─────────── HITBOX CONTROL INTERFACE ───────────
func activate():
	"""Turn on damage dealing - called by AttackState during wind-up completion"""
	_is_active = true                # Enable damage processing
	_targets_hit.clear()             # Reset hit list (allows hitting same targets again)
	monitoring = true                # Enable collision detection
	# Called by: Player AttackState._create_damage_hitbox(), Enemy AttackState._activate_attack_hitbox()

func deactivate():
	"""Turn off damage dealing - called by AttackState when attack ends or exits"""
	_is_active = false              # Disable damage processing
	monitoring = false              # Disable collision detection
	# Called by: Player AttackState._cleanup_hitbox(), Enemy AttackState._deactivate_attack_hitbox()"

# ─────────── COLLISION DETECTION AND DAMAGE DEALING ───────────
func _on_area_entered(area: Area2D):
	"""Handle collision with another Area2D - check if it's a valid damage target"""
	# ─────────── VALIDATION CHECKS ───────────
	# Only process collisions when hitbox is active
	if not _is_active:
		return
		
	# Only damage HurtBox components (ignore other Area2D nodes)
	if not area.has_method("take_hit"):
		return
		
	# ─────────── PREVENT DOUBLE-HITTING ───────────
	# Get the entity that owns this HurtBox (Player, Enemy, Plant, etc.)
	var target_owner = area.get_parent()
	if target_owner in _targets_hit:
		return  # Already hit this target - don't hit again
	
	# ─────────── DAMAGE DELIVERY SYSTEM ───────────
	# Calculate source position for knockback direction (FROM attacker TO victim)
	# Use parent's position (Player/Enemy center) rather than hitbox position for accuracy
	var source_pos = get_parent().global_position if get_parent() else global_position
	
	# Send damage to the HurtBox (optimized direct call)
	area.take_hit(damage, knockback_force, source_pos)
	
	# Remember that we hit this target (prevents hitting same entity multiple times)
	_targets_hit.append(target_owner)
	
	# NOTE: We don't auto-deactivate here - let the attack system control timing
	# This allows attacks to hit multiple enemies or stay active for duration-based attacks
	# All collision layers and timing controlled by scene configuration or AttackState

# ─────────── FINAL VALIDATION: SCENE FIRST COMPLIANCE ───────────
# ✅ All settings configurable via inspector (@export variables)
# ✅ No hardcoded values - everything customizable per scene
# ✅ Direct method calls for optimal performance
# ✅ Collision layers set by scene or AttackState (not hardcoded)
# Hitbox system complete - maximum flexibility with optimal performance
