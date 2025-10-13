# Collision Layer Setup Guide

Based on the code analysis, here's how the collision layers should be configured:

## Physics Collision Layers (CharacterBody2D/StaticBody2D)
- **Layer 1**: Player character (for enemy AI detection, NOT for blocking movement)
- **Layer 2**: Environment/Walls (static collision - blocks movement)
- **Layer 11**: Enemy characters (for player detection, NOT for blocking movement)

## Area2D Collision Layers (HitBoxes/HurtBoxes)
- **Layer 2**: Player HurtBox (can be hit by enemy attacks)
- **Layer 3**: Player Attack HitBoxes (deals damage to enemies/breakables)
- **Layer 6**: Plant HitBoxes (can be hit by player attacks)
- **Layer 7**: General Breakables (can be hit by player attacks)
- **Layer 12**: Enemy HitBoxes (can be hit by player attacks)
- **Layer 13**: Enemy Attack HitBoxes (deals damage to player)

## Current Issues Found:

### 1. Player Walking Through Enemies
**Problem**: Player and enemies might both be on collision layer 2 (environment)
**Solution**: 
- Player CharacterBody2D should be on layer 1, mask 2 (only collides with walls)
- Enemy CharacterBody2D should be on layer 11, mask 2 (only collides with walls)
- This allows them to walk through each other while still detecting walls

### 2. Plant Breaking Not Working
**Problem**: Plant HitBox might be on wrong layer or not properly configured
**Solution**:
- Plant HitBox should be on layer 6
- Player attacks should target layers [6, 12] (plants and enemies)

### 3. Enemy Damage Not Working
**Problem**: Enemy HitBox might not be properly configured
**Solution**:
- Enemy HitBox should be on layer 12
- Enemy CharacterBody2D collision should NOT interfere with Area2D collision

## Scene Configuration Checklist:

### Player.tscn
- Player (CharacterBody2D): Layer 1, Mask 2
- Player/HurtBox (Area2D): Layer 2, Mask 13

### Enemy/Slime.tscn  
- Slime (CharacterBody2D): Layer 11, Mask 2
- Slime/HitBox (Area2D): Layer 12, Mask 3
- Slime/HurtBox (Area2D): Layer 13, Mask 2

### Plant.tscn
- Plant/StaticBody2D: Layer 2, Mask 0 (blocks movement when not broken)
- Plant/HitBox (Area2D): Layer 6, Mask 3

## Testing:
1. Player should walk through enemies but not walls
2. Player attacks should damage enemies and break plants
3. Enemy attacks should damage player (when implemented)