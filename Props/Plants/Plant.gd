## BREAKABLE PLANT SYSTEM
##
## Handles destructible plants that can be broken by player attacks.
## When hit, the plant becomes invisible and non-collidable, simulating destruction.

extends Node

# ─────────── PLANT SETTINGS YOU CAN ADJUST ───────────
@export var plant_health: int = 30              # How much damage needed to break plant
@export var respawn_time: float = 3.0           # Seconds until plant grows back
@export var show_health_display: bool = true    # Whether to show health numbers above plant
@export var break_instantly: bool = false       # If true, any damage breaks plant regardless of health

# ── PLANT STATS ──
var is_broken: bool = false

# Node references  
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox  # The component that receives damage
@onready var static_body: StaticBody2D = $StaticBody2D  # The collision body

func _ready():
	# Add to environment group (prevents knockback attempts)
	add_to_group("environment")
	
	# Configure using new professional system
	if hurtbox and hurtbox.has_method("setup_environment_hurtbox"):
		hurtbox.setup_environment_hurtbox()  # Set up collision for plant
	
	# Set up health component for plants using configurable settings
	var health_component = get_node("Health")
	if health_component:
		health_component.setup_plant_health(plant_health, show_health_display)
		# Health component will auto-connect to _on_health_died method

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
		
	# Respawn the plant after configured time
	await get_tree().create_timer(respawn_time).timeout
	respawn_plant()

func respawn_plant():
	"""Restore the plant to its original state after being broken"""
	is_broken = false
	
	# Reset health component
	var health_component = get_node("Health")
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
func take_damage(amount: int, _hit_position: Vector2 = Vector2.ZERO):
	"""Alternative method for damage - behavior depends on break_instantly setting"""
	if break_instantly:
		# Instant break mode - any damage destroys plant
		break_plant()
	else:
		# Normal mode - use health component for proper damage tracking
		var health_component = get_node("Health")
		if health_component:
			health_component.take_damage(amount)

func _on_health_died():
	"""Called when health component reaches 0"""
	# Break the plant when health reaches 0
	break_plant()
