# ─────────── ENEMY CONTROLLER ───────────
## Main AI controller that coordinates enemy behavior through state machine
## Handles movement, combat, animations, and player detection

class_name Enemy
extends CharacterBody2D

# ─────────── ENEMY BEHAVIOR SETTINGS YOU CAN TWEAK ───────────
@export var move_speed: float = 60.0             # How fast enemy moves in pixels per second
@export var detection_range: float = 100.0       # How far enemy can see player (pixels)
@export var attack_range: float = 32.0           # How close enemy needs to be to attack player
@export var attack_cooldown: float = 1.5         # Seconds to wait between attacks
# ─────────── SPRITE DISPLAY CONSTANTS ───────────
const SPRITE_FLIP_OFFSET: int = -1               # How many pixels to offset sprite when facing left

# ─────────── KNOCKBACK PHYSICS YOU CAN TWEAK ───────────
@export var knockback_duration: float = 0.3      # How long knockback lasts in seconds

# ─────────── INTERNAL STATE TRACKING (DON'T MODIFY) ───────────
var direction: Vector2 = Vector2.ZERO            # Which direction enemy is moving (up/down/left/right)
var facing: Vector2 = Vector2.DOWN               # Which way enemy is facing for animations
var current = null                               # Current active state (idle, wander, chase, attack)
var target_player: Player = null                 # Reference to the player to chase and attack
var is_dead: bool = false                        # Whether enemy has died and should be removed
var post_attack_recovery: bool = false           # Brief period after attack where enemy ignores player
var knockback_timer: float = 0.0                # Countdown timer for knockback physics
var attack_cooldown_timer: float = 0.0          # Countdown timer preventing rapid attacks

# ─────────── PERFORMANCE OPTIMIZATION (DON'T MODIFY) ───────────
var _cached_player_distance: float = INF         # Stores calculated distance to avoid recalculating
var _distance_cache_frame: int = -1              # Tracks which frame distance was calculated

# ─────────── SCENE NODE CONNECTIONS (AUTO-FOUND) ───────────
@onready var sprite: Sprite2D = $Sprite2D        # Enemy's visual sprite image
@onready var anim: AnimationPlayer = $AnimationPlayer  # Plays walking/attacking animations
@onready var hitbox: Area2D = $HitBox            # Damage area that hurts player when attacking
@onready var health_component: Node2D = $Health  # Manages enemy's health and death
@onready var idle_state = $States/EnemyIdleState      # State: Standing still briefly
@onready var wander_state = $States/EnemyWanderState  # State: Walking around randomly
@onready var chase_state = $States/EnemyChaseState    # State: Chasing after player
@onready var attack_state = $States/EnemyAttackState  # State: Attacking the player

# ─────────── SETUP WHEN ENEMY SPAWNS ───────────
func _ready():
	# Give each state a reference to this enemy so they can control it
	for s in $States.get_children():
		s.enemy = self
	
	# Find the player in the scene so we can chase and attack them
	target_player = get_tree().get_first_node_in_group("player")
	
	# Add enemy to "enemy" group so player can find all enemies
	add_to_group("enemy")
	# Start in idle state (standing still, then will begin wandering)
	change_state(idle_state)

# ─────────── RUNS EVERY FRAME ───────────
func _process(dt):
	# Count down attack cooldown so enemy can attack again
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= dt
	
	# Update which way enemy is facing based on movement direction
	update_facing()
	# Let current state (idle/wander/chase/attack) do its logic
	if current:
		current.update(dt)

# ─────────── PHYSICS AND MOVEMENT EVERY FRAME ───────────
func _physics_process(dt):
	# Count down knockback timer (when player hits enemy)
	if knockback_timer > 0.0:
		knockback_timer -= dt
	
	# Let current state control enemy movement
	if current:
		current.physics_update(dt)
	
	# Actually move the enemy based on velocity set by states
	move_and_slide()

# ─────────── STATE MACHINE CONTROL ───────────
func change_state(next):
	# Don't switch to same state or null state
	if next == null or next == current:
		return
	
	# Tell old state it's ending, tell new state it's starting
	var prev = current
	if current:
		current.exit(next)     # Old state cleans up
	current = next
	current.enter(prev)    # New state initializes

# ─────────── DAMAGE AND DEATH HANDLING ───────────
func take_damage(amount: int, _hit_position: Vector2 = Vector2.ZERO):
	# Can't damage a dead enemy
	if is_dead:
		return
	
	# Forward damage to health component which handles health/death logic
	if health_component:
		health_component.take_damage(amount)

# Called automatically by health component when health reaches zero
func _on_health_died():
	is_dead = true        # Mark as dead so states stop running
	# Health component automatically hides health display on death
	queue_free()         # Remove enemy from scene

# Called automatically by health component when health changes (unused but required)
func _on_health_changed(_new_health: int, _max_health: int):
	pass

# ─────────── AI DECISION MAKING FUNCTIONS ───────────
func distance_to_player() -> float:
	# Return how far away player is (or infinity if no player/enemy dead)
	if target_player and not is_dead:
		# Cache the distance calculation to avoid expensive math every frame
		var current_frame = Engine.get_process_frames()
		if _distance_cache_frame != current_frame:
			_cached_player_distance = global_position.distance_to(target_player.global_position)
			_distance_cache_frame = current_frame
		return _cached_player_distance
	return INF

func direction_to_player() -> Vector2:
	# Return unit vector pointing from enemy toward player
	if target_player and not is_dead:
		return (target_player.global_position - global_position).normalized()
	return Vector2.ZERO

func can_see_player() -> bool:
	# True if player is within detection range
	return distance_to_player() <= detection_range

func can_attack_player() -> bool:
	# True if player is close enough AND we're not in attack cooldown
	return distance_to_player() <= attack_range and attack_cooldown_timer <= 0.0

# ─────────── SPRITE DIRECTION AND FLIPPING ───────────
func update_facing():
	# Don't change facing if not moving
	if direction == Vector2.ZERO:
		return
	
	# Determine which direction enemy is facing based on movement
	if direction.x != 0.0:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	
	# Flip sprite horizontally when facing left
	sprite.flip_h = (facing == Vector2.LEFT)
	# Adjust sprite position when flipped to keep it centered
	sprite.offset.x = SPRITE_FLIP_OFFSET if facing == Vector2.LEFT else 0

# ─────────── ANIMATION SYSTEM ───────────
func play_anim(state_name: String):
	# Convert facing direction to animation suffix
	var dir_name := "side"              # Default for left/right
	if facing == Vector2.UP:
		dir_name = "up"                  # For animations like "walk_up"
	elif facing == Vector2.DOWN:
		dir_name = "down"                # For animations like "walk_down"
	
	# Try to find directional animation first (e.g. "walk_side")
	var anim_name := "%s_%s" % [state_name, dir_name]
	
	# Fall back to generic animation if directional one doesn't exist
	if not anim.has_animation(anim_name):
		if anim.has_animation(state_name):   # Try just "walk" instead of "walk_side"
			anim_name = state_name
		else:
			return                          # No animation found, give up
	
	# Only start animation if it's different from current one (prevents stuttering)
	if !anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)

# ─────────── KNOCKBACK PHYSICS WHEN HIT BY PLAYER ───────────
func apply_knockback(knockback_force: Vector2):
	# Immediately apply knockback velocity
	velocity = knockback_force
	# Set timer to prevent states from overriding knockback
	knockback_timer = knockback_duration
	
	# Smoothly reduce knockback to zero over time (feels more natural)
	var tween = create_tween()
	tween.tween_method(_apply_knockback_decay, knockback_force, Vector2.ZERO, knockback_duration)

# Called by tween to gradually reduce knockback force
func _apply_knockback_decay(current_knockback: Vector2):
	velocity = current_knockback

# ─────────── AUTOMATIC SYSTEMS ───────────
# Attack cooldown countdown happens automatically in _process() above
# Health management handled automatically by Health component
# State machine updates happen automatically in _process() and _physics_process() above
