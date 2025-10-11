# Handles player movement, direction, facing, and switching between states.
# Think of this as the "brain" that delegates behavior to states like Idle or Walk.

class_name Player
extends CharacterBody2D

# ─────────── CONFIG ───────────
@export var move_speed: float = 100.0  # How fast the player moves (pixels/sec)

# ─────────── RUNTIME ───────────
var direction: Vector2 = Vector2.ZERO  # Current input direction
var facing: Vector2   = Vector2.DOWN   # Used for determining animation direction
var current           = null           # Current active state node (Idle/Walk)

# ─────────── NODE REFERENCES ───────────
@onready var sprite: Sprite2D        = $Sprite2D
@onready var anim: AnimationPlayer   = $AnimationPlayer
@onready var IdleState               = $States/IdleState
@onready var WalkState               = $States/WalkState

# ─────────── INITIALIZATION ───────────
func _ready():
	# Give all states a back-reference to this player
	for s in $States.get_children():
		s.player = self

	# Start in Idle mode
	change_state(IdleState)

# ─────────── FRAME UPDATES ───────────
func _process(dt):
	read_direction()   # Read keyboard input
	update_facing()    # Decide which way player is facing
	if current:
		current.update(dt)

func _physics_process(dt):
	if current:
		current.physics_update(dt)
	move_and_slide()   # Applies current velocity to movement

# ─────────── INPUT EVENTS (optional) ───────────
func _unhandled_input(event):
	if current:
		current.handle_input(event)

# ─────────── STATE MACHINE ───────────
func change_state(next):
	# Avoid switching to same or null state
	if next == null or next == current:
		return

	var prev = current
	if current:
		current.exit(next)
	current = next
	current.enter(prev)

# ─────────── INPUT & MOVEMENT HELPERS ───────────
func read_direction():
	# Combine WASD or arrow key input into a normalized vector
	direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down")  - Input.get_action_strength("up")
	)
	if direction != Vector2.ZERO:
		direction = direction.normalized()

func update_facing():
	# No input = keep last facing direction
	if direction == Vector2.ZERO:
		return

	# Prefer horizontal movement when moving diagonally
	if direction.x != 0.0:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP

	# Flip sprite for left-facing movement
	sprite.flip_h = (facing == Vector2.LEFT)

# ─────────── ANIMATION HELPERS ───────────
func play_anim(state_name: String):
	# Builds animation name like "walk_side" or "idle_down"
	var dir_name := "side"
	if facing == Vector2.UP:
		dir_name = "up"
	elif facing == Vector2.DOWN:
		dir_name = "down"

	var anim_name := "%s_%s" % [state_name, dir_name]

	# Only change animation if it’s different (avoids restarts)
	if !anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)
