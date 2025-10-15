## PLAYER STATE BASE CLASS - The Template for All Player Behaviors
##
## This is like a blueprint that all player states follow. It doesn't do anything by itself,
## but it defines what functions every state should have.
##
## Think of it like this: every state needs to know what to do when it starts (enter),
## what to do every frame (update), how to handle input (handle_input), etc.
##
## By having this base class, we ensure every state has the same "interface" so the
## Player controller can treat them all the same way - it just calls enter(), update(),
## handle_input() etc. without caring which specific state it's talking to.
##
## Each actual state (IdleState, WalkState, etc.) extends this and fills in the details.

class_name PlayerState
extends Node

# ─────────── PLAYER REFERENCE ───────────
var player  # Reference to the Player that owns this state (set automatically)

# ─────────── STATE INTERFACE FUNCTIONS ───────────
# Called when this state becomes active (like switching from idle to walk)
func enter(_from): pass

# Called when leaving this state to go to another one
func exit(_to): pass

# Called when the player presses keys or buttons
func handle_input(_event): pass

# Called every frame while this state is active (for logic and animations)
func update(_delta): pass

# Called during physics updates (for movement and collision)
func physics_update(_delta): pass

# ─────────── SHARED UTILITY FUNCTIONS ───────────
func handle_common_actions(event):
	"""Handle attack and dash inputs that work from any state"""
	if event.is_action_pressed("attack"):
		player.change_state(player.attack_state)
		return true
	elif event.is_action_pressed("dash") and player.dash_state.can_dash():
		player.change_state(player.dash_state)
		return true
	return false