---
sidebar_position: 1
---

# Roblox Utils

A collection of Luau utilities for Roblox.

```lua
local Utils = require(ReplicatedStorage.Utils)
```

Everything lives on the `Utils` table. No nested requires. If you're on `--!strict`, exported types are available too (`Utils.GenericTable`, `Utils.Signal`, ...).

- **No instances.** Nothing creates BindableEvents; signals are plain tables.
- **Typed.** Every function has a signature; the module typechecks clean under `--!strict`.
- `Signal.luau` is split into its own file purely for readability: it's part of the module, not a dependency.

## Sections

- [Tables](/docs/API/tables): deep copy/diff/equal/patch, pick/omit, grouping, observers, computed values, enums
- [Signals](/docs/API/signals): event objects with unique Ids and a global registry
- [Strings](/docs/API/strings): trimming, casing, padding, wrapping
- [Math & randomness](/docs/API/math-randomness): parity, stats, weighted choice, seeds
- [Time](/docs/API/time): timestamp formatting, countdowns, unit conversion
- [Instances](/docs/API/instances): reflection-based property/attribute helpers
- [Value](/docs/API/value): coalescing, defaults, negation
- [Functions](/docs/API/functions): once, memoize, throttle, retry, timers
- [Color](/docs/API/color): inversion, brightness, contrast, palettes
- [UI](/docs/API/ui): the contrast wipe