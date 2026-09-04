---
sidebar_position: 9
---

# Instances

## Searching

```lua
Utils.GetChildrenOfClass(Instance, ClassName) -> { Instance }
Utils.GetDescendantsOfClass(Instance, ClassName) -> { Instance }
```

Children or descendants matching a class (including subclasses, via `IsA`).

```lua
local AllButtons = Utils.GetDescendantsOfClass(ScreenGui, "TextButton")
```

## Attributes

```lua
Utils.GetAttributes(Instance) -> GenericTable
Utils.SetAttributes(Instance, Attributes)
Utils.CopyAttributes(Source, Target)
Utils.AttributeDiff(Instance, Comparison) -> GenericTable
Utils.HasAttribute(Instance, AttributeName) -> boolean
```

Read, write, copy, diff, and check attributes. `AttributeDiff` compares against another instance's attributes or a plain table, returning `Key = {InstanceValue, ComparisonValue}`.

## Properties

```lua
Utils.GetProperties(Instance) -> GenericTable
Utils.CopyProperties(Source, Target)
Utils.PropertyDiff(Instance, Comparison?) -> GenericTable
Utils.HasProperty(Instance, PropertyName) -> boolean
```

`GetProperties` reads every readable value property accessible to a normal script (Basic security, via `ReflectionService`; the class's property list is cached, so repeated calls are cheap).

`CopyProperties` copies writable properties, skipping read-only ones and `Parent`.

`PropertyDiff` compares against another instance's properties, a table of properties, or, when nothing is passed, the class's defaults:

```lua
local Changed = Utils.PropertyDiff(Part) -- what's different from a fresh Part
```

`HasProperty` checks existence through reflection.