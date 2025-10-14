## ENEMY CONTROLLER - The Main Enemy Manager
## 
## This is the "brain" of the enemy character that coordinates everything.
## It handles AI decision making, manages which direction the enemy is facing,
## handles animations, and delegates specific behaviors to different states
## (like EnemyIdleState for standing still, EnemyChaseState for chasing player, EnemyAttackState for attacking)
## 
## Think of it as a coordinator that says "Hey EnemyChaseState, the player is nearby!"
## or "EnemyAttackState, time to do an attack!" based on what's happening in the game.

class_name Enemy
extends CharacterBody2D

# ─────────── GAME SETTINGS YOU CAN ADJUST ───────────
@export var move_speed: float = 60.0           # How many pixels per second the enemy moves (slower than player)

# ── COMBAT STATS (EASY TO ADJUST) ──
@export var damage: int = 10                   # How much damage this enemy deals to the player

# ── AI BEHAVIOR SETTINGS ──
@export var detection_range: float = 100.0     # How close the player needs to be for enemy to notice
@export var attack_range: float = 32.0         # How close the player needs to be for enemy to attack
const SPRITE_FLIP_OFFSET: int = -1             # Visual centering offset when sprite is flipped left

# ─────────── LIVE INFORMATION THAT CHANGES DURING PLAY ───────────
var direction: Vector2 = Vector2.ZERO          # Which way the enemy is trying to move (AI controlled)
var facing: Vector2   = Vector2.DOWN           # Which direction the enemy sprite is facing (for animations)
var current           = null                   # Which state is currently controlling the enemy
var target_player: Player = null               # Reference to the player character to chase/attack
var is_dead: bool = false                      # Whether this enemy has been defeated
var post_attack_recovery: bool = false         # True when enemy should ignore player after attacking
var knockback_timer: float = 0.0               # Timer for knockback duration
var attack_cooldown_timer: float = 0.0         # Prevents rapid attacks

# ─────────── CONNECTIONS TO CHILD NODES IN THE SCENE ───────────
@onready var sprite: Sprite2D        = $Sprite2D          # The visual enemy sprite (gets flipped left/right)
@onready var anim: AnimationPlayer   = $AnimationPlayer   # Controls all enemy animations (walk, idle, attack)
@onready var hitbox: Area2D          = $HitBox           # Takes damage from player attacks
@onready var hurtbox: Area2D         = $HurtBox          # Deals damage to player (if enemy can attack)
@onready var health_component: Node2D = $Health          # The health management component
@onready var idle_state              = $States/EnemyIdleState     # Handles when enemy is standing still
@onready var wander_state            = $States/EnemyWanderState   # Handles when enemy is wandering around
@onready var walk_state              = $States/EnemyWalkState     # Handles when enemy is moving around
@onready var chase_state             = $States/EnemyChaseState    # Handles when enemy is chasing the player
@onready var attack_state            = $States/EnemyAttackState   # Handles when enemy is attacking

# ─────────── SETUP THAT RUNS WHEN THE GAME STARTS ───────────
func _ready():
	# Tell each state "hey, you belong to this enemy" so they can control it
	for s in $States.get_children():
		s.enemy = self

	# Find the player in the scene so we can chase/attack them
	target_player = get_tree().get_first_node_in_group("player")

	# Configure using modular system
	# Configure enemy to receive damage from player attacks
	if hurtbox and hurtbox.has_method("setup_enemy_hurtbox"):
		hurtbox.setup_enemy_hurtbox()  # Sets up collision layers for player damage
	
	if hitbox:
		hitbox.damage = damage  # Set enemy damage using new professional system
		hitbox.knockback_force = 80.0  # Default enemy knockback
	
	if health_component and health_component.has_method("setup_enemy_health"):
		health_component.auto_connect_to_parent = false  # Disable auto-connect to prevent duplicates
		health_component.setup_enemy_health(60, true)  # 60 HP, show health display

	# Add enemy to group so player and other systems can find us
	add_to_group("enemy")
	
	# Health component auto-connects to our methods, no manual connection needed
	
	# Start in Idle mode
	change_state(idle_state)

# ─────────── THINGS THAT HAPPEN EVERY FRAME ───────────
func _process(dt):
	# Count down attack cooldown timer
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= dt
	
	# Every frame: update which way the enemy sprite should face
	update_facing()
	# Let the current state (idle, chase, attack, etc.) do its thing
	if current:
		current.update(dt)

func _physics_process(dt):
	# Count down knockback protection timer BEFORE states run (prevents state interference)
	if knockback_timer > 0.0:
		knockback_timer -= dt
	
	# Let the current state handle physics stuff (like setting velocity)
	if current:
		current.physics_update(dt)
	
	# Actually move the enemy based on the velocity that was set
	move_and_slide()

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

# ─────────── COMBAT SYSTEM ───────────
func take_damage(amount: int, _hit_position: Vector2 = Vector2.ZERO):
	"""Called when player attacks hit this enemy"""
	if is_dead:
		return
		
	if health_component:
		health_component.take_damage(amount)
		
	# Add hurt effects here:
	# - Play hurt animation
	# - Flash red color
	# - Play hurt sound
	# - Apply knockback

func _on_health_died():
	"""Handle enemy death - play death animation, drop items, etc."""
	is_dead = true
	# For now, just remove the enemy
	queue_free()

func _on_health_changed(_new_health: int, _max_health: int):
	"""React to health changes"""
	# You can add effects here:
	# - Hurt animations
	# - Color flashing
	# - Damage numbers
	pass

# Collision methods removed - now handled by Hitbox/Hurtbox scripts

# ─────────── AI HELPER FUNCTIONS ───────────
func distance_to_player() -> float:
	"""How far away is the player from this enemy?"""
	if target_player and not is_dead:
		return global_position.distance_to(target_player.global_position)
	return INF

func direction_to_player() -> Vector2:
	"""Which direction should the enemy move to get closer to the player?"""
	if target_player and not is_dead:
		return (target_player.global_position - global_position).normalized()
	return Vector2.ZERO

func can_see_player() -> bool:
	"""Is the player within detection range?"""
	return distance_to_player() <= detection_range

func can_attack_player() -> bool:
	"""Is the player close enough to attack and not in cooldown?"""
	# Check both distance and attack cooldown
	return distance_to_player() <= attack_range and attack_cooldown_timer <= 0.0

# ─────────── MOVEMENT & FACING HELPERS ───────────
func update_facing():
	# If the enemy isn't trying to move, keep facing the same direction as before
	if direction == Vector2.ZERO:
		return

	# Decide which way the enemy should face based on movement
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

	# Check if animation exists before playing
	if not anim.has_animation(anim_name):
		# Fallback to basic animation names
		if anim.has_animation(state_name):
			anim_name = state_name
		else:
			# Animation doesn't exist - skip silently
			return

	# Only change animation if it's different (avoids restarts)
	if !anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)

func apply_knockback(knockback_force: Vector2):
	"""Apply knockback to the enemy with proper decay (matches player implementation)"""

	# Set the knockback velocity immediately
	velocity = knockback_force
	
	# Set knockback timer to prevent movement override
	knockback_timer = 0.3
	
	# Create a timer to gradually reduce the knockback (same as player)
	var tween = create_tween()
	tween.tween_method(_apply_knockback_decay, knockback_force, Vector2.ZERO, 0.3)

func _apply_knockback_decay(current_knockback: Vector2):
	"""Called by tween to smoothly reduce knockback velocity each frame"""
	velocity = current_knockback

func can_attack() -> bool:
	"""Check if enemy is allowed to attack (not in cooldown)"""
	return attack_cooldown_timer <= 0.0

func start_attack_cooldown(duration: float = 2.0):
	"""Set attack cooldown to prevent rapid attacks"""
	attack_cooldown_timer = duration
	print("Enemy attack cooldown started: ", duration, " seconds")
