# Roblox Utils

A collection of Luau utilities for Roblox. Drop the Utils folder wherever you want and require.

```lua
local Utils = require(Path.to.Utils)
```

The module is `Utils/init.luau`; `Signal.luau` sits beside it - split into its own file purely for readability, not because it's a dependency. Everything is exported on the `Utils` table - no nested requires, no setup. There are exported types too (`Utils.GenericTable`, `Utils.Signal`, ...) if you're on `--!strict`.

## API Reference

### Tables

- `Utils.DeepCopy(Table, SkipJSON?)` - deep copy; JSON roundtrip first, recursive fallback. `SkipJSON` forces the fallback.
- `Utils.DeepDiff(Table1, Table2)` - returns `{ Key = {Table1Value, Table2Value} }` differences; nested tables recurse.
- `Utils.DeepEqual(Table1, Table2, SkipJSON?)` - true if deeply equal (JSON fast path, DeepDiff fallback).
- `Utils.Patch(Table, Diff)` - applies a `DeepDiff` result in place; the inverse of DeepDiff.
- `Utils.Shuffle(Table, Recursive?)` - shuffles in place and returns the table.
- `Utils.Pick(Table, Keys)` - new table with only the given keys.
- `Utils.Omit(Table, Keys)` - new table without the given keys.
- `Utils.Unique(Table, Recursive?)` - new list of unique values (primitives via set, tables by reference).
- `Utils.Merge(Table1, Table2, Recursive?)` - Table2 into a copy of Table1; Table2 wins.
- `Utils.Filter(Table, FilterFunction, Recursive?)` - new table with only passing values.
- `Utils.Keys(Table, Recursive?)` / `Utils.Values(Table, Recursive?)` - list of keys / values.
- `Utils.IsEmpty(Table)` - true if the table has no keys.
- `Utils.Contains(Table, Value)` - true if any entry equals Value.
- `Utils.GroupBy(Table, KeyFunction)` - buckets entries by the key `KeyFunction(Value, Key)` returns.
- `Utils.Flatten(Table)` - one flat list of all non-table values, recursing nested tables.
- `Utils.Observer(Table?)` - proxy table; writes fire `OnChanged` / `OnKeyChanged(Key)` signals. `Destroy()` detaches.
- `Utils.CreateTableWithDefault(Default, Table?)` - missing keys return Default (or `Default(Key)` if it's a function); `SetDefault`/`GetDefault`/`AddDefault`/`RemoveDefault`/`Destroy`.
- `Utils.Computed(Dependencies, Compute)` - reactive value; recomputes when any dependency (signal, observer, or computed) changes. `Value`, `OnRecompute`, `OnChanged`, `OnDestroy`, `Destroy()`.
- `Utils.Enum(Name, Values)` - strict read-only constants; unknown reads and writes error. Stored in `Utils.Enums`.

### Signals

- `Utils.NewSignal()` - creates a signal with a unique Id, registered in `Utils.Signals`.
- `Utils.Connect(Signal, Listener)` - returns a connection object.
- `Utils.Disconnect(Connection)` / `Utils.DisconnectAll()` - disconnect one / everything.
- `Utils.FireSignal(Signal, ...)` - runs listeners on a recycled thread.
- `Utils.Wait(Signal)` - yields until the next fire, returns its arguments.
- `Utils.GetListenerCount(Signal)` - connected listener count.

### Strings

- `Utils.Trim(String)` / `Utils.Strip(String)` - remove leading/trailing whitespace.
- `Utils.Capitalize(String)` - first letter upper, rest lower.
- `Utils.StartsWith(String, Substring)` / `Utils.EndsWith(String, Substring)` - prefix/suffix checks (empty substring matches).
- `Utils.Join(Separator, Strings, ...)` - concat with a separator.
- `Utils.Prefix(String, Prefix)` / `Utils.Suffix(String, Suffix)` - prepend / append.
- `Utils.PadLeft(String, Length, Padding)` / `Utils.PadRight(String, Length, Padding)` - repeat-pad one side.
- `Utils.Truncate(String, Length, Prefix?)` - cut to Length, appending Prefix only when cut.
- `Utils.Wrap(String, Width)` - word-wrap into lines; over-long words are hard-cut.

### Math & randomness

- `Utils.IsEven(Number)` / `Utils.IsOdd(Number)` - parity.
- `Utils.IsClose(Number1, Number2, Tolerance)` - |a − b| <= Tolerance.
- `Utils.Sum(...)` / `Utils.Average(...)` / `Utils.Median(...)` - varargs stats (empty Average/Median → 0).
- `Utils.RandomChoice(Table)` - random value.
- `Utils.RandomFloat(Min, Max, Decimals)` - random float rounded to Decimals.
- `Utils.RandomWeightedChoice(Table)` - random key/value by each entry's `Weight`.
- `Utils.RandomInt(Min, Max)` - random integer, inclusive.
- `Utils.RandomSeed()` - random integer seed (1..2^31-1).
- `Utils.RandomColor()` - random Color3.

### Time

- `Utils.FormatTime(Timestamp, Format?)` - unix timestamp as date/time. Presets: `DateTime` (default), `Date`, `Clock`, `Short`, `Long`; custom templates use `{y} {mo} {d} {h} {m} {s}`, padded `{yy} {dd} {hh} {mm} {ss}`, and word tokens `{Month} {Mon} {Day}`.
- `Utils.FormatRelativeTime(Timestamp, Short?, Format?)` - "5 minutes ago" / "in 2 days and 13 hours" vs now.
- `Utils.FormatCountdown(Seconds, Format?)` - duration countdown. Presets: `Clock` (hh:mm:ss), `MMSS` (total minutes), `Short`, `Long`; same template tokens.
- `Utils.TimeDifference(Timestamp)` - signed seconds between now and the timestamp (negative = past).
- `Utils.ToMilliseconds/ToSeconds/ToMinutes/ToHours/ToDays/ToWeeks/ToMonths/ToYears(Time, Unit)` - convert a value from the given Unit name.

### Instances

- `Utils.GetChildrenOfClass(Instance, ClassName)` / `Utils.GetDescendantsOfClass(Instance, ClassName)` - filtered children/descendants.
- `Utils.GetAttributes(Instance)` - table of attributes.
- `Utils.GetProperties(Instance)` - readable, Basic-security value properties (via ReflectionService, cached per class).
- `Utils.SetAttributes(Instance, Attributes)` - set many attributes.
- `Utils.CopyAttributes(Source, Target)` / `Utils.CopyProperties(Source, Target)` - copy attributes / writable properties (skips read-only and Parent).
- `Utils.AttributeDiff(Instance, Comparison)` / `Utils.PropertyDiff(Instance, Comparison?)` - attribute/property differences (vs another instance, a table, or defaults).
- `Utils.HasAttribute(Instance, Name)` / `Utils.HasProperty(Instance, Name)` - existence checks.

### Value

- `Utils.Coalesce(...)` - first non-nil argument.
- `Utils.Default(Value, DefaultValue)` - Value unless nil.
- `Utils.Fallback(Value, Fallbacks)` - Value unless nil, else first non-nil fallback.
- `Utils.Negate(Value)` - inverted boolean / negated number / reversed string / negated table.
- `Utils.Toggle(Value)` - `not Value`.

### Functions

- `Utils.Once(Function)` - runs once, ignores later calls.
- `Utils.Memoize(Function)` - caches by value-keyed arguments (deep table compare; function arguments are computed unless memoized).
- `Utils.Throttle(Function, Delay, InitialDelay?)` - at most one call per Delay seconds.
- `Utils.Debounce(Function)` - calls only when the previous call has finished.
- `Utils.Backoff(Function, Delay, CallLimit?, InitialDelay?)` - re-schedules with `Delay()` or `Delay * InitialDelay`; live `CallCount`.
- `Utils.Retry(Function, Attempts, Delay?, ...)` - retries on error; returns first success or `nil, Error`.
- `Utils.Interval(Seconds, Function?, LoopCount?)` - repeating timer with `Start`/`Stop`/`Reset` and `OnStart`/`OnStop`/`OnReset`/`OnAdvance`/`OnLooped`.

### Color

- `Utils.InvertColor(Color)` - 1 − each channel.
- `Utils.GrayscaleColor(Color)` - average of channels.
- `Utils.LightenColor(Color, Factor)` / `Utils.DarkenColor(Color, Factor)` - clamp-shift channels.
- `Utils.GetColorBrightness(Color)` - perceived brightness (0..1).
- `Utils.GetContrastColor(Color)` - black or white, whichever contrasts more.
- `Utils.NewColorPalette(Name, Primary, Accent, Secondary, Complementary, Background?, Text?)` - stores a palette in `Utils.ColorPalettes`.

### Tween

- `Utils.NewTweenInfo(Name, Time, EasingStyle, EasingDirection, RepeatCount, Reverses)` - creates and stores a TweenInfo in `Utils.TweenInfos`.

### UI

- `Utils.NewContrastWipe(Background, Content, TweenInfo, RevealedColor?, StartDirection?)` - gradient-based color wipe. Content keeps its color on one side and flips on the other. `StartDirection` accepts `"Left"`/`"Right"`/`"Up"`/`"Down"` or degrees. Returns `Play`/`Pause`/`Resume`/`Cancel`/`Wait`/`OnFinished`.

## Config

At the top of `Utils/init.luau`:

- `IsTweenStorageWeak` / `IsColorStorageWeak` - stored TweenInfos/ColorPalettes are weakly referenced when true. Leave on unless stored things start disappearing.