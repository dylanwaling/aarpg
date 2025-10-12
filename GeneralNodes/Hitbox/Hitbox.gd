## HITBOX SYSTEM - Handles Damage and Interactions
##
## This system manages all collision-based interactions in your AARPG:
## - Player attacks hitting enemies
## - Player interactions with breakable objects (bushes, crates, etc.)
## - Enemy attacks hitting the player
## - Environmental interactions
##
## The system uses collision layers to determine what can hit what:
## - Layer 1: Player
## - Layer 9: Enemies
## - Additional layers can be added for breakables, NPCs, etc.

extends Area2D

# ─────────── HITBOX CONFIGURATION ───────────
@export var damage: int = 10                    # How much damage this hitbox deals
@export var knockback_force: float = 100.0      # How hard targets get knocked back
@export var hitbox_owner_layer: int = 1         # Which layer owns this hitbox (1=player, 9=enemy)
@export var can_hit_layers: Array[int] = [9]    # Which layers this hitbox can affect
@export var hit_duration: float = 0.1           # How long the hitbox stays active
@export var destroy_on_hit: bool = false        # If true, hitbox disappears after first hit

# ─────────── INTERACTION TYPES ───────────
enum HitType {
	DAMAGE,        # Deals damage to health
	INTERACT,      # Triggers interactions (breaking bushes, opening chests)
	KNOCKBACK,     # Just pushes targets around
	COMBO          # All of the above
}
@export var hit_type: HitType = HitType.DAMAGE

# ─────────── INTERNAL TRACKING ───────────
var _active: bool = false                       # Whether the hitbox is currently checking for hits
var _hit_targets: Array = []                   # Prevents hitting the same target multiple times
var _time_left: float = 0.0                   # Countdown timer for hitbox duration

# ─────────── SETUP AND ACTIVATION ───────────
func _ready():
	# Connect the collision detection signal
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Start inactive - must be manually activated
	_active = false
	monitoring = false
	
	# Make sure we have a CollisionShape2D child
	if not get_child(0) is CollisionShape2D:
		push_warning("Hitbox needs a CollisionShape2D as its first child!")

func activate_hitbox():
	"""Start checking for collisions and dealing damage/interactions"""
	_active = true
	monitoring = true
	_hit_targets.clear()  # Reset hit list for fresh activation
	_time_left = hit_duration
	
	# Auto-deactivate after duration
	if hit_duration > 0:
		await get_tree().create_timer(hit_duration).timeout
		deactivate_hitbox()

func deactivate_hitbox():
	"""Stop checking for collisions"""
	_active = false
	monitoring = false

# ─────────── COLLISION DETECTION ───────────
func _on_body_entered(body):
	"""Called when a CharacterBody2D enters the hitbox"""
	if not _active:
		return
		
	# Check if this body is on a layer we can hit
	var body_layer = _get_body_collision_layer(body)
	if not body_layer in can_hit_layers:
		return
		
	# Don't hit the same target twice
	if body in _hit_targets:
		return
		
	# Process the hit
	_process_hit(body)

func _on_area_entered(area):
	"""Called when an Area2D (like another hitbox or hurtbox) enters"""
	if not _active:
		return
		
	# Check if this area is on a layer we can interact with
	var area_layer = _get_area_collision_layer(area)
	if not area_layer in can_hit_layers:
		return
		
	# Don't hit the same target twice
	if area in _hit_targets:
		return
		
	# Process the hit
	_process_hit(area)

# ─────────── HIT PROCESSING ───────────
func _process_hit(target):
	"""Handle what happens when we hit something"""
	# Add to hit list to prevent double-hits
	_hit_targets.append(target)
	
	# Determine what kind of hit to apply
	match hit_type:
		HitType.DAMAGE:
			_apply_damage(target)
		HitType.INTERACT:
			_apply_interaction(target)
		HitType.KNOCKBACK:
			_apply_knockback(target)
		HitType.COMBO:
			_apply_damage(target)
			_apply_interaction(target)
			_apply_knockback(target)
	
	# Destroy hitbox if configured to do so
	if destroy_on_hit:
		deactivate_hitbox()

func _apply_damage(target):
	"""Deal damage to the target if it can take damage"""
	# Look for common health/damage methods
	if target.has_method("take_damage"):
		target.take_damage(damage, global_position)
	elif target.has_method("damage"):
		target.damage(damage)
	elif target.has_method("hurt"):
		target.hurt(damage)
	else:
		print("Hit target but it doesn't have a damage method: ", target.name)

func _apply_interaction(target):
	"""Trigger interactions like breaking bushes, opening chests, etc."""
	if target.has_method("interact"):
		target.interact()
	elif target.has_method("break"):
		target.break()
	elif target.has_method("activate"):
		target.activate()
	elif target.has_method("destroy"):
		target.destroy()

func _apply_knockback(target):
	"""Push the target away from the hitbox"""
	if knockback_force <= 0:
		return
		
	# Calculate knockback direction (from hitbox to target)
	var knockback_direction = (target.global_position - global_position).normalized()
	
	# Apply knockback if target supports it
	if target.has_method("apply_knockback"):
		target.apply_knockback(knockback_direction * knockback_force)
	elif target.has_method("push"):
		target.push(knockback_direction * knockback_force)
	elif target is CharacterBody2D:
		# Direct velocity modification for CharacterBody2D
		target.velocity += knockback_direction * knockback_force

# ─────────── HELPER METHODS ───────────
func _get_body_collision_layer(body) -> int:
	"""Get which collision layer a CharacterBody2D is on"""
	var layers = body.collision_layer
	# Find the first set bit (layer number)
	for i in range(32):
		if layers & (1 << i):
			return i + 1  # Godot layers are 1-indexed in the editor
	return 0

func _get_area_collision_layer(area) -> int:
	"""Get which collision layer an Area2D is on"""
	var layers = area.collision_layer
	# Find the first set bit (layer number)
	for i in range(32):
		if layers & (1 << i):
			return i + 1  # Godot layers are 1-indexed in the editor
	return 0

# ─────────── EASY SETUP METHODS ───────────
func setup_player_attack(attack_damage: int = 10, knockback: float = 50.0):
	"""Quick setup for player attack hitboxes"""
	damage = attack_damage
	knockback_force = knockback
	hitbox_owner_layer = 1
	can_hit_layers = [9]  # Hit enemies
	hit_type = HitType.COMBO

func setup_enemy_attack(attack_damage: int = 5, knockback: float = 75.0):
	"""Quick setup for enemy attack hitboxes"""
	damage = attack_damage
	knockback_force = knockback
	hitbox_owner_layer = 9
	can_hit_layers = [1]  # Hit player
	hit_type = HitType.COMBO

func setup_environmental_interaction():
	"""Quick setup for breaking bushes, opening chests, etc."""
	damage = 0
	knockback_force = 0
	hitbox_owner_layer = 1
	can_hit_layers = [10]  # You can add layer 10 for breakables
	hit_type = HitType.INTERACT
