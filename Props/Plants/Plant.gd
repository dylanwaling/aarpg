## BREAKABLE PLANT SYSTEM
##
## Handles destructible plants that can be broken by player attacks.
## When hit, the plant becomes invisible and non-collidable, simulating destruction.

extends Node

# ── PLANT STATS ──
var is_broken: bool = false

# Node references  
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox  # Changed from hitbox to hurtbox
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var health_component: Node2D = $Health     # The health management component

func _ready():
	# Configure using new professional system
	if hurtbox and hurtbox.has_method("setup_environment_hurtbox"):
		hurtbox.setup_environment_hurtbox()  # Set up collision for plant
	
	# Set up health component for plants - 30 HP for 2 hits (15 damage × 2 = 30)
	if health_component:
		health_component.setup_plant_health(30, true)  # 30 HP, show display
		# Connect to death signal (it's called 'died', not 'entity_died')
		health_component.died.connect(_on_health_died)

func break_plant():
	"""Handle the plant breaking when health reaches 0"""
	if is_broken:
		return
		
	is_broken = true
	
	# Hide the plant sprite
	if sprite:
		sprite.visible = false
		
	# Disable hurtbox collision detection so it can't be hit again
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		
	# Disable static body collision so player can walk through
	if static_body:
		# Remove from environment collision layer
		static_body.set_collision_layer_value(2, false)
		
		# Also disable the collision shape completely
		var collision_shape = static_body.get_node("CollisionShape2D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
	# Respawn the plant after 3 seconds
	await get_tree().create_timer(3.0).timeout
	respawn_plant()

func respawn_plant():
	"""Restore the plant to its original state after being broken"""
	is_broken = false
	
	# Reset health component
	if health_component:
		health_component.reset_health()
	
	# Make the plant visible again
	if sprite:
		sprite.visible = true
		
	# Re-enable hurtbox collision detection so it can be hit again
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
		
	# Re-enable static body collision so it blocks player movement
	if static_body:
		# Add back to environment collision layer
		static_body.set_collision_layer_value(2, true)
		
		# Re-enable the collision shape
		var collision_shape = static_body.get_node("CollisionShape2D")
		if collision_shape:
			collision_shape.set_deferred("disabled", false)

# Alternative damage method for compatibility with other damage systems
func take_damage(_amount: int, _hit_position: Vector2 = Vector2.ZERO):
	"""Alternative method for damage - breaks the plant regardless of damage amount"""
	break_plant()

func _on_health_died():
	"""Called when health component reaches 0"""
	# Break the plant when health reaches 0
	break_plant()
