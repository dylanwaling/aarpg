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

# ─────────── PLAYER MOVEMENT YOU CAN TWEAK ───────────
@export var move_speed: float = 100.0           # Base walking speed in pixels per second

# ─────────── KNOCKBACK PHYSICS YOU CAN TWEAK ───────────
@export var knockback_duration: float = 0.3     # How long knockback effect lasts in seconds
# Note: Knockback force comes from the attacker (enemies/hazards), not from player settings

# Note: Attack and Dash settings configured in their respective state files (scene-first design)

# ─────────── SPRITE DISPLAY CONSTANTS ───────────
const SPRITE_FLIP_OFFSET: int = -1              # Pixel offset to center sprite when facing left

# ─────────── INTERNAL STATE TRACKING (DON'T MODIFY) ───────────
var direction: Vector2 = Vector2.ZERO           # Current input direction (WASD/arrow keys)
var facing: Vector2   = Vector2.DOWN            # Which way sprite faces for animations
var current           = null                    # Currently active state (idle/walk/attack/dash)

# ─────────── CONNECTIONS TO CHILD NODES IN THE SCENE ───────────
@onready var sprite: Sprite2D        = $Sprite2D        # The visual player sprite (gets flipped left/right)
@onready var anim: AnimationPlayer   = $AnimationPlayer # Controls all player animations (walk, idle, attack)
@onready var health_component: Node2D = $Health         # The health management component
@onready var hurtbox: Area2D         = $HurtBox        # Receives damage from enemy attacks
@onready var attack_fx_sprite: Sprite2D = $Sprite2D/AttackFX/AttackEffectsSprite # Attack visual effects sprite
@onready var attack_fx_anim: AnimationPlayer = $Sprite2D/AttackFX/AttackEffectsSprite/AnimationPlayer # Attack effects animation
@onready var attack_fx_node: Node2D  = $Sprite2D/AttackFX # Attack effects container node
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
	attack_fx_sprite.visible = false

	# Add player to group so enemies can find us
	add_to_group("player")

	# Validate Health component is properly connected
	if health_component:
		# Health component should auto-connect, but verify it worked
		if not health_component.died.is_connected(_on_health_died):
			push_warning("Player: Health component didn't auto-connect. Connecting manually.")
			health_component.died.connect(_on_health_died)
		if not health_component.health_changed.is_connected(_on_health_changed):
			health_component.health_changed.connect(_on_health_changed)
	else:
		push_error("Player: Health component not found! Player won't be able to take damage.")

	# Validate HurtBox component exists and is properly configured  
	if hurtbox:
		# HurtBox should auto-find Health component, but verify it worked
		if not hurtbox.get_health_component():
			push_error("Player: HurtBox couldn't find Health component! Player won't take damage from attacks.")
	else:
		push_error("Player: HurtBox not found! Player won't be able to receive damage from enemy attacks.")

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

	# Only change animation if it's different (avoids restarts)
	if !anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)

# ─────────── HEALTH & DAMAGE SYSTEM ───────────
# Note: Player receives damage through this flow:
# Enemy Hitbox → Player HurtBox → Health Component → Player.take_damage() → Death/Knockback

func take_damage(_amount: int, _hit_position: Vector2 = Vector2.ZERO):
	"""Called by Health component when player takes damage (via HurtBox system)"""
	# This function is called BY the Health component, not the other way around!
	# Add any immediate damage reactions here (screen flash, damage sounds, etc.)
	# The Health component already processed the damage before calling this
	pass  # Currently no immediate damage reactions implemented

func heal(amount: int):
	"""Restore player health (for potions, etc.)"""
	if not health_component:
		push_error("Player: No health component found!")
		return
	health_component.heal(amount)

func _on_health_died():
	"""Handle player death - called automatically by Health component"""
	print("Player died!")
	# You can add death logic here:
	# - Restart level
	# - Show game over screen
	# - Respawn at checkpoint
	# For now, just reset health
	if health_component:
		health_component.reset_health()
	else:
		push_error("Player: Death handler called but no health component found!")

func _on_health_changed(_new_health: int, _max_health: int):
	"""React to health changes"""
	# You can add effects here:
	# - Screen flash when damaged
	# - Update UI health bar
	# - Play hurt sounds
	pass

func apply_knockback(knockback_force: Vector2):
	"""Apply knockback to the player with proper decay (matches enemy implementation)"""
	# Set the knockback velocity immediately
	velocity = knockback_force
	
	# Create a timer to gradually reduce the knockback using scene-configured duration
	var tween = create_tween()
	tween.tween_method(_apply_knockback_decay, knockback_force, Vector2.ZERO, knockback_duration)

func _apply_knockback_decay(current_knockback: Vector2):
	"""Gradually reduce knockback velocity (matches enemy implementation)"""
	velocity = current_knockback
