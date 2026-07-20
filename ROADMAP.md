# God Engine Roadmap

## Design Locked

- [x] Core fantasy: dieselpunk/steampunk post-apocalyptic giant robot artillery simulation.
- [x] MVP robot: single-pilot Light Scout Knight.
- [x] Prototype mode: single-player offline internal fun test.
- [x] Core loop: detect -> calculate -> fire -> correct -> survive -> return to base.
- [x] Combat pillars: manual long-range artillery and close-range melee.
- [x] Artillery: physical projectiles, manual azimuth/elevation, discrete charge levels 1-5.
- [x] Sensors: Knight radar first; sonar/audio direction later.
- [x] Defense: energy powers shield, boost, radar, and advanced weapon systems.
- [x] Shield: strong versus energy/high-speed fire, weak versus blast/heavy physical rounds, bypassed by melee.
- [x] Damage: simplified module hit zones for MVP, upgradeable later to deeper internals.
- [x] Base: rearm/repair/logistics zone; robot loadout changes only after destruction in PvP later.
- [x] Long-term PvP: objective-first War Thunder-like battles, 3 robot lineup, Titan as team asset.

## Prototype 1: One-Month Internal Fun Test

Goal: prove the Light Scout Knight artillery loop before networking, progression, Titans, and full faction systems.

- [x] Scaffold Godot 4.6 project.
- [x] Create runnable main scene.
- [x] Add third-person/cockpit switchable Knight controller.
- [x] Add dieselpunk placeholder Knight silhouette.
- [x] Add manual turret azimuth/elevation controls.
- [x] Add charge 1-5 artillery firing with physical projectile.
- [x] Add radar contacts with range/bearing/error/decay.
- [x] Add static target outside direct line-of-sight.
- [x] Add moving convoy target.
- [x] Add simple enemy Knight target.
- [x] Add base logistics zone for rearm/repair/energy.
- [x] Add energy drain for boost, shield, and radar pulse.
- [x] Add deploy/bracing mode that improves stability but restricts movement.
- [x] Add basic module-style damage feedback on targets.
- [x] Add tactical HUD/cockpit instrument overlay.
- [x] Validate project with Godot 4.6 headless using local Standard non-Mono `tools/godot-4.6.3-standard/Godot_v4.6.3-stable_linux.x86_64`.
- [x] Run automated playtest smoke pass: scene spawn, radar, artillery fire, melee, damage, outpost service, main base service.

## Prototype 2: Combat Pressure

- [x] Enemy Knight basic AI: patrol, investigate impact, direct-fire, close assault.
- [x] Melee arm strike with shield bypass and module damage.
- [x] Projectile trajectory detection for counter-battery radar.
- [x] Better recoil, heat, barrel wear, and misfire/jam states.
- [x] Sonar/audio direction display.
- [x] Add War Thunder Naval-inspired fire-control HUD with range ladder, traverse arc, weapon strip, module silhouette, and visual sensor scope.
- [x] Add mouse desired-aim control with per-hardpoint traverse limits and range-set fire-control.
- [x] Fix fire-control regressions: sensor bearing orientation, mouse-driven weapon elevation, barrel recoil feedback, and visible ballistic shell launch.
- [x] Outpost logistics zone with limited repair/rearm.

## Prototype 3: PvP Foundation

- [ ] Deterministic/server-authoritative projectile simulation plan.
- [ ] Objective capture mode.
- [ ] 3-robot lineup and respawn rules.
- [ ] Team spotting/contact sharing with decay.
- [ ] PvP brackets and loadout budget.
- [ ] Commander tactical map actions.

## Titan Roadmap

- [ ] Titan station model: commander, pilot, artillery, radar, loader, repair.
- [ ] AI crew task execution and skill ratings.
- [ ] Co-op role assignment only at base/staging area.
- [ ] Titan command points deployment rule.
- [ ] Titan module damage and logistics burden.


## HUD / Fire-Control Checklist

- [x] Reset aiming model to the intended War Thunder tank direction: removed floating AIM offset, mouse controls weapon angles directly, RMB sight follows actual barrel, and Q/E zeroing applies ballistic delta instead of overwriting manual elevation.
- [x] Fixed range dial fire-control: Q/E and charge changes now recompute desired elevation, barrel pitch follows the solution, and projectile speed matches the elevation calculation.
- [x] Phase 1 HUD orientation upgrade: vector-based heading telemetry, War Thunder-style top compass, hull/desired/actual aim markers, hardpoint arc limit display, radar/sonar direction labels, and smoke-test bearing validation.
- [x] Created `HUD_WARTHUNDER_CHECKLIST.md` from `warthunder_hud.md`: maps War Thunder Tank/Naval HUD ideas to current prototype, marks implemented/partial/missing items, and defines the next HUD improvement phases.

## Local Tooling

- [x] Added Godot 4.6.3 Standard non-Mono under `tools/godot-4.6.3-standard/` because the pre-existing Mono build in `~/Downloads` requires missing `.NET`/hostfxr.
- [x] Added reproducible smoke test at `tests/smoke_test.gd`.

Run validation:

```bash
tools/godot-4.6.3-standard/Godot_v4.6.3-stable_linux.x86_64 --headless --path . --import --quit
tools/godot-4.6.3-standard/Godot_v4.6.3-stable_linux.x86_64 --headless --path . --scene res://scenes/main.tscn --quit-after 120
tools/godot-4.6.3-standard/Godot_v4.6.3-stable_linux.x86_64 --headless --path . --script tests/smoke_test.gd
```
