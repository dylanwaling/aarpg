# How to Use the New General Health System

## What I Created

I've created a reusable Health system that you can drag onto any character:
- **Health.gd**: A complete health management script
- **Health.tscn**: A ready-to-use health component scene

## How to Use It

### 1. Add Health to Your Characters

In the Godot editor:
1. Open your Player.tscn, Slime.tscn, or Plant.tscn
2. Drag the `GeneralNodes/Health/Health.tscn` scene as a child of your character
3. In the Inspector, adjust the settings:
   - **Max Health**: Set to desired value (100 for player, 50 for slime, 1 for plant)
   - **Show Health Display**: Keep true for placeholder debugging
   - **Health Display Offset**: Adjust position to place above character

### 2. Connect to Your Scripts

In your character scripts, replace health management with references to the Health node:

```gdscript
# Add this to get reference to health component
@onready var health_component: Node2D = $Health

# Remove these old variables:
# @export var max_health: int = 100
# @export var current_health: int = 100
# @export var health: int = 50
# @onready var health_label: Label = null

# In _ready(), remove:
# _create_health_display()

# Replace take_damage() function with:
func take_damage(amount: int, _hit_position: Vector2 = Vector2.ZERO):
	if health_component:
		health_component.take_damage(amount)

# Connect to health events in _ready():
func _ready():
	# ... existing code ...
	
	# Connect to health events
	if health_component:
		health_component.died.connect(_on_health_died)
		health_component.health_changed.connect(_on_health_changed)

# Add these callback functions:
func _on_health_died():
	# Handle death (for enemies: queue_free(), for player: restart level, etc.)
	pass

func _on_health_changed(new_health: int, max_health: int):
	# React to health changes if needed
	pass
```

### 3. What to Remove from Your Current Scripts

**From Player.gd, Enemy.gd, and Plant.gd, remove:**
- Health-related @export variables (`max_health`, `current_health`, `health`)
- `@onready var health_label` line
- `_create_health_display()` function
- `_update_health_display()` function
- Calls to `_create_health_display()` and `_update_health_display()`
- Manual health tracking code in `take_damage()` functions

## Benefits

- ✅ **No code duplication** - health logic is in one place
- ✅ **Easy to use** - just drag and drop the scene
- ✅ **Consistent** - all characters use the same health system
- ✅ **Flexible** - adjust max health and display settings per character
- ✅ **Event-driven** - other systems can listen to health changes
- ✅ **Visual feedback** - automatic health display positioning

## Health Component Features

The Health component provides:
- `take_damage(amount)` - Apply damage
- `heal(amount)` - Restore health  
- `set_health(value)` - Set specific health value
- `get_health()` - Get current health
- `is_alive()` - Check if still alive
- `reset_health()` - Reset to full health

## Signals Available

- `health_changed(new_health, max_health)` - When health changes
- `died()` - When health reaches 0
- `damage_taken(amount)` - When damage is applied

## Example Integration

After adding Health.tscn to your Player scene and connecting it, you can:
```gdscript
# Check if player is alive
if health_component.is_alive():
	# Do something...

# Get health percentage for UI
var health_percent = health_component.get_health_percentage()

# Heal the player
health_component.heal(25)
```