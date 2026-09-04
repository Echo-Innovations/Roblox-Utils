---
sidebar_position: 2
---

# Installation

Two files inside the `Utils` folder: `Signal.luau` is split out for readability, not because it's separate:

```
Utils/
├── init.luau
└── Signal.luau
```

## Rojo

Run: `rojo serve utils.project.json`
This will put Utils into ReplicatedStorage, which can be modified in `utils.project.json`

Then require it from any script:

```lua
local Utils = require(ReplicatedStorage.Utils)
```

## By hand

If you're not using Rojo, create a `ModuleScript` named `Utils` inside `ReplicatedStorage`, set its `Source` to the contents of `Utils/init.luau`, and do the same for `Signal.luau` as a child named `Signal`. The require at the top of `init.luau` resolves the child automatically.

## Requirements

- Roblox Luau (any recent version)
- Nothing else

The module has no dependencies and creates no instances at require time.