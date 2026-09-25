# Collateral penalties and bankruptcy

Opponents receive the full propaganda award immediately, regardless of the
attacker's funds. Each recipient's propaganda servers add the existing 10% per
server bonus. Neither the attacker nor their allies receive a house-destruction
award. The extra house-destruction fine remains 5,000 money, in addition to
ordinary neutral-unit damage penalties.

A single base fine is charged to the offender, not separately to every ally or
once per enemy. Propaganda bonuses are additional income, not extra debt.
Collection runs every 10 simulation frames, outside damage/death callbacks:

1. Take as much money as available from the offender.
2. Collect the shortfall from allied teams, proportional to their available money.
3. Convert anything still unpaid into lost HP on the offender's military
   buildings, proportional to their current HP. Default: 1 money = 1 HP.

HP collection can destroy a building. Eligible structures are army bases, both
factions' assemblies, warhead factories, blacksites, Nimrods and launchers.
Construction sites count by their current HP. Civilian buildings, safehouses,
propaganda servers, intelligence buildings, mobile units and allied buildings
are excluded. In particular, the automatically recreated mobile-assembly helper
is not an unlimited pool of HP with which to erase debt.

Anything still unpaid remains in the allied-visible `collateral_debt` team rule
parameter. Later income, allied funds or new military construction will be
collected, including after a gadget reload. Collection never repeats an enemy
award. Failed resource deductions do not reduce the debt. Fines queued through
`GG.Bank` (such as interrogation/checkpoint penalties) use the same collector;
positive bank payments do not require a display marker.

Only attributed attacks are billable. Damage/death call-in team attribution is
used even when the attacking unit has died; anonymous damage and Gaia attacks
are not assigned to an arbitrary player. Foreclosed buildings have no combat
attacker, preventing a kill bounty or another collateral penalty.

Configuration: `luarules/configs/collateral.lua`.
Regression check from the repository root:

```sh
lua tests/collateral_collection_test.lua
```

The check executes the actual gadget and collector with mocked Spring APIs. It
covers payouts, allies, multiple opponents, partial balances, HP eligibility and
destruction, future collection, reloads, captured/recycled units, failed debits,
bank fines, and a 2,000-hit burst without repeated population scans. In-engine
verification remains necessary for presentation and building death effects.
