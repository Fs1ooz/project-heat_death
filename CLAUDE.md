# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Heat Death** is a Godot 4.7 top-down space physics game. The player controls a growing celestial body that absorbs energy, grows in mass/size, and must survive against increasingly dangerous space objects. The game uses real-ish N-body gravity (G * m1 * m2 / r²) and a unique "entropy" mechanic.

## Running the Game

Open the project in Godot 4.7+ and press F5, or run via the Godot CLI:
```
godot --path "D:/app-games/Gioco/project-heat_death"
```

There are no build steps, tests, or linting commands — this is a pure Godot/GDScript project.

## Architecture

### Autoloads (Singletons)

Defined in `project.godot`, always accessible by name:

| Singleton | File | Purpose |
|---|---|---|
| `GlobalSignals` | `Commons/global_signals.tscn` | Game-wide event bus: `game_over`, `death(body)`, `low_health(bool)`, `windup_shake(intensity, time)`, `ceres_spawned(node)` |
| `UpgradeManager` | `Commons/upgrade_manager.tscn` | Player progression: emits `tier_changed`, `energy_changed(current, max, level)`, `energy_gained(amount)` |
| `EntropyManager` | `Commons/entropy_manager.tscn` | Entropy float that rises over time; emits `entropy_changed(value)` |
| `StatTracker` | `Commons/stat_tracker.gd` | Run-stats recorder: `time_survived`, `enemies_killed`, `energy_collected`, `level_reached`. Subscribes to GlobalSignals/UpgradeManager; freezes tracking on `game_over` (read by `game_over_screen.gd`). Persists best run to `user://records.cfg` (`best_time/best_level/...`, `last_run_new_record`); `format_time()` helper. Call `reset()` to start a new run. |
| `SettingsManager` | `Commons/settings_manager.gd` | Single source of truth for persistent settings (`user://settings.cfg`): audio volumes, `physics_ticks`, `post_processing`, `hidpi`, `reduce_effects`. Applies global settings on `_ready`; main menu & pause menu read/write via its setters. |

(`ImGuiRoot` is also registered as an autoload but belongs to the imgui-godot addon.)

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
            └── Ceres                 ← boss; state machine: WAIT → WINDUP → (SPAWN_ENEMIES | GAS) → WAIT (loops)

Player (extends RigidBody2D)          ← separate from CelestialBody hierarchy
```

`CelestialBody` tracks all live instances via the static `celestial_bodies: Array`.  
All `CelestialBody` nodes are in the Godot group `"celestialbodies"`; the player is in group `"player"`; energy drops in group `"energy"`.

### Key Systems

**Entropy** (`Commons/entropy_manager.gd`): The `entropy_value` float increases over time via a timer. When an enemy dies it decreases (negative values). Negative entropy applies exponentially-scaling oscillating + random forces to the player (`apply_entropy()` in `player.gd`). The player can discharge negative entropy with a shockwave (Space key).

**Upgrade/Progression** (`Commons/UpgradeManager.gd`): Enemies drop energy pickups → `UpgradeManager.gain_energy()` → on level-up, player grows (`change_size(1.25)`), `health_max *= 1.15`, `speed *= 1.25`, `acceleration *= 1.25`. The `max_energy` bar grows by `growth_factor = 1.2` each level. At tier thresholds `tiers = [3, 5, 10, 15, 20, 30, 40, 50]`, `tier_changed` fires and the upgrade menu appears with 3 random stat choices. Upgrades: `REGENERATION` (recharge speed of the layered health), `SPEED`, `ACCELERATION`, `MASS`, `MAX_ORBITS`, `MANTLE` (adds a shield layer — see Player Survival).

**Orbit System** (`small_body.gd` + `player.gd`): Hold right-click or Q to attract nearby `SmallBody` instances into orbit. Bodies cycle through `OrbitState.FREE → ATTRACTED → ORBITING`. When orbiting, `freeze = true` (kinematic freeze). `max_orbiting_bodies` limits simultaneous orbits (upgradeable). Only bodies with mass ratio `0.1–2.0× player mass` can be attracted (`orbit_mass_ratio_min/max`).

**Dynamic Spawner** (`Stages/World/celestial_bodies_spawner.gd`): Spawns objects in a rectangular "frame" around the player using Poisson-disc distribution. `GameStage` enum controls spawn weights (meteoroids early → asteroids/comets later); stage advances each `tier_changed`. Objects despawn when too far from the player.

**Mass & Physics**: `CelestialBody._setup_mass()` derives mass from collision shape size × density. Enemy damage to player is `mass × velocity × 0.0075 × mass_ratio`. Player damage to enemies is `mass × velocity × 0.5`. Player engulfs bodies at mass ratio ≥ 8× (calls `queue_free.call_deferred()`); "bulldozer mode" at ≥ 4×.

**Camera** (`Entities/Player/camera_2d.gd`, class `PlayerCamera`): Noise-based screen shake (`apply_shake(intensity, time)`). Auto-zoom based on player scale (recalculated on `tier_changed`). Manual scroll-wheel zoom with timeout to resume auto. Boss cam mode: when Ceres is on screen, the camera targets the midpoint between player and Ceres and zooms to fit both.

**Player Survival — layered health** (`player.gd`): The player's life is a stack of recharging bars. The innermost/last bar is the **health core** (`health`/`health_max`): subtractive damage, death at 0, scales `×1.15` per level-up. Outer bars are **shield layers** (`shield_layers: Array[float]`): each one **fully negates a single hit of any magnitude** (overflow discarded) then breaks with `LAYER_BREAK_IFRAME` invulnerability + feedback; capacity (`shield_layer_max`) only matters against sustained damage (gas). Shield layers are added by the **`MANTLE`** upgrade (repeatable, no cap), not automatically. Everything recharges from the inside out after `recharge_delay` seconds without damage (`recharge_rate`, tuned by the `REGENERATION` upgrade). Bars are generated at runtime into the `health_layers_container` (a VBox in `progress_bars.tscn`). One-time auto-revive on health core hitting 0 (`auto_revive`). Hitstop on kill: `Engine.time_scale = 0.08` briefly (`_do_hitstop()`).

**Unit Conversion** (`Commons/unit_converter.gd`): `UnitConverter` static class converts between AU, km, and pixels. Scale: 1 pixel = 100 km (`GAME_SCALE = 0.01`).

### Components (`Commons/Components/`)

Reusable nodes looked up via `get_node_or_null("%ComponentName")` (scene-unique names):

- `RotationComponent` — drives sprite visual rotation (independent of physics rotation); supports `windup()` and `freeze()` used by Ceres attacks
- `OutgassingComponent` — manages gas jet spawn points on Ceres; `prespawn()`, `activate_all()`, `stop()`
- `KickComponent` — applies impulse kick to a body

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

### Dead / WIP code (don't rely on it)

- `Commons/streaming_manager.gd` — entirely commented out; a never-finished body-streaming experiment.
- `Commons/GameState/game_state.gd` (`class_name GameState`) — a plain data holder that is not referenced anywhere yet.

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
- Most in-code comments are in Italian; this is intentional.
