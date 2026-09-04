---
sidebar_position: 8
---

# Time

All timestamp functions take unix timestamps (`os.time()` values), not durations, except `FormatCountdown`, which takes seconds.

## FormatTime

```lua
Utils.FormatTime(Timestamp, Format?) -> string
```

Formats a unix timestamp as a date/time string.

Presets:
- `DateTime` (default): `2026-09-02 14:30:45`
- `Date`: `2026-09-02`
- `Clock`: `14:30:45`
- `Short`: `2 Sep 2026`
- `Long`: `2 September 2026`

Or a custom template. Tokens: `{y}` `{yy}` `{mo}` `{d}` `{dd}` `{h}` `{hh}` `{m}` `{mm}` `{s}` `{ss}` `{Month}` `{Mon}` `{Day}`.

```lua
Utils.FormatTime(Now, "{hh}:{mm}:{ss}") -- "14:30:45"
```

## FormatRelativeTime

```lua
Utils.FormatRelativeTime(Timestamp, Short?, Format?) -> string
```

Formats a timestamp relative to now.

```lua
Utils.FormatRelativeTime(os.time() - 300)          -- "5 minutes ago"
Utils.FormatRelativeTime(os.time() + 172800, true) -- "in 2d"
Utils.FormatRelativeTime(os.time())                -- "Just now"
```

`Short` switches to compact units. `Format` accepts the same presets/templates as `FormatTime`'s duration side and overrides `Short`.

## FormatCountdown

```lua
Utils.FormatCountdown(Seconds, Format?) -> string
```

Formats a duration as a countdown.

Presets:
- `Clock` (default): `01:02:05`
- `MMSS`: total minutes, `62:05`
- `Short`: `1h 2m 5s`
- `Long`: `1 hour, 2 minutes and 5 seconds`

Custom templates use the duration tokens: `{h}` `{m}` `{s}` (omitted when zero), `{hh}` `{mm}` `{ss}` (always shown, padded), and word tokens `{hours}` `{minutes}` `{seconds}` (pluralized).

```lua
Utils.FormatCountdown(45, "{s} seconds left") -- "45 seconds left"
```

## TimeDifference

```lua
Utils.TimeDifference(Timestamp) -> number
```

Signed seconds between now and the timestamp. Negative means the timestamp is in the past.

```lua
Utils.TimeDifference(os.time() - 300) -- -300
Utils.TimeDifference(os.time() + 600) -- 600
```

## Unit conversion

```lua
Utils.ToMilliseconds(Time, Unit) -> number
Utils.ToSeconds(Time, Unit) -> number
Utils.ToMinutes(Time, Unit) -> number
Utils.ToHours(Time, Unit) -> number
Utils.ToDays(Time, Unit) -> number
Utils.ToWeeks(Time, Unit) -> number
Utils.ToMonths(Time, Unit) -> number
Utils.ToYears(Time, Unit) -> number
```

Converts a time value from the named unit into the function's unit. Unknown units pass the value through unchanged.

```lua
Utils.ToSeconds(2, "Minutes") -- 120
```