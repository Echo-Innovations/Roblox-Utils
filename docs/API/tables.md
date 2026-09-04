---
sidebar_position: 4
---

# Tables

## DeepCopy

```lua
Utils.DeepCopy(Table, SkipJSON?)
```

Creates a deep copy, including nested tables. Tries a JSON roundtrip first (fast), falls back to a recursive copy when the data isn't serializable. Pass `SkipJSON` to force the recursive path.

```lua
local Copy = Utils.DeepCopy(Config) -- independent of Config
```

## DeepDiff

```lua
Utils.DeepDiff(Table1, Table2) -> { [any]: any }
```

Returns the differences as `Key = {Table1Value, Table2Value}` pairs. Nested tables diff recursively. Keys only in `Table2` appear as `{nil, Table2Value}`.

## DeepEqual

```lua
Utils.DeepEqual(Table1, Table2, SkipJSON?)
```

True when the tables are deeply equal. JSON fast path, then `DeepDiff`: equal means the diff comes back empty.

## Patch

```lua
Utils.Patch(Table, Diff) -> Table
```

Applies a `DeepDiff` result in place. Value pairs write or remove keys; nested sub-diffs recurse. After `Patch(Table, DeepDiff(Table, Target))`, `Table` equals `Target`.

## Shuffle

```lua
Utils.Shuffle(Table, Recursive?)
```

Shuffles in place and returns the table.

## Pick / Omit

```lua
Utils.Pick(Table, Keys) -- only the given keys
Utils.Omit(Table, Keys) -- everything except the given keys
```

Both return new tables.

## Unique

```lua
Utils.Unique(Table, Recursive?)
```

A new list of unique values. Primitives dedupe through a set; tables compare by reference.

## Merge

```lua
Utils.Merge(Table1, Table2, Recursive?)
```

`Table2` merged into a copy of `Table1`; `Table2` wins on duplicate keys.

## Filter

```lua
Utils.Filter(Table, FilterFunction, Recursive?)
```

New table with only the values for which the filter returns true.

## Keys / Values

```lua
Utils.Keys(Table, Recursive?) -> { any }
Utils.Values(Table, Recursive?) -> { any }
```

Lists of keys or values, optionally recursed.

## IsEmpty / Contains

```lua
Utils.IsEmpty(Table) -> boolean
Utils.Contains(Table, Value) -> boolean
```

No keys / any entry equal to `Value`.

## GroupBy

```lua
Utils.GroupBy(Table, KeyFunction) -> { [any]: GenericTable }
```

Buckets entries by the key `KeyFunction(Value, Key)` returns; groups keep the original keys.

```lua
local ByParity = Utils.GroupBy({ a = 1, b = 2, c = 3 }, function(V) return V % 2 end)
-- { [1] = { a = 1, c = 3 }, [0] = { b = 2 } }
```

## Flatten

```lua
Utils.Flatten(Table) -> { any }
```

One flat list of every non-table value, recursing through nested tables.

```lua
Utils.Flatten({1, {2, 3}, {4, {5}}}) -- {1, 2, 3, 4, 5}
```

## Observer

```lua
Utils.Observer(Table?) -> ObservedTable
```

A proxy table that fires signals on writes. See [Getting Started](../getting-started) for usage.

- `OnChanged`: fires `(Key, NewValue, OldValue)` on any write
- `OnKeyChanged(Key)`: per-key signal, fires `(NewValue, OldValue)`
- `OnDestroy`: fires when destroyed
- `Destroy()`: detaches the proxy; data stays in the backing table

## CreateTableWithDefault

```lua
Utils.CreateTableWithDefault(Default, Table?) -> TableWithDefault
```

Missing keys return `Default` instead of nil. If `Default` is a function it's called with the key. Management functions: `SetDefault`, `GetDefault`, `AddDefault(Key, Value)`, `RemoveDefault(Key)`, `Destroy`.

```lua
local Stats = Utils.CreateTableWithDefault(0)
print(Stats.Kills) -- 0
```

## Computed

```lua
Utils.Computed(Dependencies, Compute) -> ComputedValue
```

A value that recomputes when its dependencies change. Dependencies can be signals, observed tables, other computeds, or a list of them.

- `Value`: the current result
- `OnRecompute`: fires `(NewValue)` on every recompute
- `OnChanged`: fires `(NewValue, OldValue)` only when the value actually changed (fires once on creation)
- `OnDestroy`: fires with the last value
- `Destroy()`: disconnects dependencies and returns the last value

## Enum

```lua
Utils.Enum(Name, Values) -> EnumTable
```

A strict, read-only constant table. Reading an unknown key or writing anything errors. Stored in `Utils.Enums`.

```lua
local Mode = Utils.Enum("Mode", { Easy = 1, Hard = 2 })
print(Mode.Easy)    -- 1
print(Mode.Normal)  -- errors
Mode.Easy = 3       -- errors
```