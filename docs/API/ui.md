---
sidebar_position: 13
---

# UI

## NewContrastWipe

```lua
Utils.NewContrastWipe(Background, Content, TweenInfo, RevealedColor?, StartDirection?) -> ContrastWipe
```

A two-color wipe driven by UIGradients. The background sweeps from its own color to the revealed color while a duplicate of the content sits on top with the opposite gradient: so the content always shows the color that contrasts its side of the wipe. No clips, no positioning math, nothing moves except gradient offsets.

```lua
local Wipe = Utils.NewContrastWipe(BlackFrame, WhiteLabel, "WipeInfo")
Wipe:Play()
```

`StartDirection` takes `"Left"`, `"Right"` (default), `"Up"`, `"Down"`, or any angle in degrees (e.g. `127`).

The returned control object:

- `Play()`: runs the wipe, restartable
- `Pause()` / `Resume()`: stop and continue
- `Cancel()`: stop and reset
- `Wait()`: yields until the wipe finishes
- `OnFinished`: a signal that fires on completion

`TweenInfo` can be a raw `TweenInfo` or a name from `Utils.TweenInfos` (see below).

## NewTweenInfo

```lua
Utils.NewTweenInfo(Name, Time, EasingStyle, EasingDirection, RepeatCount, Reverses) -> TweenInfo
```

Creates a `TweenInfo`, stores it in `Utils.TweenInfos` under `Name`, and returns it. Reuse the same info for synced tweens.

```lua
local WipeInfo = Utils.NewTweenInfo("Wipe", 5, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false)
```