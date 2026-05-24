# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Heat Death** is a Godot 4.6 top-down space physics game. The player controls a growing celestial body that absorbs energy, grows in mass/size, and must survive against increasingly dangerous space objects. The game uses real-ish N-body gravity (G * m1 * m2 / r²) and a unique "entropy" mechanic.

## Running the Game

Open the project in Godot 4.6+ and press F5, or run via the Godot CLI:
```
godot --path "D:/app-games/Gioco/project-heat_death"
```

There are no build steps, tests, or linting commands — this is a pure Godot/GDScript project.

## Architecture

### Autoloads (Singletons)

Defined in `project.godot`, always accessible by name:

| Singleton | File | Purpose |
|---|---|---|
| `GlobalSignals` | `Commons/global_signals.tscn` | Game-wide event bus (`game_over`, `death`, `low_health`, `windup_shake`, `use_3d`, `ceres_spawned`) |
| `UpgradeManager` | `Commons/upgrade_manager.tscn` | Player progression: energy → level-up → size/stat growth; fires `tier_changed` at milestone levels |
| `EntropyManager` | `Commons/entropy_manager.tscn` | Entropy float that rises over time; goes negative on enemy death; negative entropy applies chaotic forces to the player |

### Scene Flow

```
MainMenu (Stages/UI/MainMenu/main_menu.tscn)
    → SolarSystem (Stages/World/SolarSystem/solar_system.tscn)
        → World (Stages/World/world.tscn)
```

The main gameplay lives inside `world.tscn`.

### Entity Class Hierarchy

```
CelestialBody (extends RigidBody2D)  ← base for all physics objects
    └── SmallBody                     ← destroyable, orbitally-attractable bodies
            ├── Asteroid
            ├── Meteoroid
            ├── Comet
            ├── Vesta
            └── Ceres                 ← boss; state machine: WAIT → WINDUP → (SPAWN_ENEMIES | GAS)

Player (extends RigidBody2D)          ← separate from CelestialBody hierarchy
```

`CelestialBody` tracks all live instances via the static `celestial_bodies: Array`.  
All `CelestialBody` nodes are in the Godot group `"celestialbodies"`; the player is in group `"player"`; energy drops in group `"energy"`.

### Key Systems

**Entropy** (`Commons/entropy_manager.gd`): The `entropy_value` float increases over time via a timer. When an enemy dies it decreases (negative values). Negative entropy applies oscillating + random forces to the player (`apply_entropy()` in `player.gd`). The player can discharge negative entropy with a shockwave (Space key).

**Upgrade/Progression** (`Commons/UpgradeManager.gd`): Enemies drop energy pickups → `UpgradeManager.gain_energy()` → on level-up, `player.change_size(1.25)` grows the player. At tier thresholds (`tiers: Array`), `tier_changed` fires and the upgrade menu appears with 3 random stat upgrades.

**Orbit System** (`player.gd`): Hold right-click or Q to attract nearby `SmallBody` instances into orbit. Bodies cycle through `OrbitState.FREE → ATTRACTED → ORBITING`. `max_orbiting_bodies` limits how many can orbit simultaneously (upgradeable).

**Dynamic Spawner** (`Stages/World/celestial_bodies_spawner.gd`): Spawns objects in a rectangular "frame" around the player using Poisson-disc distribution. `GameStage` enum controls spawn weights (meteoroids early → asteroids/comets later). Objects despawn when too far from the player.

**Mass & Physics**: `CelestialBody._setup_mass()` derives mass from collision shape size × density. Damage is `mass × velocity × 0.005`. Player engulfs bodies at mass ratio ≥ 8×; "bulldozer mode" at ≥ 4×.

**Unit Conversion** (`Commons/unit_converter.gd`): `UnitConverter` static class converts between AU, km, and pixels. Scale: 1 pixel = 100 km (`GAME_SCALE = 0.01`).

### Physics Layers (2D)

- Layer 1: `Player`
- Layer 2: `CelestialBodies`

### Input Actions

| Action | Default |
|---|---|
| `up/down/left/right` | WASD / Arrow keys |
| Left mouse button | Move toward mouse cursor |
| `orbit` | Right-click / Q |
| `space` | Shockwave (discharge negative entropy) |
| `pause` | P / Escape |
| `fullscreen` | F11 |

### Addons

- `gdfxr` — procedural SFX generator (editor tool)
- `brackeys_particle_controls` — particle preview in editor
- `imgui-godot` — Dear ImGui debug overlay (`Utils/ImGui.gd`)

## Code Conventions

- GDScript with static typing throughout. All variables and parameters should be typed.
- Class names declared with `class_name` for all entity/component scripts.
- `printerr()` is used heavily for debug output (not errors); this is intentional.
- Autoloads are accessed directly by name (e.g., `EntropyManager.change_entropy(-5.0)`).
- `call_deferred()` / `queue_free.call_deferred()` is required when freeing nodes from inside physics callbacks.
- Components are looked up via `get_node_or_null("%ComponentName")` (scene-unique names).
