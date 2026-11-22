# Steal a vehicle

Build the **Steal Vehicle** icon beside a civilian road vehicle using an operative. Once construction completes, the animated hologram searches its recruitment radius for a Gaia vehicle. The icon expires after 15 seconds if no eligible car is found.

Capture transfers the original vehicle and its attached visual cargo. It preserves the chosen body, decorations, payload variant, health, and load-dependent driving profile. Neither the vehicle nor its payload is recreated. Ownership transfer runs in a deferred game-frame callback, and boarding is attempted on the following frame where the vehicle supports it. A full vehicle keeps its cargo and leaves the operative outside and selectable.

There is no custom Steal Car command. Starting icon construction releases a hostage, like other building activity.
