# ─────────── BREAKABLE PLANT SYSTEM ───────────
##
## PURPOSE: This script creates destructible plants that can be broken by player attacks
##          and automatically regrow after a set time period.
##
## HOW IT WORKS:
## 1. Player attacks plant → HurtBox receives damage → Health component processes it
## 2. When health reaches 0 → Health component calls _on_health_died() automatically
## 3. Plant becomes invisible and non-collidable (broken state)
## 4. After respawn_time seconds → Plant becomes visible and gets full health back
##
## SCENE SETUP:
## • Plant (this script)
##   ├── Sprite2D (visual appearance)
##   ├── StaticBody2D (blocks player movement when alive)
##   ├── HurtBox (receives damage from player attacks)
##   └── Health (manages health points and death detection)
##
## INSPECTOR SETTINGS:
## • respawn_time: How long plant stays broken before regrowing
## • Health component: Set max_health and show_health_display in its inspector
## • HurtBox component: Set damage immunity and knockback settings in its inspector

extends Node

# ─────────── PLANT SETTINGS YOU CAN TWEAK ───────────

@export var respawn_time: float = 3.0  # How long plant stays broken before regrowing

# ─────────── PLANT STATE TRACKING ───────────

var is_broken: bool = false  # True when plant is broken and waiting to respawn

# ─────────── CHILD NODE CONNECTIONS ───────────

@onready var sprite: Sprite2D = $Sprite2D  # Plant's visual image
@onready var hurtbox: Area2D = $HurtBox  # Receives damage from attacks
@onready var static_body: StaticBody2D = $StaticBody2D  # Blocks player movement
@onready var health_component: Node2D = $Health  # Health management component

# ─────────── INITIALIZATION ───────────

func _ready():
    # Add to environment group (prevents knockback)
    add_to_group("environment")
    
    # Check required nodes exist
    if not sprite or not hurtbox or not static_body or not health_component:
        push_error("Plant missing required child nodes: Sprite2D, HurtBox, StaticBody2D, or Health")
        return

# ─────────── INTERNAL STATE MANAGEMENT ───────────

func _set_plant_active(active: bool):
    # ─────────── VISUAL STATE CONTROL ───────────
    # Turn plant ON/OFF: visible + collidable when active, hidden + passable when inactive
    sprite.visible = active  # Show/hide plant image
    
    # ─────────── DAMAGE SYSTEM CONTROL ───────────
    # Enable/disable damage receiving (safe deferred call)
    hurtbox.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED if not active else Node.PROCESS_MODE_INHERIT)
    
    # ─────────── COLLISION CONTROL ───────────
    # Enable/disable collision blocking (safe deferred call)
    static_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED if not active else Node.PROCESS_MODE_INHERIT)
    
    # Note: Health display visibility is now handled automatically by the Health component
    # - Health.die() automatically hides the health display
    # - Health.reset_health() automatically shows it again

# ─────────── PLANT DESTRUCTION SYSTEM ───────────

func break_plant():
    # Destroy plant and schedule respawn
    
    if is_broken:
        return  # Already broken, do nothing
    
    is_broken = true  # Mark as broken
    _set_plant_active(false)  # Hide and disable collision
    
    # Wait for respawn timer, then regrow
    await get_tree().create_timer(respawn_time).timeout
    respawn_plant()

# ─────────── PLANT RESPAWN SYSTEM ───────────

func respawn_plant():
    # ─────────── PLANT REVIVAL SYSTEM ───────────
    # Bring broken plant back to life with full health
    
    is_broken = false  # Mark as alive
    _set_plant_active(true)  # Show and enable collision
    
    # ─────────── HEALTH RESTORATION ───────────
    # Reset health to maximum (using the cached health_component reference)
    if health_component and health_component.has_method("reset_health"):
        health_component.reset_health()
    else:
        push_warning("Plant: Health component not found or missing reset_health() method")

# ─────────── HEALTH SYSTEM INTEGRATION ───────────

func _on_health_died():
    # ─────────── AUTOMATIC DEATH HANDLER ───────────
    # Called automatically by Health component when health reaches 0
    # Health component auto-connects to this method by name
    break_plant()