# ─────────── ENEMY CONTROLLER ───────────
##
## The "brain" that controls enemy behavior through different AI states.
## Coordinates movement, combat, animations, and state switching.
## States handle specific behaviors: idle, chase, attack, wander, walk.

class_name Enemy
extends CharacterBody2D

# ─────────── ENEMY SETTINGS ───────────
@export var move_speed: float = 60.0  # Movement speed (pixels/second)
@export var damage: int = 10  # Damage dealt to player

@export var detection_range: float = 100.0  # Range to detect player
@export var attack_range: float = 32.0  # Range to attack player
@export var wander_range: float = 50.0  # Wandering distance
@export var chase_speed_multiplier: float = 1.5  # Speed boost when chasing

@export var knockback_resistance: float = 0.8  # Knockback strength (0.0-1.0)
@export var knockback_recovery_time: float = 0.4  # Knockback stun duration

@export var attack_cooldown: float = 1.5  # Time between attacks
@export var attack_windup_time: float = 0.5  # Attack warning time
@export var post_attack_delay: float = 0.8  # Recovery after attack
const SPRITE_FLIP_OFFSET: int = -1

# ─────────── ENEMY STATE ───────────
var direction: Vector2 = Vector2.ZERO  # Movement direction
var facing: Vector2 = Vector2.DOWN  # Sprite facing direction
var current = null  # Current AI state
var target_player: Player = null  # Player reference
var is_dead: bool = false  # Death status
var post_attack_recovery: bool = false  # Post-attack cooldown
var knockback_timer: float = 0.0  # Knockback duration
var attack_cooldown_timer: float = 0.0  # Attack cooldown

# ─────────── CHILD NODES ───────────
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $HitBox
@onready var hurtbox: Area2D = $HurtBox
@onready var health_component: Node2D = $Health
@onready var idle_state = $States/EnemyIdleState
@onready var wander_state = $States/EnemyWanderState
@onready var walk_state = $States/EnemyWalkState
@onready var chase_state = $States/EnemyChaseState
@onready var attack_state = $States/EnemyAttackState

# ─────────── INITIALIZATION ───────────
func _ready():
	# Connect states to this enemy
	for s in $States.get_children():
		s.enemy = self

	# Find player reference
	target_player = get_tree().get_first_node_in_group("player")

	# Sync hitbox damage
	if hitbox:
		hitbox.damage = damage
		hitbox.knockback_force = 80.0

	# Add to enemy group
	add_to_group("enemy")
	
	# Start in idle state
	change_state(idle_state)

# ─────────── FRAME UPDATES ───────────
func _process(dt):
	# Update attack cooldown
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= dt
	
	update_facing()
	if current:
		current.update(dt)

func _physics_process(dt):
	# Update knockback timer
	if knockback_timer > 0.0:
		knockback_timer -= dt
	
	# Let state handle physics
	if current:
		current.physics_update(dt)
	
	move_and_slide()

# ─────────── STATE MACHINE ───────────
func change_state(next):
	if next == null or next == current:
		return

	var prev = current
	if current:
		current.exit(next)
	current = next
	current.enter(prev)

# ─────────── COMBAT SYSTEM ───────────
func take_damage(amount: int, _hit_position: Vector2 = Vector2.ZERO):
	if is_dead:
		return
		
	if health_component:
		health_component.take_damage(amount)

func _on_health_died():
	# Handle death
	is_dead = true
	queue_free()

func _on_health_changed(_new_health: int, _max_health: int):
	# React to health changes (add effects here)
	pass

# ─────────── AI HELPERS ───────────
func distance_to_player() -> float:
	if target_player and not is_dead:
		return global_position.distance_to(target_player.global_position)
	return INF

func direction_to_player() -> Vector2:
	if target_player and not is_dead:
		return (target_player.global_position - global_position).normalized()
	return Vector2.ZERO

func can_see_player() -> bool:
	return distance_to_player() <= detection_range

func can_attack_player() -> bool:
	return distance_to_player() <= attack_range and attack_cooldown_timer <= 0.0

# ─────────── MOVEMENT HELPERS ───────────
func update_facing():
	if direction == Vector2.ZERO:
		return

	# Set facing direction based on movement
	if direction.x != 0.0:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP

	# Flip sprite and apply offset
	sprite.flip_h = (facing == Vector2.LEFT)
	sprite.offset.x = SPRITE_FLIP_OFFSET if facing == Vector2.LEFT else 0

# ─────────── ANIMATION HELPERS ───────────
func play_anim(state_name: String):
	# Build animation name with direction
	var dir_name := "side"
	if facing == Vector2.UP:
		dir_name = "up"
	elif facing == Vector2.DOWN:
		dir_name = "down"

	var anim_name := "%s_%s" % [state_name, dir_name]

	# Check animation exists
	if not anim.has_animation(anim_name):
		if anim.has_animation(state_name):
			anim_name = state_name
		else:
			return

	# Play if different
	if !anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)

# ─────────── KNOCKBACK SYSTEM ───────────
func apply_knockback(knockback_force: Vector2):
	velocity = knockback_force
	knockback_timer = 0.3
	
	var tween = create_tween()
	tween.tween_method(_apply_knockback_decay, knockback_force, Vector2.ZERO, 0.3)

func _apply_knockback_decay(current_knockback: Vector2):
	velocity = current_knockback

# ─────────── ATTACK HELPERS ───────────
func can_attack() -> bool:
	return attack_cooldown_timer <= 0.0

func start_attack_cooldown(duration: float = 2.0):
	attack_cooldown_timer = duration
