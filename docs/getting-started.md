---
sidebar_position: 3
---

# Getting Started

The everyday stuff first.

## Requiring

```lua
local Utils = require(ReplicatedStorage.Utils)
```

Everything is on the `Utils` table. Nothing to build, nothing to configure.

## Diffing and syncing tables

```lua
local Diff = Utils.DeepDiff(OldState, NewState)
Utils.Patch(OldState, Diff) -- OldState now equals NewState
```

`DeepDiff` produces `Key = {OldValue, NewValue}` changes; `DeepEqual` just asks whether two tables are equal; `Patch` applies a diff back.

## Copying and finding things

```lua
local Copy = Utils.DeepCopy(Config)                       -- independent clone
local AllButtons = Utils.GetDescendantsOfClass(ScreenGui, "TextButton")
local ByParity = Utils.GroupBy({ a = 1, b = 2, c = 3 }, function(V) return V % 2 end)
```

## Formatting time

```lua
Utils.FormatTime(os.time())              -- "26-09-02 14:30:45"
Utils.FormatRelativeTime(os.time() - 60) -- "1 minute ago"
Utils.FormatCountdown(3725)              -- "01:02:05"
```

All three take formats: presets (`Clock`, `MMSS`, `Short`, `Long`) or custom templates.

## Also available

- **Signals**: `NewSignal` / `Connect` / `FireSignal`, with a global registry in `Utils.Signals`
- **Function helpers**: `Once`, `Memoize`, `Throttle`, `Retry`, timers via `Interval`
- **Metatable helpers**: `Observer` (write-tracking tables), `Computed` (derived values), `Enum` (read-only constants). Handy, but not the main course

Read the [API reference](/docs/API/tables) for the full list.