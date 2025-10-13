## BREAKABLE PLANT SYSTEM
##
## Handles destructible plants that can be broken by player attacks.
## When hit, the plant becomes invisible and non-collidable, simulating destruction.

extends Node

# Simple settings for testing
@export var health: int = 1
var is_broken: bool = false

# Node references  
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $HitBox  
@onready var static_body: StaticBody2D = $StaticBody2D

func _ready():
	# Set up initial plant state and collision detection
	if hitbox:
		# Connect signal to detect when player attacks hit the plant
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		
		# Enable collision monitoring so the plant can detect attack hitboxes
		hitbox.monitoring = true
		hitbox.monitorable = true

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
	
	# Hide the plant sprite
	if sprite:
		sprite.visible = false
		
	# Disable hitbox collision detection so it can't be hit again
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
		
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
	
	# Make the plant visible again
	if sprite:
		sprite.visible = true
		
	# Re-enable hitbox collision detection so it can be hit again
	if hitbox:
		hitbox.monitoring = true
		hitbox.monitorable = true
		
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
