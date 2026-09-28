# Double agents and counterintelligence

Only operatives issue **Investigate**, targeting another unit. Safehouses and
factories cannot investigate themselves. The command approaches the chosen unit,
then requires the operative to stay nearby. Progress appears on its command button.
There is no global paranoia/reveal action, automatic suspicion meter or third faction.

## Subversion and activation

The existing traps remain: building a safehouse in an enemy-occupied house
compromises the new safehouse; recruiting a disguised enemy can produce an
individually compromised civilian agent. Allied disguises are excluded.

A compromised safehouse or production hub has one handler-owned, cloaked marker.
Its **Turn network** command lists the affected living units and activates them
together. An individually compromised operative has **Turn agent**, affecting
only itself. Ordinary products never get additional markers. Decloaking is no
longer an activation mechanism, and damaging/deleting a marker cannot cure a network.

Production provenance is recorded from actual builder IDs, including products
made before compromise and surviving descendants whose intermediate recruiter
has died. Hub descendants form the network. Abstract effects and morph placeholders
are excluded. Only units still belonging to the compromised employer can be
hijacked; giving a unit to a third party does not let the old hub steal it.

The record follows explicit ownership replacements and factory morphs; ordinary
death removes the identity so recycled engine IDs cannot inherit its history.
Unit-limit failures leave the original intact and allow another activation attempt.
Unfinished products are excluded from activation; there is no later automatic flip.

Destroying a hub removes its mass-activation channel and marker. Surviving spokes
keep their present employer and their compromised history in a detached record;
the bombing itself does not expose them, issue orders, or start runners. There
is no automatic successor hub or extra marker. Operatives remain guilty
when investigated, factory backdoors can still be cleaned, and an already burned
network stays unable to build. A surviving compromised builder can pass on its
dormant backdoor, but cannot recreate the lost handler channel. The detached record
is discarded as its remaining members die or are secured, independently of ID reuse.

## Investigation outcomes

Initial tuning lives in `luarules/configs/counterintelligence.lua`:

| Target | Work and cost | Outcome |
| --- | --- | --- |
| Another own operative | 30 seconds, 300 money | A double agent becomes a betrayal runner seeking its real handler's side. A false accusation gives opposing live teams 500 money in total, divided equally. |
| Own safehouse | 30 seconds, 300 money | A discovered network loses its takeover ability and stops production. An innocent target stays unchanged. |
| Factory / Nimrod / production hub | 90 seconds, 2,000 money and 1,000 supply | Compromised machinery and its surviving products are secured. If already hijacked, the former owner can investigate it in LOS to restore the factory and its machinery. |

All own targets are valid independently of whether they are compromised; the
command cursor and initial cost never reveal guilt. Allied teammates' units and
arbitrary enemy units are not eligible. Nobody can investigate themselves.
Resource shortages, stun, transport and leaving range pause work. Death, ownership
change, a replacement or a new order cancels it. Work already performed is not refunded.

A human-network discovery silently disables its trigger and stops its production.
The handler receives no discovery notification or special status flag. Normal
events such as an exposed operative fleeing remain observable.
Sending the activation signal consumes it normally but transfers no units.
The defender's production-disabled rule is visible only to allies. Hubs are switched
off; build orders, assistance, carried-bomb manufacturing and morphing cannot bypass
the shutdown. Existing combat capability is retained. Exposed operatives use the
existing visible runner, rendezvous and dead-drop system.

Factory remediation restores manufacturing rather than permanently disabling it.
Secured machinery, including subsequent products, cannot inherit the same backdoor
again. Rekeying a morphed factory does **not** cure its historical human recruits:
that human remainder stays disabled and can still be investigated as double agents.
There is no automatic conversion into a crime syndicate. That would introduce new
combat, allegiance and police interactions beyond this counterintelligence loop.

## Implementation and validation

`game_counterintelligence.lua` owns the roster, marker lifecycle and investigations.
The old `attachDoubleAgentToUnit` function delegates to it. The retired Hivemind
reveal purchase is removed; an already-created legacy icon refunds its cost.

`lib_unit_replacement.lua` recreates scripts that cache their team, preserves
health/experience/orientation and transfers carried bomb stock and manufacturing
progress. It migrates hub/graph identity and discards the former employer's command
queue. Failed creation leaves the original alive. Normal deaths still detonate
carried bombs; switching sides and becoming a runner do not.

Run from the repository root with Lua 5.1+:

```
lua tests/counterintelligence_test.lua
lua tests/counterintelligence_helpers_test.lua
lua tests/betrayal_runners_test.lua
lua tests/betrayal_visibility_test.lua
lua tests/sticky_bombs_test.lua
```

The counterintelligence test exercises the real counterintelligence, betrayal and
bomb gadgets together. Live Recoil validation remains necessary: command placement,
approach around buildings, hidden markers from both player perspectives, factory
animations after reactivation, and the initial investigation timing/economy.
