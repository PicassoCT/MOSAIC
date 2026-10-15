# Radiance debug lamp

The neutral unit `radiancedebuglamp` is a deliberately simple articulated desk-lamp
fixture for validating MOSAIC's dynamic radiance and mobile-shadow path.

Spawn it with:

```
/give radiancedebuglamp
```

The lamp stays in place, periodically hops, and looks around. Its `bulb` model
piece is tracked every draw frame by the ordinary combat-light source collector.
The source cycles continuously through the full hue wheel, is visible during the
day, and carries its owning unit ID into the same height-aware mobile shadow
renderer used by police lights and tank muzzle flashes.

Useful checks:

```
/radiancelight on
/radiancelight shadows on
/radiancelight shadows stats
```

Place the lamp beside cars, pedestrians, walls and building corners. The moving
bulb should move the shadow origin while the color changes without changing the
shadow geometry. The lamp has no gameplay weapon or movement behavior; its hop is
piece animation only.
