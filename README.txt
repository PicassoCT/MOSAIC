MOSAIC external regression suite

All test sources and fixtures live here, outside the game checkout.
This independent checkout is published on the mosaic-tests branch of the MOSAIC
repository. Do not merge that branch into the game branch.

Run the focused terrain/prop/audio smoke tests:
  ./run.sh
Run another test:
  ./run.sh -- lua tests/city_roads_test.lua
Run the house assembly suite using an installed Lupa environment:
  ./run.sh -- /path/to/python tests/house_asian_stacks_runtime_test.py
Choose another game checkout:
  ./run.sh --game /path/to/Mosaic.sdd -- python3 -m unittest discover -s tests -p test_windows_release.py

The runner creates a temporary workspace OUTSIDE the game folder, copies the
small test suite there and links the game files. Existing relative paths,
fixtures, Python __file__ roots and Lua dofile imports continue to work.
Only the owned temporary workspace is removed after the test command ends.
Individual tests retain their existing Lua/Python/OpenGL/tool requirements.
No-argument execution is a focused smoke check, not a claim that every test ran.

To inspect or reuse a workspace, supply --workspace /path/to/new-directory.
It must not exist and must be outside both the game and test source directories.
Windows uses directory junctions and hard links if symlinks are unavailable.

GitHub workflows fetch the exact suite commit pinned in
.github/mosaic-tests.ref in the GAME repository, using its external-tests action.
After updating this suite: commit/push mosaic-tests, then update that pin in the
relevant game branch. This preserves reproducible checks and keeps the test
sources out of the playable checkout. Game/test branches are never force-pushed.

relocation-manifest.json records the hashes of all 234 files moved on 2026-11-08,
including uncommitted assembly/stack-test edits. The three earlier external
terrain, placeable and missing-audio tests are retained alongside them.
Original test history remains in the game repository's history before relocation.
