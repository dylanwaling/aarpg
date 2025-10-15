## ENEMY STATE BASE CLASS - The Template for All Enemy Behaviors
##
## This is like a blueprint that all enemy states follow. It doesn't do anything by itself,
## but it defines what functions every enemy state should have.
##
## Think of it like this: every state needs to know what to do when it starts (enter),
## what to do every frame (update), what to do during physics (physics_update), etc.
##
## By having this base class, we ensure every state has the same "interface" so the
## Enemy controller can treat them all the same way - it just calls enter(), update(),
## physics_update() etc. without caring which specific state it's talking to.
##
## Each actual state (EnemyIdleState, EnemyChaseState, etc.) extends this and fills in the details.

class_name EnemyState
extends Node

# ─────────── ENEMY REFERENCE ───────────
var enemy  # Reference to the Enemy that owns this state (set automatically)

# ─────────── STATE INTERFACE FUNCTIONS ───────────
# Called when this state becomes active (like switching from idle to chase)
func enter(_from): pass

# Called when leaving this state to go to another one  
func exit(_to): pass

# Called every frame while this state is active (for AI decisions and animations)
func update(_delta): pass

# Called during physics updates (for movement and collision detection)
func physics_update(_delta): pass
