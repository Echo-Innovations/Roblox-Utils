---
sidebar_position: 10
---

# Value

## Coalesce

```lua
Utils.Coalesce(...) -> any
```

The first non-nil argument.

```lua
Utils.Coalesce(nil, nil, 3) -- 3
```

## Default

```lua
Utils.Default(Value, DefaultValue) -> any
```

`Value` unless it's nil. `false` and `0` pass through: only nil triggers the default.

## Fallback

```lua
Utils.Fallback(Value, Fallbacks) -> any
```

`Value` unless nil, otherwise the first non-nil entry in `Fallbacks`.

```lua
Utils.Fallback(nil, { nil, "x" }) -- "x"
```

## Negate

```lua
Utils.Negate(Value) -> any
```

Inverts by type: booleans flip, numbers change sign, strings reverse, tables negate their values recursively. Anything else returns nil. Cyclic tables are not supported.

## Toggle

```lua
Utils.Toggle(Value) -> boolean
```

Returns the opposite of the given boolean.

```lua
Utils.Toggle(true)  -- false
Utils.Toggle(false) -- true
```