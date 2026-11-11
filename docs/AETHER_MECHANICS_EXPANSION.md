# Echoes of Aether — Realm-specific puzzle expansion (post-v7)

## Scope and status
The six deterministic systems in `scripts/AetherMechanics.gd` are **implemented game-logic primitives, not yet wired into the live scene, touch HUD, quests, save file or APK**. `tests/test_aether_mechanics.gd` covers the rules. Test execution is pending; do not claim a playable feature or passing device test from this commit.

## Fits the game (different contexts, not 24 forced mechanics)
| Destination | Encounter | Actual player decision |
|---|---|---|
| Echo Labyrinth | 10-second ghost recording | Record a switch hold, then race to an exit while the shadow replays |
| Mirror Vault | Past / present lens | Cross the intact ancient bridge in the past, pass a collapsed wall in the present |
| Rootbound Crypt | Growth/decay | Grow a climbable vine; decay a rusty latch to reveal a secret path |
| Sunken Ruins | Sonar | Reveal hidden spikes and passages for 3.5 seconds in darkness |
| Gale Spire | Listen and repeat | Hear an original four-tone chime phrase, then play matching bells |
| Aether Nexus | Glyph dictionary | Discover glyph translations in lore; decode an optional sealed inscription |
| Tidal Control Vault | Counterweights | Place distinct weights on two pans and match a target mass |
| Shadowfen | Stealth lure | Distract a patrol with tossed pebbles to reach a secret chest |
| Emberfall | Artifact heist | Swap the forge seal with a forged decoy without triggering alarm |
| Moonhaven | Restoration | Repair a bridge or workshop to unlock a route and a town interaction |

Existing v6 mural/circuit/number/memory puzzles remain working and untouched.

## Integration acceptance criteria
1. Add world-space interactable entities with actual sprite collision and visible feedback; do not present these as generic modal puzzles.
2. Gate each puzzle behind a reachable optional room, NPC clue or exploratory landmark; preserve optional exits.
3. Bind mobile controls to context actions without disrupting customized button positions.
4. One-time quest completion and rewards use existing `trial_completed` / `record_quest_event` patterns; save new per-puzzle flags using default-safe keys.
5. Ghost snapshots are sampled at 10 Hz, duration 10 seconds; clones must never interact outside their originating dungeon. Record x/y and switch state; player must be at exit while replay holds switch.
6. Past/present geometry uses distinct collision layers, updated atomically; no character trapping on phase switches.
7. Sonar shows real hazards and secrets only for its reveal window. Chime puzzle requires hearing-independent visual pattern as an accessibility fallback.
8. Cipher clues allow gradual learning, while counterweights use distinct movable object masses.
9. Investigations, restoration and choice quests get authored dialogues, world consequences and explicit save flags, never a generic fetch-quest replacement.
10. Run Godot headless script tests, existing v7 regression suite, APK export, inspect screenshots and perform on-device input and collision testing. Report pass/fail/not tested separately.

## Deliberately not forced into v8
Size shifting, possession, faction disguise, moral dilemmas and full dynamic seasons require new animation, collision, quest branching and art. They should be introduced only where they strengthen an authored region, not sprayed across all maps.

## Standalone test command
`godot --headless --path . --script res://tests/test_aether_mechanics.gd`
