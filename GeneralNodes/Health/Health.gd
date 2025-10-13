## GENERAL HEALTH SYSTEM
##
## A reusable health component that can be added to any node (Player, Enemy, Plant, etc.)
## Handles health tracking, damage, death, and optional visual health display.
## Just drag this scene onto your character and adjust max_health as needed.
## Position the HealthLabel child node in the scene editor to place the health display.

extends Node2D

# ── HEALTH SETTINGS (ADJUST IN INSPECTOR) ──
@export var max_health: int = 100          # Maximum health points
@export var show_health_display: bool = true  # Whether to show the red health number above entity
@export var override_editor_styling: bool = false  # If true, applies script styling instead of editor styling

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
	# Initialize health to maximum
	current_health = max_health
	
	# Set up health display
	_setup_health_display()
	
	# Update display
	_update_health_display()

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
		health_label.text = str(current_health)
		# Make text more visible when health is low
		if current_health <= max_health * 0.3:  # 30% health or less
			health_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			health_label.add_theme_color_override("font_color", Color.RED)
