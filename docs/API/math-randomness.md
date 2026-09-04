---
sidebar_position: 7
---

# Math & Randomness

## IsEven / IsOdd

```lua
Utils.IsEven(Number) -> boolean
Utils.IsOdd(Number) -> boolean
```

Parity checks. Zero is even.

## IsClose

```lua
Utils.IsClose(Number1, Number2, Tolerance) -> boolean
```

True when `|Number1 - Number2| <= Tolerance`.

## Sum / Average / Median

```lua
Utils.Sum(...) -> number
Utils.Average(...) -> number
Utils.Median(...) -> number
```

Varargs statistics. Average and Median return 0 when nothing is passed; Median averages the two middle values on even counts.

```lua
Utils.Sum(1, 2, 3)          -- 6
Utils.Average(2, 4, 6)      -- 4
Utils.Median(4, 1, 3, 2)    -- 2.5
```

## RandomChoice

```lua
Utils.RandomChoice(Table) -> any
```

A random value from a table.

## RandomFloat

```lua
Utils.RandomFloat(Min, Max, Decimals) -> number
```

A random float in `[Min, Max]`, rounded to `Decimals` places.

## RandomWeightedChoice

```lua
Utils.RandomWeightedChoice(Table) -> any, WeightedTable
```

Picks a random entry weighted by each entry's `Weight` field. Returns the key and the entry. Negative weights warn.

## RandomInt

```lua
Utils.RandomInt(Min, Max) -> number
```

A random integer in `[Min, Max]`, inclusive.

## RandomSeed

```lua
Utils.RandomSeed() -> number
```

A random integer in `[1, 2^31 - 1]`, usable directly as a seed.

## RandomColor

```lua
Utils.RandomColor() -> Color3
```

A fully random Color3.