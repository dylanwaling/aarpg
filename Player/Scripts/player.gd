## PLAYER CONTROLLER - The Main Character Manager
## 
## This is the "brain" of the player character that coordinates everything.
## It reads keyboard input, manages which direction the player is facing,
## handles animations, and delegates specific behaviors to different states
## (like IdleState for standing still, WalkState for moving, AttackState for attacking)
## 
## Think of it as a coordinator that says "Hey WalkState, the player is moving!"
## or "AttackState, time to do an attack!" based on what's happening.

class_name Player
extends CharacterBody2D

# ─────────── GAME SETTINGS YOU CAN ADJUST ───────────
@export var move_speed: float = 100.0  # How many pixels per second the player moves
const SPRITE_FLIP_OFFSET: int = -1     # Visual centering offset when sprite is flipped left

# ─────────── LIVE INFORMATION THAT CHANGES DURING PLAY ───────────
var direction: Vector2 = Vector2.ZERO  # Which way the player is trying to move (WASD input)
var facing: Vector2   = Vector2.DOWN   # Which direction the player sprite is facing (for animations)
var current           = null           # Which state is currently controlling the player

# ─────────── CONNECTIONS TO CHILD NODES IN THE SCENE ───────────
@onready var sprite: Sprite2D        = $Sprite2D        # The visual player sprite (gets flipped left/right)
@onready var anim: AnimationPlayer   = $AnimationPlayer # Controls all player animations (walk, idle, attack)
@onready var idle_state              = $States/IdleState    # Handles when player is standing still
@onready var walk_state              = $States/WalkState   # Handles when player is moving around
@onready var attack_state            = $States/AttackState # Handles when player is attacking
@onready var dash_state              = $States/DashState   # Handles when player is dashing

# ─────────── SETUP THAT RUNS WHEN THE GAME STARTS ───────────
func _ready():
	# Tell each state "hey, you belong to this player" so they can control it
	for s in $States.get_children():
		s.player = self

	# Make sure attack effects are hidden when the game starts (they show during attacks)
	var attack_fx_sprite = $Sprite2D/AttackFX/AttackEffectsSprite
	attack_fx_sprite.visible = false

	# Add player to group so enemies can find us
	add_to_group("player")

	# Note: HurtBox uses its own script - setup handled there

	# Start in Idle mode
	change_state(idle_state)

# ─────────── THINGS THAT HAPPEN EVERY FRAME ───────────
func _process(dt):
	# Every frame: check what keys are pressed and convert to direction
	read_direction()
	# Every frame: update which way the player sprite should face
	update_facing()
	# Let the current state (idle, walk, attack, etc.) do its thing
	if current:
		current.update(dt)

func _physics_process(dt):
	# Let the current state handle physics stuff (like setting velocity)
	if current:
		current.physics_update(dt)
	# Actually move the player based on the velocity that was set
	move_and_slide()

# ─────────── WHEN KEYS ARE PRESSED OR RELEASED ───────────
func _unhandled_input(event):
	# Let the current state decide what to do with key presses (like attack or dash)
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
	# Look at WASD or arrow keys and figure out which direction the player wants to go
	# This creates a Vector2 where x is left/right (-1 to 1) and y is up/down (-1 to 1)
	direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down")  - Input.get_action_strength("up")
	)
	# Make sure diagonal movement isn't faster by normalizing the vector
	if direction != Vector2.ZERO:
		direction = direction.normalized()

func update_facing():
	# If the player isn't trying to move, keep facing the same direction as before
	if direction == Vector2.ZERO:
		return

	# Decide which way the player should face based on input
	# If moving left or right, face that direction. If only moving up/down, face up or down
	if direction.x != 0.0:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP

	# Flip the sprite horizontally when facing left (mirror image)
	sprite.flip_h = (facing == Vector2.LEFT)
	
	# When flipped, add offset to fix visual centering
	if facing == Vector2.LEFT:
		sprite.offset.x = SPRITE_FLIP_OFFSET
	else:
		sprite.offset.x = 0

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
