---
sidebar_position: 6
---

# Strings

## Trim / Strip

```lua
Utils.Trim(String) -> string
Utils.Strip(String) -> string
```

Removes leading and trailing whitespace. Same function, two names.

## Capitalize

```lua
Utils.Capitalize(String) -> string
```

First letter upper, rest lower. `"hELLO"` → `"Hello"`.

## StartsWith / EndsWith

```lua
Utils.StartsWith(String, Substring) -> boolean
Utils.EndsWith(String, Substring) -> boolean
```

Prefix and suffix checks. An empty substring matches everything.

## Join

```lua
Utils.Join(Separator, Strings, ...) -> string
```

`table.concat` with a different name. Pass a table of strings, or varargs, or both.

```lua
Utils.Join(", ", { "a", "b" }, "c") -- "a, b, c"
```

## Prefix / Suffix

```lua
Utils.Prefix(String, Prefix) -> string
Utils.Suffix(String, Suffix) -> string
```

Prepend or append.

## PadLeft / PadRight

```lua
Utils.PadLeft(String, Length, Padding) -> string
Utils.PadRight(String, Length, Padding) -> string
```

Repeats the padding `Length` times on one side. The count is repeats, not total characters.

```lua
Utils.PadLeft("x", 2, "0") -- "00x"
```

## Truncate

```lua
Utils.Truncate(String, Length, Prefix?) -> string
```

Cuts to `Length` characters. The prefix is only appended when the string was actually cut.

```lua
Utils.Truncate("hello world", 5, "...") -- "hello..."
Utils.Truncate("hi", 5, "...")          -- "hi"
```

## Wrap

```lua
Utils.Wrap(String, Width) -> { string }
```

Word-wraps into lines of at most `Width` characters. Words longer than the width are hard-cut into chunks.

```lua
Utils.Wrap("the quick brown fox", 10) -- { "the quick", "brown fox" }
```