## BREAKABLE PLANT SYSTEM
##
## Handles destructible plants that can be broken by player attacks.
## When hit, the plant becomes invisible and non-collidable, simulating destruction.

extends Node

# ── PLANT STATS ──
var is_broken: bool = false

# Node references  
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $HitBox  
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var health_component: Node2D = $Health     # The health management component

func _ready():
	# Configure using modular system
	if hitbox and hitbox.has_method("setup_plant_hurtbox"):
		hitbox.setup_plant_hurtbox()  # Set up collision for plant
	
	# Set up health component for plants
	if health_component:
		health_component.auto_connect_to_parent = false  # Disable auto-connect to prevent duplicates
		health_component.setup_plant_health(1, false)  # 1 HP, no display
		health_component.died.connect(_on_health_died)

func _on_hitbox_area_entered(area):
	"""Called when player attack hitbox enters our detection area"""
	# Check if the area is an attack hitbox with damage capability
	if area.has_method("activate_hitbox") and area.get("damage") != null:
		# This is a valid attack hitbox - break the plant
		break_plant()

func break_plant():
	"""Handle the plant breaking when hit by player attacks"""
	if is_broken:
		return
		
	is_broken = true
	
	# Update health component (deal enough damage to kill it)
	if health_component and health_component.is_alive():
		health_component.take_damage(health_component.get_health())
	
	# Hide the plant sprite
	if sprite:
		sprite.visible = false
		
	# Disable hitbox collision detection so it can't be hit again
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
		
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
		
	# Re-enable hitbox collision detection so it can be hit again
	if hitbox:
		hitbox.set_deferred("monitoring", true)
		hitbox.set_deferred("monitorable", true)
		
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
	# Additional death effects can go here
	# The visual hiding is already handled in break_plant()
	pass
