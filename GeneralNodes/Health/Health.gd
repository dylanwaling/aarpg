## PROFESSIONAL HEALTH SYSTEM - Universal Health Management Component
##
## Core Features:
## • Universal health management for any entity (Player, Enemy, Plant, etc.)
## • Automatic parent method connection (connects to _on_health_died, _on_damage_taken if they exist)
## • Visual health display with configurable styling
## • Proper death handling with signals
## • Setup methods for different entity types (setup_player_health, setup_enemy_health, etc.)
##
## Usage: Drag Health.tscn into your scene, configure max_health, call appropriate setup method.
## Position HealthLabel child node to control where health display appears.

extends Node2D

# ── HEALTH SETTINGS (ADJUST IN INSPECTOR) ──
@export var max_health: int = 100                    # Maximum health points
@export var starting_health: int = -1                # Starting health (-1 = use max_health)
@export var show_health_display: bool = true         # Whether to show the red health number above entity
@export var override_editor_styling: bool = false    # If true, applies script styling instead of editor styling
@export var auto_connect_to_parent: bool = true      # Automatically connect to parent's damage methods
@export var parent_damage_method: String = "take_damage"  # Method name to call on parent when damaged

# ── HEALTH STATE ──
var current_health: int
var is_dead: bool = false

# ── HEALTH DISPLAY ──
@onready var health_label: Label = $HealthLabel

# ── SIGNALS FOR OTHER NODES TO LISTEN TO ──
signal health_changed(new_health: int, max_health: int)
signal died()
signal damage_taken(damage_amount: int)

func _ready():
	# Initialize health (use starting_health if set, otherwise max_health)
	current_health = starting_health if starting_health > 0 else max_health
	
	# Set up health display
	_setup_health_display()
	
	# Auto-connect to parent if enabled
	if auto_connect_to_parent:
		_auto_connect_to_parent()
	
	# Update display
	_update_health_display()

func _auto_connect_to_parent():
	"""Automatically connect health events to parent methods if they exist"""
	var parent = get_parent()
	if not parent:
		return
	
	# Connect died signal if parent has death handling method (only if not already connected)
	if parent.has_method("_on_health_died") and not died.is_connected(parent._on_health_died):
		died.connect(parent._on_health_died)
	
	# Connect health_changed signal if parent has health change handling (only if not already connected)
	if parent.has_method("_on_health_changed") and not health_changed.is_connected(parent._on_health_changed):
		health_changed.connect(parent._on_health_changed)
	
	# Connect damage_taken signal if parent has damage handling (only if not already connected)
	if parent.has_method("_on_damage_taken") and not damage_taken.is_connected(parent._on_damage_taken):
		damage_taken.connect(parent._on_damage_taken)

func _setup_health_display():
	"""Configure the visual health display"""
	if not health_label:
		return
		
	# Only apply styling if override_editor_styling is enabled
	# Otherwise, completely respect what was set in the scene editor
	if override_editor_styling:
		health_label.add_theme_color_override("font_color", Color.RED)
		health_label.add_theme_font_size_override("font_size", 8)
	
	# Show or hide based on setting
	health_label.visible = show_health_display

func take_damage(damage_amount: int):
	"""Apply damage to this entity"""
	if is_dead:
		return
		
	current_health -= damage_amount
	current_health = max(0, current_health)  # Don't go below 0
	
	# Emit signals
	damage_taken.emit(damage_amount)
	health_changed.emit(current_health, max_health)
	
	# Update display
	_update_health_display()
	
	# Check for death
	if current_health <= 0:
		die()

func heal(heal_amount: int):
	"""Restore health to this entity"""
	if is_dead:
		return
		
	current_health += heal_amount
	current_health = min(max_health, current_health)  # Don't go above max
	
	# Emit signal and update display
	health_changed.emit(current_health, max_health)
	_update_health_display()

func die():
	"""Handle death"""
	if is_dead:
		return
		
	is_dead = true
	current_health = 0
	
	# Emit death signal
	died.emit()
	
	# Update display
	_update_health_display()

func reset_health():
	"""Reset to full health"""
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
	_update_health_display()

func set_health(new_health: int):
	"""Set health to a specific value"""
	current_health = clamp(new_health, 0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_display()
	
	if current_health <= 0:
		die()

func get_health() -> int:
	"""Get current health value"""
	return current_health

func get_max_health() -> int:
	"""Get maximum health value"""
	return max_health

func is_alive() -> bool:
	"""Check if entity is still alive"""
	return not is_dead

func get_health_percentage() -> float:
	"""Get health as a percentage (0.0 to 1.0)"""
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func _update_health_display():
	"""Update the visual health display"""
	if health_label and show_health_display:
		# Update text display
		health_label.text = str(current_health)
		
		# Update health bar if it exists
		var health_bar = get_node_or_null("HealthBar") 
		if not health_bar:
			health_bar = get_node_or_null("../HealthBar")  # Check parent
		if health_bar and health_bar.has_method("set_value"):
			var percentage = float(current_health) / float(max_health) * 100.0
			health_bar.value = percentage
		
		# Make text more visible when health is low
		if current_health <= max_health * 0.3:  # 30% health or less
			health_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			health_label.add_theme_color_override("font_color", Color.RED)

# ─────────── MODULAR SETUP METHODS ───────────
func setup_player_health(max_hp: int = 40, show_display: bool = true):
	"""Quick setup for player health"""
	max_health = max_hp
	current_health = max_hp
	show_health_display = show_display
	auto_connect_to_parent = true
	_update_health_display()

func setup_enemy_health(max_hp: int = 30, show_display: bool = false):
	"""Quick setup for enemy health"""
	max_health = max_hp
	current_health = max_hp
	show_health_display = show_display
	auto_connect_to_parent = true
	_update_health_display()

func setup_plant_health(max_hp: int = 1, show_display: bool = false):
	"""Quick setup for breakable plant health"""
	max_health = max_hp
	current_health = max_hp
	show_health_display = show_display
	auto_connect_to_parent = true
	_update_health_display()

func configure_from_editor():
	"""Call this to refresh settings when changed in editor"""
	if starting_health > 0:
		current_health = starting_health
	else:
		current_health = max_health
	_update_health_display()

func trigger_parent_damage_method(amount: int):
	"""Manually call the parent's damage method if it exists"""
	var parent = get_parent()
	if parent and parent.has_method(parent_damage_method):
		parent.call(parent_damage_method, amount)
