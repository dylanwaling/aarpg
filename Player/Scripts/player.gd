# Main Player controller:
# - Reads input -> direction (normalized)
# - Computes facing (prefers horizontal when diagonal)
# - Delegates logic to the current state (Idle/Walk, etc.)
# - Owns animation helper and state switching
#
# Scene requirements (child node names must match):
#   Player (CharacterBody2D)
#   ├─ Sprite2D
#   ├─ AnimationPlayer
#   └─ States
#      ├─ IdleState   (IdleState.gd attached)
#      └─ WalkState   (WalkState.gd attached)

class_name Player
extends CharacterBody2D

# ───────────────────────────────── CONFIG
@export var move_speed: float = 100.0  # movement speed in pixels/second

# ───────────────────────────────── RUNTIME STATE
var direction: Vector2 = Vector2.ZERO  # current input direction (normalized)
var facing:   Vector2 = Vector2.DOWN   # last facing dir used to pick animations
var current               = null       # current state node (IdleState/WalkState)

# ───────────────────────────────── NODE REFERENCES (null-safe lookups)
@onready var sprite: Sprite2D        = get_node_or_null("Sprite2D")
@onready var anim: AnimationPlayer   = get_node_or_null("AnimationPlayer")
@onready var states_root: Node       = get_node_or_null("States")

# Concrete state nodes in the scene tree:
@onready var IdleState               = get_node_or_null("States/IdleState")
@onready var WalkState               = get_node_or_null("States/WalkState")

func _ready() -> void:
	# Hard assertions provide clear messages if the scene is miswired.
	assert(sprite      != null, "Player: Missing child node 'Sprite2D'")
	assert(anim        != null, "Player: Missing child node 'AnimationPlayer'")
	assert(states_root != null, "Player: Missing child node 'States'")
	assert(IdleState   != null, "Player: Missing node 'States/IdleState'")
	assert(WalkState   != null, "Player: Missing node 'States/WalkState'")

	# Give each state a back-reference to this Player (so states can call player.*)
	for s in states_root.get_children():
		s.player = self

	# Start in Idle
	change_state(IdleState)

func _process(delta: float) -> void:
	read_direction()   # 1) Poll input to a normalized direction vector
	update_facing()    # 2) Derive animation-facing from that direction
	if current:
		current.update(delta)  # 3) Let the active state do its per-frame logic

func _physics_process(delta: float) -> void:
	if current:
		current.physics_update(delta)  # State-specific physics (optional)
	move_and_slide()                   # Apply velocity each physics frame

func _unhandled_input(event: InputEvent) -> void:
	# If you later have states that need raw InputEvent, they'll use this.
	if current:
		current.handle_input(event)

# ───────────────────────────────── STATE MACHINE CORE

# Switch to another state node (e.g., IdleState -> WalkState).
func change_state(next) -> void:
	if next == null or next == current:
		return
	var prev = current
	if current:
		current.exit(next)  # let old state clean up
	current = next
	current.enter(prev)     # let new state initialize

# ───────────────────────────────── INPUT / FACING / ANIMATION HELPERS

# Polls Input Map actions (right/left/down/up) and builds a normalized vector.
# Normalization keeps diagonal speed the same as horizontal/vertical.
func read_direction() -> void:
	direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down")  - Input.get_action_strength("up")
	)
	if direction != Vector2.ZERO:
		direction = direction.normalized()

# Computes facing used to choose animation direction.
# Rule: ANY horizontal input forces side-facing (so diagonals keep "side"),
# otherwise use vertical facing. We also flip the sprite for left/right.
func update_facing() -> void:
	if direction == Vector2.ZERO:
		return

	# Prefer horizontal when there is any X input.
	if direction.x != 0.0:
		facing = (Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT)
	else:
		facing = (Vector2.DOWN  if direction.y > 0.0 else Vector2.UP)

	if sprite:
		sprite.flip_h = (facing == Vector2.LEFT)

# Plays "<state>_<dir>" (e.g., "walk_side", "idle_up").
# Only restarts the animation if the name actually changes (cheap).
func play_anim(state_name: String) -> void:
	if anim == null:
		return

	var dir_name := "side"
	if facing == Vector2.UP:
		dir_name = "up"
	elif facing == Vector2.DOWN:
		dir_name = "down"

	var anim_name := "%s_%s" % [state_name, dir_name]
	if not anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)
