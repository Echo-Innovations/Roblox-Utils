---
sidebar_position: 11
---

# Functions

## Once

```lua
Utils.Once(Function) -> function
```

Runs the function once; later calls do nothing.

## Memoize

```lua
Utils.Memoize(Function) -> function
```

Caches the result per unique set of arguments. Keys are built by value:

- primitives compare by value
- tables compare deeply, order-independently
- function arguments are called and keyed by their result, unless the function is itself memoized, in which case it's treated as stable by identity

Nil results are cached too. The cache lives in `Utils.MemoizeCache`, keyed by the original function.

```lua
local Expensive = Utils.Memoize(function(X) return X * X end)
Expensive(4) -- computes
Expensive(4) -- cached
```

## Throttle

```lua
Utils.Throttle(Function, Delay, InitialDelay?) -> function
```

At most one call per `Delay` seconds; throttled calls return nil. `Delay` can be a number (scaled by `InitialDelay`, default 1) or a function that computes the delay from the arguments.

## Debounce

```lua
Utils.Debounce(Function) -> function
```

Calls the function only when the previous call has finished. While one call is running, further calls return nil.

## Backoff

```lua
Utils.Backoff(Function, Delay, CallLimit?, InitialDelay?) -> { BackoffFunction, CallCount }
```

Re-schedules the call repeatedly with a delay of `Delay()` or `Delay * InitialDelay`. `CallCount` stays live. Without `CallLimit` it runs forever.

## Retry

```lua
Utils.Retry(Function, Attempts, Delay?, ...) -> any
```

Calls the function; on error, retries up to `Attempts` total calls with `Delay` seconds between them. Returns the first successful result, or `nil, Error` when everything fails.

```lua
local Data = Utils.Retry(function() return DataStore:GetAsync(Key) end, 3, 1)
```

## Interval

```lua
Utils.Interval(Seconds, Function?, LoopCount?) -> timer
```

A repeating timer. Methods: `Start`, `Stop`, `Reset`. Signals: `OnStart`, `OnStop`, `OnReset`, `OnAdvance(TickCount)`, `OnLooped(TickCount)`. With `LoopCount`, the timer stops automatically after that many ticks and fires `OnLooped`.

```lua
local Timer = Utils.Interval(1, function(Tick) print(Tick) end)
Timer:Start()
Timer:Stop()
```