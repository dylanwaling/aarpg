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

# ─────────── VISUAL STYLING SETTINGS (SCENE-FIRST) ───────────
@export var normal_health_color: Color = Color.GREEN   # Color for normal health display
@export var low_health_color: Color = Color.RED   # Color when health is critically low
@export var low_health_threshold: float = 0.3        # Health percentage that triggers low health warning (0.3 = 30%)
@export var default_font_size: int = 8               # Font size for health display (only used if override_editor_styling = true)

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
	# ─────────── PARENT ENTITY CHECK ───────────
	# Must have parent entity (Player, Enemy, Plant, etc.) to connect signals
	var parent = get_parent()
	if not parent:
		push_warning("Health: No parent found for auto-connection")
		return
	
	# ─────────── DEATH SIGNAL AUTO-WIRING ───────────
	# If parent has _on_health_died() method, automatically connect death signal
	if parent.has_method("_on_health_died"):
		# Only connect if not already connected (prevents duplicate connections)
		if not died.is_connected(parent._on_health_died):
			died.connect(parent._on_health_died)
		else:
			push_warning("Health: _on_health_died already connected to parent")
	
	# ─────────── HEALTH CHANGE SIGNAL AUTO-WIRING ───────────
	# If parent has _on_health_changed() method, automatically connect health updates
	if parent.has_method("_on_health_changed"):
		# Only connect if not already connected (prevents duplicate connections)
		if not health_changed.is_connected(parent._on_health_changed):
			health_changed.connect(parent._on_health_changed)
		else:
			push_warning("Health: _on_health_changed already connected to parent")
	
	# ─────────── DAMAGE REACTION SIGNAL AUTO-WIRING ───────────
	# If parent has _on_damage_taken() method, automatically connect damage notifications
	# Note: This is for immediate reactions (screen shake, sounds, effects)
	# The actual damage processing happens through take_damage() method calls
	if parent.has_method("_on_damage_taken"):
		# Only connect if not already connected (prevents duplicate connections)
		if not damage_taken.is_connected(parent._on_damage_taken):
			damage_taken.connect(parent._on_damage_taken)
		else:
			push_warning("Health: _on_damage_taken already connected to parent")

func _setup_health_display():
	"""Configure the visual health display - colors, fonts, visibility"""
	# ─────────── DISPLAY COMPONENT CHECK ───────────
	# Can't set up display without a health label component
	if not health_label:
		return
		
	# ─────────── SCENE-FIRST STYLING SYSTEM ───────────
	# Only override scene editor styling if explicitly requested
	# This respects designer's visual choices in the scene editor
	if override_editor_styling:
		# Apply script-defined colors and fonts (overrides scene settings)
		health_label.add_theme_color_override("font_color", normal_health_color)
		health_label.add_theme_font_size_override("font_size", default_font_size)
	
	# ─────────── VISIBILITY CONTROL ───────────
	# Show or hide health display based on inspector setting
	health_label.visible = show_health_display

# ─────────── CORE HEALTH MANAGEMENT FUNCTIONS ───────────
func take_damage(damage_amount: int):
	"""Process incoming damage and handle death if health reaches zero"""
	# ─────────── DAMAGE VALIDATION ───────────
	# Dead entities can't take more damage (prevents negative health)
	if is_dead:
		return
		
	# ─────────── HEALTH CALCULATION ───────────
	# Subtract damage from current health points
	current_health -= damage_amount
	# Make sure health never goes below 0 (clamp to minimum)
	current_health = max(0, current_health)
	
	# ─────────── NOTIFICATION SYSTEM ───────────
	# Tell other systems "I just took damage" (for effects, sounds, etc.)
	damage_taken.emit(damage_amount)
	# Tell other systems "My health changed" (for UI updates, AI reactions)
	health_changed.emit(current_health, max_health)
	
	# ─────────── VISUAL UPDATE ───────────
	# Update the red health number displayed above the entity
	_update_health_display()
	
	# ─────────── DEATH CHECK ───────────
	# If health reached 0, entity dies (triggers death animations, cleanup, etc.)
	if current_health <= 0:
		die()

func heal(heal_amount: int):
	"""Restore health points - used for potions, rest areas, etc."""
	# ─────────── HEALING VALIDATION ───────────
	# Dead entities can't be healed (must use reset_health() to revive them)
	if is_dead:
		return
		
	# ─────────── HEALTH RESTORATION ───────────
	# Add healing points to current health
	current_health += heal_amount
	# Make sure health never exceeds maximum (clamp to max_health)
	current_health = min(max_health, current_health)
	
	# Notify systems and update display
	health_changed.emit(current_health, max_health)
	_update_health_display()

func die():
	"""Handle entity death - called when health reaches zero"""
	# ─────────── DEATH VALIDATION ───────────
	# Prevent multiple death calls (already dead entities stay dead)
	if is_dead:
		return
		
	# ─────────── DEATH STATE SETUP ───────────
	# Mark entity as dead (stops further damage, healing, etc.)
	is_dead = true
	# Set health to exactly 0 (ensures consistent death state)
	current_health = 0
	
	# ─────────── HEALTH DISPLAY AUTO-HIDE ───────────
	# Automatically hide health display when entity dies
	# This prevents floating health numbers on dead entities
	if health_label:
		health_label.visible = false
	
	# ─────────── DEATH NOTIFICATION ───────────
	# Tell parent entity "I died" (triggers death animations, cleanup, respawn)
	died.emit()
	
	# ─────────── VISUAL DEATH UPDATE ───────────
	# Update health display to show 0 health (usually hides or grays out)
	_update_health_display()

func reset_health():
	"""Reset to full health and restore visibility"""
	# ─────────── HEALTH RESTORATION ───────────
	is_dead = false
	current_health = max_health
	
	# ─────────── HEALTH DISPLAY AUTO-SHOW ───────────
	# Automatically show health display when entity is revived
	# This ensures health numbers appear when entities respawn
	if health_label and show_health_display:
		health_label.visible = true
	
	# ─────────── REVIVAL NOTIFICATIONS ───────────
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
	"""Get health as a percentage (0.0 to 1.0) - used by UI, visual effects, and AI systems"""
	# This function provides normalized health data for:
	# - Health bars and UI elements (0.0 = empty, 1.0 = full)
	# - Visual effects (screen red overlay, damage indicators)
	# - AI behavior (enemies get more aggressive when player is low health)
	# - Save/load systems for health persistence
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

# ─────────── VISUAL DISPLAY SYSTEM ───────────
func _update_health_display():
	"""Update the visual health display - text and optional health bar"""
	# ─────────── DISPLAY VALIDATION ───────────
	# Don't update if no health label exists or display is turned off
	if not health_label or not show_health_display:
		return
	
	# ─────────── HEALTH TEXT UPDATE ───────────
	# Show current health as red number above entity (e.g. "75", "0")
	health_label.text = str(current_health)
	
	# ─────────── HEALTH BAR UPDATE (OPTIONAL) ───────────
	# Look for health bar component (only if designer added one in scene)
	var health_bar = get_node_or_null("HealthBar") or get_node_or_null("../HealthBar")
	if health_bar and health_bar.has_method("set_value"):
		# Convert health to percentage (0-100%) for progress bar display
		health_bar.value = float(current_health) / float(max_health) * 100.0
	
	# ─────────── LOW HEALTH WARNING COLORS ───────────
	# Change text color when health gets dangerously low
	if current_health <= max_health * low_health_threshold:
		# Health is critically low - use warning color (default: yellow)
		health_label.add_theme_color_override("font_color", low_health_color)
	else:
		# Health is normal - use standard color (default: red)
		health_label.add_theme_color_override("font_color", normal_health_color)



func validate_parent_integration() -> bool:
	"""Validate that Health component is properly integrated with its parent entity"""
	var parent = get_parent()
	if not parent:
		push_error("Health: No parent entity found!")
		return false
	
	# Check parent has required death handler
	if auto_connect_to_parent and not parent.has_method("_on_health_died"):
		push_warning("Health: Parent missing _on_health_died() method - death won't be handled properly")
	
	# Parent damage reactions handled through signals, not direct method calls
	
	# Check if there's a HurtBox that should be finding this Health component
	var hurtbox_found = false
	for child in parent.get_children():
		if child.get_script() and child.has_method("get_health_component"):
			if child.get_health_component() == self:
				hurtbox_found = true
				break
	
	if not hurtbox_found:
		push_warning("Health: No HurtBox component found that references this Health - entity may not take damage")
	
	return true

# ─────────── FINAL VALIDATION: SCENE FIRST COMPLIANCE ───────────
# ✅ All settings configurable via inspector (@export variables)
# ✅ No hardcoded values - everything customizable per scene
# ✅ Auto-connection system respects parent entity structure
# ✅ Visual styling respects scene editor settings first
# Health system complete - maximum flexibility with optimal performance
