# Base class for all player states (idle, walk, dash, attack, etc.)
# States are Nodes that get a back-reference to the Player at runtime.
# We keep this file free of type-hints to avoid load-order/cyclic import issues.

class_name PlayerState
extends Node

# Set by Player.gd in _ready(): each state gets a ref to the Player node.
var player

# Called once when the state becomes active.
func enter(from): pass

# Called once when the state is about to be replaced by another state.
func exit(to): pass

# Input hook (only used if your state wants raw InputEvents).
func handle_input(event): pass

# Per-frame update (game-time). Use for logic and animation decisions.
func update(delta): pass

# Fixed-timestep update (physics-time). Use for movement/physics.
func physics_update(delta): pass
