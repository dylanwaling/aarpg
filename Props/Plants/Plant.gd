## SIMPLE BREAKABLE PLANT - Testing Version
##
## Simplified to just get plant breaking working first

extends Node

# Simple settings for testing
@export var health: int = 1
var is_broken: bool = false

# Node references  
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $HitBox  
@onready var static_body: StaticBody2D = $StaticBody2D

func _ready():
	print("=== PLANT SETUP DEBUG ===")
	
	# Connect the hitbox to detect player attacks
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		
		# CRITICAL FIX: Enable monitoring so it can detect collisions!
		hitbox.monitoring = true
		hitbox.monitorable = true
		
		print("Plant HitBox - Layer: ", hitbox.collision_layer, " (should be 512 for layer 10), Mask: ", hitbox.collision_mask, " (should be 1 for layer 1)")
		print("Plant monitoring: ", hitbox.monitoring, " monitorable: ", hitbox.monitorable, " - FIXED!")
	else:
		print("ERROR: No HitBox found!")
		
	if static_body:
		print("Plant StaticBody2D - Layer: ", static_body.collision_layer, " (should be 2), Mask: ", static_body.collision_mask, " (should be 0)")
	else:
		print("ERROR: No StaticBody2D found!")
		
	print("=== END PLANT SETUP ===")

# Debug method to test if plant can break manually - REMOVED since spacebar is dash

func _on_hitbox_area_entered(area):
	"""Called when player attack hitbox enters our detection area"""
	print(">>> Plant hit by area: ", area.name)
	print("    Area collision_layer: ", area.collision_layer)
	
	# Check if it's from the player (layer 1 = bit flag value 1)
	if area.collision_layer == 1:  # Player layer bit flag
		print("    PLAYER ATTACK DETECTED!")
		break_plant()
	else:
		print("    Not a player attack, layer bit flag is: ", area.collision_layer)
		print("    Checking if this area has damage/hitbox methods...")
		
		# Alternative check - look for hitbox properties
		if area.has_method("activate_hitbox") or area.get("damage") != null:
			print("    Found hitbox with damage - breaking plant anyway!")
			break_plant()
		else:
			print("    Not a damage source, ignoring")

func break_plant():
	"""Simple plant breaking for testing"""
	if is_broken:
		return
		
	print("*** PLANT BREAKING ***")
	is_broken = true
	
	# Hide the visual sprite
	if sprite:
		sprite.visible = false
		
	# PROPERLY disable collision detection  
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
		print("HitBox collision disabled")
		
	# PROPERLY disable static body collision (use bit flag method)
	if static_body:
		print("StaticBody2D BEFORE disable - Layer: ", static_body.collision_layer)
		static_body.set_collision_layer_value(2, false)  # Disable layer 2
		print("StaticBody2D AFTER disable - Layer: ", static_body.collision_layer)
		
		# Alternative method - completely disable collision
		var collision_shape = static_body.get_node("CollisionShape2D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
			print("StaticBody2D CollisionShape2D disabled")
		
	# Simple respawn after 3 seconds
	await get_tree().create_timer(3.0).timeout
	respawn_plant()

func respawn_plant():
	"""Bring the plant back for testing"""
	print("*** PLANT RESPAWNING ***")
	is_broken = false
	
	# Restore visual
	if sprite:
		sprite.visible = true
		
	# PROPERLY restore hitbox collision detection
	if hitbox:
		hitbox.monitoring = true
		hitbox.monitorable = true
		print("HitBox collision restored - monitoring: ", hitbox.monitoring, " monitorable: ", hitbox.monitorable)
		
	# PROPERLY restore static body collision (use bit flag method)
	if static_body:
		print("StaticBody2D BEFORE restore - Layer: ", static_body.collision_layer)
		static_body.set_collision_layer_value(2, true)  # Enable layer 2 (Environment)
		print("StaticBody2D AFTER restore - Layer: ", static_body.collision_layer)
		
		# Re-enable collision shape
		var collision_shape = static_body.get_node("CollisionShape2D")
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
			print("StaticBody2D CollisionShape2D restored")
		
	print("*** PLANT FULLY RESTORED ***")

# Keep the old method name in case hitbox system calls it
func take_damage(_amount: int, _hit_position: Vector2 = Vector2.ZERO):
	"""Backup method for damage - calls break_plant"""
	print("Plant take_damage called! Breaking plant...")
	break_plant()
