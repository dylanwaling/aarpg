## DEBUG COLLISION SCRIPT
## Add this as an autoload or attach to a node to debug collision settings

extends Node

func _ready():
	print("=== COLLISION DEBUG INFO ===")
	
	# Find and check player collision settings
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("PLAYER:")
		print("  Layer: ", player.collision_layer, " (binary: ", String.num_uint64(player.collision_layer, 2), ")")
		print("  Mask:  ", player.collision_mask, " (binary: ", String.num_uint64(player.collision_mask, 2), ")")
	
	# Find and check enemy collision settings
	var enemies = get_tree().get_nodes_in_group("enemy") 
	for enemy in enemies:
		print("ENEMY (", enemy.name, "):")
		print("  Layer: ", enemy.collision_layer, " (binary: ", String.num_uint64(enemy.collision_layer, 2), ")")
		print("  Mask:  ", enemy.collision_mask, " (binary: ", String.num_uint64(enemy.collision_mask, 2), ")")
	
	print("=== EXPECTED VALUES ===")
	print("Player should have: Layer=1 (binary: 1), Mask=2 (binary: 10)")
	print("Enemy should have:  Layer=1024 (binary: 10000000000), Mask=2 (binary: 10)")
	print("Environment should have: Layer=2 (binary: 10)")