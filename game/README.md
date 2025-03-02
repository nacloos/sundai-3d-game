# Astronaut Planet 3D

A 3D game where you control an astronaut exploring a small spherical planet, featuring custom gravity mechanics and character animations.

## Setup

1. Open the project in Godot 4.2 or later
2. Make sure the following assets are present in the `assets/biped/biped/` directory:
   - `Animation_Walking_withSkin.glb`
   - `Animation_Running_withSkin.glb`
   - `Animation_Excited_Walk_F_withSkin.glb`
3. Open the main scene at `scenes/main_scene.tscn`
4. Run the game (F5)

## Controls

- **Movement**: WASD or Arrow Keys
- **Run**: Hold Shift while moving
- **Dance**: Space bar
- **Camera Control**: Mouse movement
- **Toggle Mouse Capture**: Escape

## Features

- Spherical planet with custom gravity system
- Smooth character movement and rotation
- Multiple character animations:
  - Walking
  - Running
  - Dancing
- Dynamic camera system with mouse control
- Beautiful space environment with atmospheric effects

## Technical Details

- Planet radius: 20 units
- Gravity strength: 20.0
- Character movement speed: 5.0 units/second (2x when running)
- Camera sensitivity: 0.003
- Vertical camera angle limits: -80° to +80°

## Project Structure

```
astronaut_planet_3/
├── assets/
│   └── biped/
│       └── biped/
│           ├── Animation_Walking_withSkin.glb
│           ├── Animation_Running_withSkin.glb
│           └── Animation_Excited_Walk_F_withSkin.glb
├── scenes/
│   └── main_scene.tscn
├── scripts/
│   ├── character.gd
│   └── main_scene.gd
├── default_env.tres
├── project.godot
└── README.md
```

## Implementation Notes

- The character uses a CharacterBody3D with a CapsuleShape3D for collision
- Custom gravity system pulls the character towards the planet's center
- Movement is projected onto the planet's surface tangent plane
- Animations are handled through separate model nodes with their own AnimationPlayers
- Camera follows the character while maintaining proper orientation relative to the planet's surface 