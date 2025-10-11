class_name Player
extends CharacterBody2D

@export var move_speed: float = 100.0

var state: String = "idle"
var direction: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN  # last facing used by animations

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

func _process(_delta: float) -> void:
	handle_input()
	update_facing()      # <-- prefers horizontal when present
	update_state()
	update_animation()

func _physics_process(_delta: float) -> void:
	move_and_slide()

func handle_input() -> void:
	direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down")  - Input.get_action_strength("up")
	)
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO

func update_facing() -> void:
	if direction == Vector2.ZERO:
		return
	# Prefer horizontal if any X input exists (keeps "side" on diagonals)
	if direction.x != 0.0:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	# Flip for left vs right; "side" anim is shared
	sprite.flip_h = (facing == Vector2.LEFT)

func update_state() -> void:
	var new_state := ( "idle" if velocity == Vector2.ZERO else "walk" )
	if new_state != state:
		state = new_state

func update_animation() -> void:
	var anim_name := "%s_%s" % [state, get_facing_name()]
	if !anim.is_playing() or anim.current_animation != anim_name:
		anim.play(anim_name)

func get_facing_name() -> String:
	if facing == Vector2.UP:
		return "up"
	elif facing == Vector2.DOWN:
		return "down"
	else:
		return "side"
