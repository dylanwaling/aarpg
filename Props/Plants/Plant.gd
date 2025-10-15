extends Node

# ─────────── PLANT SETTINGS ───────────
@export var respawn_time: float = 3.0  # Seconds until plant regrows after being destroyed

# ── STATE ──
var is_broken: bool = false

# ── NODE REFERENCES ── 
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox  
@onready var static_body: StaticBody2D = $StaticBody2D

func _ready():
    add_to_group("environment")
    
    # Validate required nodes exist
    if not sprite or not hurtbox or not static_body:
        push_error("Plant missing required child nodes: Sprite2D, HurtBox, or StaticBody2D")
        return

func _set_plant_active(active: bool):
    """Handle all plant visibility and collision state changes"""
    sprite.visible = active
    
    # Disable the entire hurtbox area instead of specific properties
    hurtbox.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED if not active else Node.PROCESS_MODE_INHERIT)
    
    # Disable the entire static body collision instead of specific layers
    static_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED if not active else Node.PROCESS_MODE_INHERIT)

func break_plant():
    """Break the plant and schedule respawn"""
    if is_broken:
        return
        
    is_broken = true
    _set_plant_active(false)
    
    await get_tree().create_timer(respawn_time).timeout
    respawn_plant()

func respawn_plant():
    """Restore plant to full health and visibility"""
    is_broken = false
    _set_plant_active(true)
    
    var health_component = get_node_or_null("Health")
    if health_component and health_component.has_method("reset_health"):
        health_component.reset_health()

func _on_health_died():
    """Called when health reaches 0"""
    break_plant()