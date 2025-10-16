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
	set_deferred("monitorable", true)  # Allow it to be detected/visible for debugging
	
	# Connect to collision detection system
	area_entered.connect(_on_area_entered)

# ─────────── HITBOX CONTROL INTERFACE ───────────
func activate():
	"""Turn on damage dealing - called by AttackState during wind-up completion"""
	# ─────────── DAMAGE SYSTEM ACTIVATION ───────────
	_is_active = true                # Allow this hitbox to deal damage
	_targets_hit.clear()             # Clear previous hit list (fresh attack)
	monitoring = true                # Start detecting collisions with other entities
	# Called by: Player AttackState._create_damage_hitbox(), Enemy AttackState._activate_attack_hitbox()

func deactivate():
	"""Turn off damage dealing - called by AttackState when attack ends or exits"""
	# ─────────── DAMAGE SYSTEM DEACTIVATION ───────────
	_is_active = false              # Stop dealing damage
	monitoring = false              # Stop detecting collisions (performance)
	# Called by: Player AttackState._cleanup_hitbox(), Enemy AttackState._deactivate_attack_hitbox()"

# ─────────── COLLISION DETECTION AND DAMAGE DEALING ───────────
func _on_area_entered(area: Area2D):
	"""Handle collision with another Area2D - check if it's a valid damage target"""
	# ─────────── HITBOX ACTIVATION CHECK ───────────
	# Only deal damage when attack is actually active (not during wind-up/cooldown)
	if not _is_active:
		return
		
	# ─────────── TARGET TYPE VALIDATION ───────────
	# Only damage HurtBox components (ignore walls, triggers, other Area2D nodes)
	if not area.has_method("take_hit"):
		return
	
	# ─────────── SELF-DAMAGE PREVENTION ───────────
	# Don't let entities damage themselves (HitBox and HurtBox on same parent)
	if area.get_parent() == get_parent():
		return
		
	# ─────────── DUPLICATE HIT PREVENTION ───────────
	# Get the entity that owns this HurtBox (Player, Enemy, Plant, etc.)
	var target_owner = area.get_parent()
	# Don't hit the same entity multiple times in one attack
	if target_owner in _targets_hit:
		return  # Already damaged this target
	
	# ─────────── KNOCKBACK POSITION CALCULATION ───────────
	# Get attacker's center position for accurate knockback direction
	# Use parent (Player/Enemy) position, not hitbox position for better physics
	var source_pos = get_parent().global_position if get_parent() else global_position
	
	# ─────────── DAMAGE DELIVERY ───────────
	# Send damage, knockback force, and attacker position to victim's HurtBox
	area.take_hit(damage, knockback_force, source_pos)
	
	# ─────────── HIT TRACKING ───────────
	# Remember we hit this entity to prevent multiple hits from same attack
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
