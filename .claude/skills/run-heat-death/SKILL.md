---
name: run-heat-death
description: Run, launch, validate, or screenshot the Heat Death Godot game. Use when asked to start/run/play the game, check it for script or scene errors, capture a screenshot of the menu or gameplay, or verify a change works in the real running app.
---

# Run Heat Death

Heat Death is a Godot 4.7 top-down space game (Windows). It is driven by a
PowerShell harness, **`.claude/skills/run-heat-death/driver.ps1`**, which runs
the real game on the Windows desktop with the Steam Godot binary. The driver has
three jobs:

- `validate` — headless run, scans output for GDScript/scene errors (no display needed)
- `screenshot` — launches the game windowed and captures the **main menu** to a PNG
- `play` — launches, clicks **Start**, and captures **live gameplay** to a PNG

All paths below are relative to the project root
(`D:\app-games\Gioco\project-heat_death`). The driver finds the project and the
Godot binary itself.

## Prerequisites

- Godot 4.7 Steam editor binary. The driver auto-detects
  `D:\app-games\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`;
  edit `Find-Godot` in `driver.ps1` if yours is elsewhere. (`git` is not on PATH —
  irrelevant to running, but don't reach for it here.)
- `screenshot` and `play` need an **interactive desktop session** (they capture
  real pixels). `validate` runs fine headless.

## Run (agent path) — use the driver

Check the project for script/scene errors (exit 1 on any error, exit 0 if clean):

```powershell
powershell -ExecutionPolicy Bypass -File '.\.claude\skills\run-heat-death\driver.ps1' validate -Seconds 8
```

Capture the main menu to a PNG (always pass `-Out` to a temp path so you don't
litter the repo root):

```powershell
powershell -ExecutionPolicy Bypass -File '.\.claude\skills\run-heat-death\driver.ps1' screenshot -Out "$env:TEMP\hd_menu.png" -Seconds 6
```

Click Start and capture live gameplay (player orb, survival timer, health bar,
ImGui debug panel):

```powershell
powershell -ExecutionPolicy Bypass -File '.\.claude\skills\run-heat-death\driver.ps1' play -Out "$env:TEMP\hd_gameplay.png" -Seconds 5
```

Each command launches Godot, does its job, then **kills the process** — they do
not leave a window open. After capturing, open the PNG and actually look at it;
a blank or menu-only image when you expected gameplay means the click missed
(see Gotchas).

## Run (human path)

Plain windowed launch, blocks until the window is closed — useless for an agent,
fine for a person eyeballing the game:

```powershell
powershell -ExecutionPolicy Bypass -File '.\.claude\skills\run-heat-death\driver.ps1' launch
```

Equivalent to opening the project in Godot and pressing F5. F5 in the editor is
still the right tool for actually *playing* (input, sound, feel).

## Gotchas

- **Godot launches *behind* the active terminal.** Windows blocks
  `SetForegroundWindow` from a background process, so a naive screen-grab
  captures your terminal, not the game. The driver works around this with the
  `AttachThreadInput` foreground trick (`Win32Rect.Force`) — this is the whole
  reason the harness exists rather than a one-line `CopyFromScreen`.
- **`play` re-asserts foreground right before clicking.** During the settle
  wait, Godot loses focus back to the parent shell; without a second `Force()`
  the click lands on a stale window and you stay on the menu. It also clicks
  twice (the first click on a just-activated window can be swallowed as an
  activation click).
- **The Start-button click is positional** (~50% width, ~48% height of the
  window). If the menu layout changes, update `$cx`/`$cy` in `Invoke-Play`.
- **`validate` scans output, not the exit code.** Godot returns exit 0 even when
  a script throws at runtime, so the driver greps stdout/stderr for `SCRIPT
  ERROR`, `Parse Error`, `Node not found`, etc. `-Seconds N` controls how long it
  runs (converted to `--quit-after N*60` frames).
- **In-game ImGui debug panel** ("Pannello Controllo") exposes *Fai Level UP* and
  *Vai su di tier* buttons — handy for jumping the player to a tier/upgrade state
  without grinding, if you script clicks into the gameplay area.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Screenshot shows the terminal/editor, not the game | Foreground wasn't forced. The driver handles this via `Win32Rect.Force`; if you bypass the driver, replicate the `AttachThreadInput` trick. |
| `play` screenshot still shows the menu | Click missed. Confirm the window didn't move; adjust `$cx`/`$cy` fractions in `Invoke-Play`. The double-click + pre-click `Force()` normally fixes it. |
| `Godot binary not found` | Edit `Find-Godot` in `driver.ps1` with your Godot 4.7 path. |
| `validate` reports errors | Read the printed lines — they're the actual Godot error output (file:line). |
