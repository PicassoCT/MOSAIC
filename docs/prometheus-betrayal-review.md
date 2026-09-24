# Prometheus review alongside the betrayal repair

## Repaired

- Difficulty was assigned outside `gadget`, while managers read `gadget.difficulty`.
- Managers expected waypoint, neural-network and intelligence tables on `gadget`; startup only initialized globals. References now stay aligned when managers are created.
- The synced economy callback iterated an unavailable `team` table. It now uses the framework's actual AI-team roster. Economy cheats remain as configured previously.
- Startup no longer depends on receiving one exact game frame, does not treat incomplete units as finished, and propagates the framework's no-AI exit result.
- Lifecycle forwarding was empty. The framework now forwards named events through namespaced sync actions, and removes the actions on shutdown.
- Invalid command packets could be retried forever. Whole batches are validated before execution, malformed packets are discarded, sender leadership and current unit ownership are checked, and serialization handles integer bytes and bounded batches.
- Repeated LOS/damage events duplicated enemies. Removing an enemy shifted the list without updating its ID index. The index now stays consistent, with LOS events filtered by the AI's allyteam.
- Combat targeting compared unit IDs with team IDs, allowing friendly/allied/neutral units into the enemy list. It now compares actual team ownership and alliances. Combat orders use the same command queue.
- A runner is exempt from AI orders while fleeing. The AI sends an available mobile operative to meet a friendly runner and reserves that receiver so construction/combat managers do not overwrite the rendezvous order.

## Validation and limits

`tests/prometheus_betrayal_test.lua` checks packet round trips, rejected senders, truncation, stale ownership, runner protection, event forwarding, enemy-index removal, private LOS, field rendezvous and friendly target exclusion.

`tests/prometheus_startup_test.lua` checks synced/unsynced startup, manager wiring, difficulty, delayed initial frames, incomplete units and no-AI matches.

These are focused mocked-engine regressions, not a full AI-versus-AI match. This pass does not rebalance the neural-network scoring, construction plans, the existing hard-difficulty information advantage, or waypoint strategy. Prometheus still needs a complete in-game opening/midgame test and observation of a runner rendezvous on actual city terrain.
