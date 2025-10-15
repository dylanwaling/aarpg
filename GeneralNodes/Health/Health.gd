## HEALTH COMPONENT - Universal Life Management System
##
## This component handles health, damage, death, and visual health display for any entity.
## It automatically connects to parent methods and provides a clean interface for damage systems.
##
## Key Features:
## - Works with Player, Enemy, Plant, or any game entity
## - Auto-connects to parent methods (_on_health_died, _on_health_changed, etc.)
## - Visual health display with configurable styling  
## - Proper signal-based communication for loose coupling
## - Scene-first configuration - all settings via inspector
##
## Usage: Add Health.tscn to your scene, configure in inspector, position HealthLabel as needed.

class_name Health
extends Node2D

# ─────────── HEALTH SETTINGS YOU CAN TWEAK ───────────
@export var max_health: int = 100                    # Total health points this entity can have
@export var starting_health: int = -1                # Health at game start (-1 = use max_health)
@export var show_health_display: bool = true         # Show red health number above entity
@export var override_editor_styling: bool = false    # Apply script styling over scene editor styling
@export var auto_connect_to_parent: bool = true      # Auto-wire signals to parent methods
@export var parent_damage_method: String = "take_damage"  # Parent method to call when damaged

# ─────────── INTERNAL HEALTH STATE (DON'T MODIFY) ───────────
var current_health: int                              # Current health points remaining
var is_dead: bool = false                           # Whether this entity has died

# ─────────── VISUAL DISPLAY COMPONENT ───────────
@onready var health_label: Label = $HealthLabel     # Text showing current health number

# ─────────── COMMUNICATION SIGNALS ───────────
# Other components can listen to these signals to react to health events
signal health_changed(new_health: int, max_health: int)  # When health increases or decreases
signal died()                                            # When health reaches zero
signal damage_taken(damage_amount: int)                  # When entity takes damage

# ─────────── COMPONENT INITIALIZATION ───────────
func _ready():
	# Set starting health value (use custom starting_health or default to max)
	current_health = starting_health if starting_health > 0 else max_health
	
	# Configure the visual health display styling and visibility
	_setup_health_display()
	
	# Wire up automatic signal connections to parent entity methods
	if auto_connect_to_parent:
		_auto_connect_to_parent()
	
	# Make sure the health display shows the correct starting value
	_update_health_display()

func _auto_connect_to_parent():
	"""Automatically wire health signals to parent methods - prevents manual connection errors"""
	var parent = get_parent()
	if not parent:
		push_warning("Health: No parent found for auto-connection")
		return
	
	# ─────────── DEATH SIGNAL CONNECTION ───────────
	# Connect to parent's death handler if it exists (and isn't already connected)
	if parent.has_method("_on_health_died"):
		if not died.is_connected(parent._on_health_died):
			died.connect(parent._on_health_died)
		else:
			push_warning("Health: _on_health_died already connected to parent")
	
	# ─────────── HEALTH CHANGE SIGNAL CONNECTION ───────────
	# Connect to parent's health change handler if it exists (and isn't already connected)
	if parent.has_method("_on_health_changed"):
		if not health_changed.is_connected(parent._on_health_changed):
			health_changed.connect(parent._on_health_changed)
		else:
			push_warning("Health: _on_health_changed already connected to parent")
	
	# ─────────── DAMAGE SIGNAL CONNECTION ───────────
	# Connect to parent's damage reaction handler if it exists (and isn't already connected)
	if parent.has_method("_on_damage_taken"):
		if not damage_taken.is_connected(parent._on_damage_taken):
			damage_taken.connect(parent._on_damage_taken)
		else:
			push_warning("Health: _on_damage_taken already connected to parent")

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

# ─────────── CORE HEALTH MANAGEMENT FUNCTIONS ───────────
func take_damage(damage_amount: int):
	"""Process incoming damage and handle death if health reaches zero"""
	# Dead entities can't take more damage
	if is_dead:
		return
		
	# Apply damage and clamp to valid range (0 to max_health)
	current_health -= damage_amount
	current_health = max(0, current_health)  # Never go below 0
	
	# ─────────── SIGNAL BROADCASTING ───────────
	# Notify other systems about the damage and health change
	damage_taken.emit(damage_amount)                # "I just took X damage"
	health_changed.emit(current_health, max_health) # "My health is now X/Y"
	
	# Update the visual health display to show new value
	_update_health_display()
	
	# Check if this damage was fatal
	if current_health <= 0:
		die()  # Trigger death sequence

func heal(heal_amount: int):
	"""Restore health points - used for potions, rest areas, etc."""
	# Dead entities can't be healed (use reset_health() to revive)
	if is_dead:
		return
		
	# Apply healing and clamp to valid range (0 to max_health)
	current_health += heal_amount
	current_health = min(max_health, current_health)  # Never exceed maximum
	
	# Notify systems and update display
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

# ─────────── VISUAL DISPLAY SYSTEM ───────────
func _update_health_display():
	"""Update the visual health display - text and optional health bar"""
	if not health_label or not show_health_display:
		return
	
	# ─────────── TEXT DISPLAY UPDATE ───────────
	health_label.text = str(current_health)
	
	# ─────────── HEALTH BAR UPDATE (IF PRESENT) ───────────
	# Look for health bar as child or sibling
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		health_bar = get_node_or_null("../HealthBar")  # Check parent's children
	
	if health_bar and health_bar.has_method("set_value"):
		# Convert health to percentage for progress bar
		var percentage = float(current_health) / float(max_health) * 100.0
		health_bar.value = percentage
	
	# ─────────── VISUAL WARNING SYSTEM ───────────
	# Change color when health is critically low
	if current_health <= max_health * 0.3:  # 30% health or less = danger zone
		health_label.add_theme_color_override("font_color", Color.YELLOW)  # Warning color
	else:
		health_label.add_theme_color_override("font_color", Color.RED)     # Normal color

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
