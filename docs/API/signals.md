---
sidebar_position: 5
---

# Signals

Signals are event objects without the instance. Connect listeners, fire, and they all run, on a single recycled coroutine thread, so listeners can yield without blocking the caller.

```lua
local Signal = Utils.NewSignal()

Signal:Connect(function(Value)
	print(Value)
end)

Utils.FireSignal(Signal, "hello")
```

## NewSignal

```lua
Utils.NewSignal() -> Signal
```

Creates a signal with a unique `Id`, registered in `Utils.Signals`.

## Connect

```lua
Utils.Connect(Signal, Listener) -> SignalConnection
```

Runs `Listener` on every fire. The connection has a `Disconnect` method.

```lua
local Connection = Utils.Connect(MySignal, function() end)
Connection:Disconnect()
```

## Disconnect / DisconnectAll

```lua
Utils.Disconnect(Connection)
Utils.DisconnectAll()
```

Disconnect one connection, or every connection of every signal in `Utils.Signals`.

## FireSignal

```lua
Utils.FireSignal(Signal, ...)
```

Runs every connected listener with the given arguments. Listener execution happens on a recycled thread, so a listener can `task.wait()` without blocking the caller.

## Wait

```lua
Utils.Wait(Signal) -> (...any)
```

Yields until the next fire, then returns its arguments. One-shot: the connection cleans itself up.

```lua
local Value = Utils.Wait(MySignal)
```

## GetListenerCount

```lua
Utils.GetListenerCount(Signal) -> number
```

How many listeners are currently connected.

## Utilities.Signals

Every signal created through the module, in creation order. Handy for cleanup and introspection.

```lua
print(#Utils.Signals) -- how many signals exist
```