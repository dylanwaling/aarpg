# ─────────── ENEMY CONTROLLER ───────────
## Main AI controller that coordinates enemy behavior through state machine
## Handles movement, combat, animations, and player detection

class_name Enemy
extends CharacterBody2D

# ─────────── ENEMY SETTINGS ───────────
@export var move_speed: float = 60.0
@export var detection_range: float = 100.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.5
# ─────────── CONSTANTS ───────────
const SPRITE_FLIP_OFFSET: int = -1

# ─────────── STATE VARIABLES ───────────
var direction: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var current = null
var target_player: Player = null
var is_dead: bool = false
var post_attack_recovery: bool = false
var knockback_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

# ─────────── NODE REFERENCES ───────────
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
	# Initialize state machine
	for s in $States.get_children():
		s.enemy = self
	
	# Find player reference
	target_player = get_tree().get_first_node_in_group("player")
	
	# Set up groups and initial state
	add_to_group("enemy")
	change_state(idle_state)

# ─────────── FRAME UPDATES ───────────
func _process(dt):
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= dt
	
	update_facing()
	if current:
		current.update(dt)

func _physics_process(dt):
	if knockback_timer > 0.0:
		knockback_timer -= dt
	
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
	is_dead = true
	queue_free()

func _on_health_changed(_new_health: int, _max_health: int):
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
	
	if direction.x != 0.0:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	
	sprite.flip_h = (facing == Vector2.LEFT)
	sprite.offset.x = SPRITE_FLIP_OFFSET if facing == Vector2.LEFT else 0

# ─────────── ANIMATION HELPERS ───────────
func play_anim(state_name: String):
	var dir_name := "side"
	if facing == Vector2.UP:
		dir_name = "up"
	elif facing == Vector2.DOWN:
		dir_name = "down"
	
	var anim_name := "%s_%s" % [state_name, dir_name]
	
	if not anim.has_animation(anim_name):
		if anim.has_animation(state_name):
			anim_name = state_name
		else:
			return
	
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
# Attack cooldown managed automatically in _process()
