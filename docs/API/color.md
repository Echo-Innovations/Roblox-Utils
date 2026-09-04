---
sidebar_position: 12
---

# Color

## InvertColor

```lua
Utils.InvertColor(Color) -> Color3
```

Each channel subtracted from 1.

## GrayscaleColor

```lua
Utils.GrayscaleColor(Color) -> Color3
```

The average of the channels applied to all three.

## LightenColor / DarkenColor

```lua
Utils.LightenColor(Color, Factor) -> Color3
Utils.DarkenColor(Color, Factor) -> Color3
```

Channels clamped-shifted by `Factor`. `Factor` can exceed the visible range; clamping handles it.

## GetColorBrightness

```lua
Utils.GetColorBrightness(Color) -> number
```

Perceived brightness in 0..1, using the standard 0.299/0.587/0.114 weights.

## GetContrastColor

```lua
Utils.GetContrastColor(Color) -> Color3
```

Black or white, whichever contrasts `Color` more. Uses the classic 186/255 threshold.

```lua
Utils.GetContrastColor(Color3.new(0.1, 0.1, 0.1)) -- white
Utils.GetContrastColor(Color3.new(0.9, 0.9, 0.9)) -- black
```

## NewColorPalette

```lua
Utils.NewColorPalette(Name, Primary, Accent, Secondary, Complementary, Background?, Text?) -> ColorPalette
```

Builds a `ColorPalette` table, stores it in `Utils.ColorPalettes`, and returns it.

```lua
local Palette = Utils.NewColorPalette("Hud", Blue, Red, Green, Yellow)
print(Palette.PrimaryColor) -- Blue
```