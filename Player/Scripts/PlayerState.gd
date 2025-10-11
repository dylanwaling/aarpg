# Base class for all player states (Idle, Walk, Dash, etc.)
# Each state node extends this to share the same function structure.

class_name PlayerState
extends Node

# Reference to the Player node (set automatically in Player.gd)
var player

# Called when entering this state (from a previous state)
func enter(from): pass

# Called when exiting this state (to another state)
func exit(to): pass

# Used if you want to handle raw InputEvents (optional)
func handle_input(event): pass

# Called every frame for logic and animations
func update(delta): pass

# Called during physics updates (for movement or collisions)
func physics_update(delta): pass
