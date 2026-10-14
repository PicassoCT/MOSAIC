# Optional building fire and tank muzzle diagnostics

Production tracing from `cf2e2f04bdc4d9369b0eb0adda63b2030d9ad5fd`
(`debug: trace building fire and tank muzzle delivery`) is removed from master.
The instrumented snapshot and its reuse instructions are retained on:

- Branch: `debug/building-fire-tank-muzzle-tracing`
- Archive head: `8004b41973bde9abf63a4b6e985619088ec54ccd`
- Guide on that branch: `DEBUG-INSTRUMENTATION.md`
- Detailed stage guide on that branch: `docs/building-effects-tracing.md`

```sh
git fetch origin
git show origin/debug/building-fire-tank-muzzle-tracing:DEBUG-INSTRUMENTATION.md
```

This is a historical diagnostic archive, not a feature branch to merge wholesale.
Do not delete it as an already-merged branch. Future coding assistants should
read the archive guide and inspect the current runtime before reapplying traces.
Use a fresh debugging branch from current master and explicitly reapply the
instrumentation or revert its removal. Preserve subsequent gameplay and effects
changes when resolving conflicts; do not restore entire old runtime files.

In particular, keep the configured damage threshold, retained block geometry,
facade flame placement, finite effect lifetimes, and client-side expiry/fading.
The frame argument passed to `lightBlockFire` now controls actual lifetimes and
must remain even with tracing removed. Ordinary error reporting and the manual
validation commands are unaffected. Traces have allocation and bookkeeping costs
in addition to log output, so keep diagnostic commits separate from fixes.

The archive's original stage guide contains historical numerical examples; it
is not an instruction to reset current dimensions, thresholds, or timings.
