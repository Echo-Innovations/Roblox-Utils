-- Utils: A collection of utility functions (and modules?) that could be useful.

--!strict
--!native
--!optimize 2

local Utils = {}

--// Config
local IsTweenStorageWeak = false -- If true, stored TweenInfos will be weakly referenced and may be garbage collected if memory usage is high, which can decrease memory usage but may destroy some of the created TweenInfos.
local IsColorStorageWeak = false -- If true, stored ColorPalettes will be weakly referenced and may be garbage collected if memory usage is high, which can decrease memory usage but may destroy some of the created ColorPalettes.

-- Expirements
local EnableExpirements = false -- If true, experimental features below are loaded.

--// Services
local HttpService = game:GetService("HttpService")
local ReflectionService = game:GetService("ReflectionService")
local TweenService = game:GetService("TweenService")

--// Requires
local Signal = require("@self/Signal")

--// Types
-- Generic Types
export type GenericTable = {[any]: any}
export type GenericStringAnyTable = {[string]: any}
export type GenericFunction = (...any) -> (...any)

-- JSON Types
export type JSONSerializable = {JSONSerializable} | {[string]: JSONSerializable} | number | string | boolean | buffer

-- Table Types
export type WeightedTable = {
	[any]: {Weight: number, [any]: any}
}

-- Signal Types
export type SignalConnection = Signal.SignalConnection
export type Signal = Signal.Signal
export type SignalConnectionData = Signal.SignalConnectionData
export type SignalData = Signal.SignalData
export type SignalClassType = Signal.SignalClassType

-- UI Types
export type ContrastWipe = {
	Play: (self: ContrastWipe) -> (),
	Pause: (self: ContrastWipe) -> (),
	Resume: (self: ContrastWipe) -> (),
	Cancel: (self: ContrastWipe) -> (),
	Wait: (self: ContrastWipe) -> (...any),
	OnFinished: Signal,
}

-- Color Palette Types
export type ColorPalette = {
	PrimaryColor: Color3,
	AccentColor: Color3,
	SecondaryColor: Color3,
	ComplementaryColor: Color3,

	BackgroundColor: Color3?,
	TextColor: Color3?,
}

-- Observer Types
export type ObservedTable = GenericTable & {
	OnChanged: Signal,
	OnKeyChanged: (Key: string) -> Signal,
	OnDestroy: Signal,
	Destroy: (self: ObservedTable) -> (),
}

-- Computed Types
export type ComputedValue = GenericTable & {
	Value: any,
	OnRecompute: Signal,
	OnChanged: Signal,
	OnDestroy: Signal,
	Destroy: (self: ComputedValue) -> any,
}

-- Default Table Types
export type TableWithDefault = {
	SetDefault: (self: TableWithDefault, Value: any) -> (),
	GetDefault: (self: TableWithDefault) -> any,
	AddDefault: (self: TableWithDefault, Key: any, Value: any) -> (),
	RemoveDefault: (self: TableWithDefault, Key: any) -> (),
	OnDestroy: Signal,
	Destroy: (self: TableWithDefault) -> (),

	[any]: any,
}

-- Enum Types
export type EnumTable = {
	[any]: any,
}

-- UI Types
export type Direction = "Right" | "Left" | "Up" | "Down"

--// Constants
local WeakValueTable = {__mode = "v"}
local _WeakKeyTable = {__mode = "k"}

--// Storage
Utils.TweenInfos = {} :: {[string]: TweenInfo}
Utils.ColorPalettes = {} :: {[string]: ColorPalette}
Utils.MemoizeCache = {} :: {[GenericFunction]: GenericStringAnyTable}
Utils.MemoizedFunctionSet = {} :: {[GenericFunction]: boolean}
Utils.Signals = Signal.Signals :: {SignalData} -- Making sure its correctly typed idrk
Utils.PropertyListCache = {} :: {[string]: any} -- ReflectionService.GetPropertiesOfClass results per class
Utils.Enums = {} :: {[string]: EnumTable}

--// Initialization
if IsTweenStorageWeak then
	setmetatable(Utils.TweenInfos, WeakValueTable)
end

if IsColorStorageWeak then
	setmetatable(Utils.ColorPalettes, WeakValueTable)
end

--[[ Table manipulation
    -- Table manipulation functions are useful for working with tables in Lua. Here are some common functions:
    -- Utils.DeepCopy: Creates a deep copy of a table, including nested tables.
    -- Utils.DeepDiff: Compares two tables and returns a table containing the differences.
	-- Utils.Patch: Applies a Utils.DeepDiff result back onto a table (the inverse of DeepDiff).
	-- Utils.DeepEqual: Returns true if two tables are deeply equal (DeepDiff via JSON or recursion).
    -- Utils.Shuffle: Randomly shuffles the elements of a table in place.
    -- Utils.Pick: Create a table containing certain keys from the original table.
    -- Utils.Omit: Create a table containing everything except certain keys from the original table.
    -- Utils.Unique: Returns a new table containing only unique values from the original table.
    -- Utils.Merge: Merges two tables together, with the second table overwriting any duplicate keys in the first table.
    -- Utils.Filter: Returns a new table containing only the elements that pass a given filter function.
	-- Utils.Keys: Returns a table of all the keys in a given table.
	-- Utils.Values: Returns a table of all the values in a given table.
	-- Utils.IsEmpty: Returns true if the inputted table is empty.
	-- Utils.Observer: Creates an observed table that fires Utils Signals (OnChanged, OnKeyChanged(Key)) on any write; Destroy() detaches it.
	-- Utils.CreateTableWithDefault: Creates a table that returns a default for missing keys, with SetDefault/GetDefault/AddDefault/RemoveDefault/Destroy.
    -- Maybe more soon?
]]

-- SkipJSON Paramater goes directly to a looping fallback if true. Setting it to true would only be useful if you know the table contains non-serializable data. 
-- Creates a deep copy of a table, including nested tables. Attempts JSON serialization first, then falls back to a recursive copy if the data isn't serializable (or if SkipJSON is true).
function Utils.DeepCopy(Table: GenericTable, SkipJSON: boolean?): GenericTable
	if not SkipJSON then
		-- Attempt to copy using JSON serialization and deserialization
		local Success, Serialized = pcall(function()
			return HttpService:JSONEncode(Table)
		end)

		if Success == true then
			return HttpService:JSONDecode(Serialized)
		end
	end

	-- Looping fallback
	local Copy = {}
	for Key, Value in pairs(Table) do
		if type(Value) == "table" then
			Copy[Key] = Utils.DeepCopy(Value, true)
		else
			Copy[Key] = Value
		end
	end

	return Copy
end

-- Compares two tables and returns a table of differences. Each diff entry is {Table1Value, Table2Value}; keys only in Table2 appear as {nil, Table2Value}. Nested tables are compared recursively.
function Utils.DeepDiff(Table1: GenericTable, Table2: GenericTable): GenericTable
	local Diff = {}
	for Key, Value in pairs(Table1) do
		if type(Value) == "table" and type(Table2[Key]) == "table" then
			local SubDiff = Utils.DeepDiff(Value, Table2[Key])
			if next(SubDiff) ~= nil then
				Diff[Key] = SubDiff
			end
		elseif Value ~= Table2[Key] then
			Diff[Key] = {Value, Table2[Key]}
		end
	end

	for Key, Value in pairs(Table2) do
		if Table1[Key] == nil then
			Diff[Key] = {nil, Value}
		end
	end

	return Diff
end

-- Returns true if Table1 and Table2 are deeply equal: primitives compare by value and tables are
-- compared recursively and order-independently. Attempts a JSON serialization comparison first,
-- then falls back to DeepDiff (equal when the diff comes back empty) if the data isn't serializable
-- or if SkipJSON is true. SkipJSON forces the recursive path for non-serializable data.
function Utils.DeepEqual(Table1: any, Table2: any, SkipJSON: boolean?): boolean
	if not SkipJSON then
		local Success1, Serialized1 = pcall(function()
			return HttpService:JSONEncode(Table1)
		end)
		local Success2, Serialized2 = pcall(function()
			return HttpService:JSONEncode(Table2)
		end)

		if Success1 and Success2 then
			return Serialized1 == Serialized2
		end
	end

	if Table1 == Table2 then
		return true
	end

	if type(Table1) ~= "table" or type(Table2) ~= "table" then
		return false
	end

	return next(Utils.DeepDiff(Table1, Table2)) == nil
end

-- Applies a Utils.DeepDiff result back onto Table, mutating it in place and returning it.
-- Value pairs ({Table1Value, Table2Value}) write/remove keys; nested sub-diffs recurse into the matching nested table. The natural inverse of DeepDiff: after Patch(Table, DeepDiff(Table, Target)), Table deeply equals Target.
function Utils.Patch(Table: GenericTable, Diff: GenericTable): GenericTable
	for Key, Entry in pairs(Diff) do
		if type(Entry) == "table" then
			-- A pair is {Table1Value, Table2Value} (either slot may be nil for removed/added keys);
			-- anything with other keys is a nested sub-diff. Note: pairs() skips nil values, so a
			-- removal pair {OldValue, nil} only shows key 1 and an addition {nil, NewValue} only key 2.
			local AllPairKeys = true
			for EntryKey in pairs(Entry) do
				if EntryKey ~= 1 and EntryKey ~= 2 then
					AllPairKeys = false
					break
				end
			end

			if AllPairKeys then
				Table[Key] = Entry[2]
			else
				if type(Table[Key]) ~= "table" then
					Table[Key] = {}
				end
				Utils.Patch(Table[Key], Entry)
			end
		else
			Table[Key] = Entry
		end
	end

	return Table
end

-- Shuffles the elements of Table in place and returns it. If Recursive, nested tables are shuffled in place too.
function Utils.Shuffle(Table: GenericTable, Recursive: boolean?): GenericTable
	local Keys = {}
	for Key in pairs(Table) do
		table.insert(Keys, Key)
	end

	for i = #Keys, 2, -1 do
		local j = math.random(i)
		Table[Keys[i]], Table[Keys[j]] = Table[Keys[j]], Table[Keys[i]]
	end

	if Recursive then
		for _, Value in pairs(Table) do
			if type(Value) == "table" then
				Utils.Shuffle(Value, Recursive)
			end
		end
	end

	return Table
end

-- Shared helper for Pick/Omit: keeps the keys in Keys when IsPick is true, otherwise keeps everything else.
-- The KeySet lookup makes membership checks O(1) instead of scanning Keys for every entry.
local function basePickOmit(Table: GenericTable, Keys: {any}, IsPick: boolean): GenericTable
	local KeySet = {}
	for _, Key in ipairs(Keys) do
		KeySet[Key] = true
	end

	local Result = {}
	for Key, Value in pairs(Table) do
		local ShouldInclude = KeySet[Key] == true
		if (IsPick and ShouldInclude) or (not IsPick and not ShouldInclude) then
			Result[Key] = Value
		end
	end

	return Result
end

-- Returns a new table containing only the keys in Keys from Table.
function Utils.Pick(Table: GenericTable, Keys: {any}): GenericTable
	return basePickOmit(Table, Keys, true)
end

-- Returns a new table containing everything from Table except the keys in Keys.
function Utils.Omit(Table: GenericTable, Keys: {any}): GenericTable
	return basePickOmit(Table, Keys, false)
end

-- Returns a new list containing only unique values from Table. If Recursive, nested tables are deduplicated recursively.
-- Primitive values are deduplicated with an O(1) set; tables/functions fall back to a linear scan by reference.
function Utils.Unique(Table: GenericTable, Recursive: boolean?): GenericTable
	local UniqueValues = {}
	local PrimitiveSet = {}
	local Result = {}

	for _, Value in pairs(Table) do
		if type(Value) == "table" and Recursive then
			Value = Utils.Unique(Value, Recursive)
		end

		local ValueType = type(Value)
		local Seen = false
		if ValueType == "number" or ValueType == "string" or ValueType == "boolean" then
			local SetKey = `{ValueType}:{tostring(Value)}`
			if PrimitiveSet[SetKey] then
				Seen = true
			else
				PrimitiveSet[SetKey] = true
			end
		else
			Seen = table.find(UniqueValues, Value) ~= nil
		end

		if not Seen then
			table.insert(UniqueValues, Value)
			table.insert(Result, Value)
		end
	end

	return Result
end

-- Merges Table2 into a copy of Table1 (Table2 wins on duplicate keys). If Recursive, nested tables are merged recursively.
function Utils.Merge(Table1: GenericTable, Table2: GenericTable, Recursive: boolean?): GenericTable
	local Merged = Utils.DeepCopy(Table1, true)
	for Key, Value in pairs(Table2) do
		if type(Value) == "table" and Recursive and type(Merged[Key]) == "table" then
			Merged[Key] = Utils.Merge(Merged[Key], Value, Recursive)
		else
			Merged[Key] = Value
		end
	end
	return Merged
end

-- Returns a new table with only the values for which FilterFunction returns true. If Recursive, nested tables are filtered recursively.
function Utils.Filter(Table: GenericTable, FilterFunction: (any) -> boolean, Recursive: boolean?): GenericTable
	local Filtered = {}
	for Key, Value in pairs(Table) do
		if type(Value) == "table" and Recursive then
			Filtered[Key] = Utils.Filter(Value, FilterFunction, Recursive)
		elseif FilterFunction(Value) then
			Filtered[Key] = Value
		end
	end
	return Filtered
end

-- Returns true if any value in Table equals Value (reference or value comparison per Luau ==).
function Utils.Contains(Table: GenericTable, Value: any): boolean
	for _, Entry in pairs(Table) do
		if Entry == Value then
			return true
		end
	end

	return false
end

-- Groups Table's entries into buckets by the key KeyFunction returns for each (value, key) pair.
-- Each group keeps the original keys of its entries: GroupBy({a = 1, b = 2}, v % 2) -> {[1] = {a = 1}, [0] = {b = 2}}.
function Utils.GroupBy(Table: GenericTable, KeyFunction: (Value: any, Key: any) -> any): GenericTable
	local Groups = {}
	for Key, Value in pairs(Table) do
		local GroupKey = KeyFunction(Value, Key)
		local Group = Groups[GroupKey]
		if not Group then
			Group = {}
			Groups[GroupKey] = Group
		end
		Group[Key] = Value
	end

	return Groups
end

-- Returns a flat list of every non-table value in Table, recursing through nested tables.
-- Flatten({1, {2, 3}, {4, {5}}}) -> {1, 2, 3, 4, 5}.
function Utils.Flatten(Table: GenericTable): GenericTable
	local Result = {}

	local function Collect(Value: any)
		if type(Value) == "table" then
			for _, Child in pairs(Value) do
				Collect(Child)
			end
		else
			table.insert(Result, Value)
		end
	end

	Collect(Table)

	return Result
end

local function baseKeysValues(Table: GenericTable, Recursive: boolean?, Keys: boolean?): GenericTable
	local Data = {}
	for Key, Value in pairs(Table) do
		if type(Value) == "table" and Recursive then
			baseKeysValues(Value, Recursive, Keys)
		else
			table.insert(Data, Keys and Key or Value)
		end
	end

	return Data
end

-- Returns a list of all keys in Table (recursively collected if Recursive).
function Utils.Keys(Table: GenericTable, Recursive: boolean?): GenericTable
	return baseKeysValues(Table, Recursive, true)
end

-- Returns a list of all values in Table (recursively collected if Recursive).
function Utils.Values(Table: GenericTable, Recursive: boolean?): GenericTable
	return baseKeysValues(Table, Recursive)
end

-- Returns true if the given table is empty (no keys at all).
function Utils.IsEmpty(Table: GenericTable): boolean
	return next(Table) == nil
end

-- Creates an observed table: any write to it fires OnChanged (Key, NewValue, OldValue),
-- and OnKeyChanged(Key) returns a per-key signal firing (NewValue, OldValue).
-- Luau skips __newindex on existing keys, so the returned object is a PROXY: an empty table whose
-- reads/writes delegate to a hidden backing store (the InitialTable). Keys never exist on the proxy,
-- so every write fires. Signals live on the metatable and don't show up in pairs/Keys/Values.
-- Destroy() fires OnDestroy and detaches the proxy; the backing table keeps its data.
function Utils.Observer(InitialTable: GenericTable?): ObservedTable
	local Backing = InitialTable or {}
	local Observed = {}

	-- Metamethods are added at runtime, so keep the metadata table loosely typed
	local Meta: any = {
		Backing = Backing,
		OnChanged = Utils.NewSignal(),
		OnDestroy = Utils.NewSignal(),
		KeySignals = {},
	}

	Meta.__index = function(_, Key)
		if Key == "OnChanged" then
			return Meta.OnChanged
		elseif Key == "OnKeyChanged" then
			return function(KeyName: string)
				local KeySignal = Meta.KeySignals[KeyName]
				if not KeySignal then
					KeySignal = Utils.NewSignal()
					Meta.KeySignals[KeyName] = KeySignal
				end
				return KeySignal
			end
		elseif Key == "OnDestroy" then
			return Meta.OnDestroy
		elseif Key == "Destroy" then
			return function()
				Meta.OnDestroy:Fire()
				setmetatable(Observed, nil)
			end
		end

		return Backing[Key]
	end

	Meta.__newindex = function(_, Key, Value)
		local OldValue = Backing[Key]
		if OldValue == Value then
			return
		end

		Backing[Key] = Value

		local KeySignal = Meta.KeySignals[Key]
		if KeySignal then
			KeySignal:Fire(Value, OldValue)
		end

		Meta.OnChanged:Fire(Key, Value, OldValue)
	end

	return (setmetatable(Observed, Meta) :: any) :: ObservedTable
end

-- Creates a table where reads of missing keys return Default instead of nil.
-- If Default is a function, it is called with the key; writes behave like a normal table
-- (after a write, reads return the written value). The metatable doesn't show up in pairs/Keys/Values.
-- The table also exposes default-management functions:
--     -- SetDefault(Value): change the general default.
--     -- GetDefault(): read the general default.
--     -- AddDefault(Key, Value): a per-key default that overrides the general one.
--     -- RemoveDefault(Key): drop a per-key default (falls back to the general one).
function Utils.CreateTableWithDefault(Default: any, Table: GenericTable?): TableWithDefault
	local Defaulted = Table or {}

	local Meta: any = {
		Default = Default,
		KeyDefaults = {},
		OnDestroy = Utils.NewSignal(),
	}

	Meta.__index = function(_, Key)
		if Key == "SetDefault" then
			return function(_, NewDefault: any)
				Meta.Default = NewDefault
			end
		elseif Key == "GetDefault" then
			return function()
				return Meta.Default
			end
		elseif Key == "AddDefault" then
			return function(_, KeyName: any, Value: any)
				Meta.KeyDefaults[KeyName] = Value
			end
		elseif Key == "RemoveDefault" then
			return function(_, KeyName: any)
				Meta.KeyDefaults[KeyName] = nil
			end
		elseif Key == "OnDestroy" then
			return Meta.OnDestroy
		elseif Key == "Destroy" then
			return function()
				Meta.OnDestroy:Fire()
				setmetatable(Defaulted, nil)
			end
		end

		local KeyDefault = Meta.KeyDefaults[Key]
		if KeyDefault ~= nil then
			return KeyDefault
		end

		if type(Meta.Default) == "function" then
			return Meta.Default(Key)
		end

		return Meta.Default
	end

	return (setmetatable(Defaulted, Meta) :: any) :: TableWithDefault
end

-- Creates a computed value: Value is produced by Compute(), and any dependency changing
-- triggers a recomputation. Dependencies can be a single Utils Signal, observed table or other
-- computed value, or a list of them (observed/computed tables use their OnChanged signal).
-- OnRecompute fires with the new value on every recompute; OnChanged fires with (NewValue, OldValue)
-- only when the value actually changed (it also fires once on creation with the initial value).
-- Destroy() disconnects the dependencies, fires OnDestroy with the last value, and returns that value.
function Utils.Computed(Dependencies: Signal | ObservedTable | ComputedValue | {Signal | ObservedTable | ComputedValue}, Compute: () -> any): ComputedValue
	local Computed = {}

	local Meta: any = {
		HasValue = false,
		Value = nil,
		OnRecompute = Utils.NewSignal(),
		OnChanged = Utils.NewSignal(),
		OnDestroy = Utils.NewSignal(),
		Connections = {},
	}

	local function Recompute()
		local NewValue = Compute()

		Meta.OnRecompute:Fire(NewValue)

		local OldValue = Meta.Value
		if not Meta.HasValue or NewValue ~= OldValue then
			Meta.HasValue = true
			Meta.Value = NewValue
			Meta.OnChanged:Fire(NewValue, OldValue)
		end
	end

	Meta.__index = function(_, Key)
		if Key == "Value" then
			return Meta.Value
		elseif Key == "OnRecompute" then
			return Meta.OnRecompute
		elseif Key == "OnChanged" then
			return Meta.OnChanged
		elseif Key == "OnDestroy" then
			return Meta.OnDestroy
		elseif Key == "Destroy" then
			return function()
				for _, Connection in ipairs(Meta.Connections) do
					Connection:Disconnect()
				end
				Meta.OnDestroy:Fire(Meta.Value)
				rawset(Computed, "Value", Meta.Value)
				setmetatable(Computed, nil)
				return Meta.Value
			end
		end

		return nil
	end

	-- Accept either a single dependency or a list of them
	local RawDependencies: any = Dependencies
	local DependencyList: {Signal | ObservedTable | ComputedValue} = RawDependencies
	if type(RawDependencies.Connect) == "function" or type(RawDependencies.OnChanged) == "table" then
		DependencyList = {RawDependencies}
	end

	for _, Dependency in ipairs(DependencyList) do
		-- A dependency is either a signal itself, or an observed/computed table exposing OnChanged
		local Source = Dependency
		if type(Dependency.Connect) ~= "function" then
			Source = Dependency.OnChanged
		end
		table.insert(Meta.Connections, Source:Connect(Recompute))
	end

	Recompute()

	return (setmetatable(Computed, Meta) :: any) :: ComputedValue
end

-- Creates a strict, read-only constant table: unknown-key reads and any writes error.
-- The result is stored in Utils.Enums under Name and returned. Luau's proxy pattern is used
-- (empty table + __index into a backing store) so every access is intercepted.
function Utils.Enum(Name: string, Values: GenericTable): EnumTable
	local Enum = {}

	local Meta: any = {
		Values = Values,
	}

	Meta.__index = function(_, Key)
		local Value = Values[Key]
		if Value == nil then
			error(`[Utils - Enum] "{tostring(Key)}" is not a member of enum "{Name}"`)
		end

		return Value
	end

	Meta.__newindex = function()
		error(`[Utils - Enum] "{Name}" is read-only`)
	end

	local Result = (setmetatable(Enum, Meta) :: any) :: EnumTable
	Utils.Enums[Name] = Result

	return Result
end

--[[ Signal
    -- Signal is an alternative to BindableEvents that is more efficient and easier to use. 
    -- It allows you to create custom events that can be connected to and fired.
    -- Every signal has a unique Id and is stored in Utils.Signals.
    -- Utils.NewSignal: Creates a new event/signal.
    -- Utils.Connect: Connects a listener; returns a connection object that can disconnect it.
    -- Utils.Disconnect: Disconnects a listener connection.
    -- Utils.DisconnectAll: Disconnects every connection of every signal in Utils.Signals.
    -- Utils.FireSignal: Fires the event; every connected listener runs on the recycled runner thread.
    -- Utils.Wait: Yields until the next fire, then returns its arguments.
        -- The listener resumes the caller thread instead of the caller waiting in a busy loop.

    -- Utils.GetListenerCount: Returns the number of connected listeners.

]]

-- Creates a new event/signal
function Utils.NewSignal(): Signal
	return Signal.New()
end

-- Connects a listener; returns a connection object that can disconnect it
function Utils.Connect(self: SignalData, Listener: GenericFunction): SignalConnection
	return Signal.Connect(self, Listener)
end

-- Disconnects a listener connection
function Utils.Disconnect(self: SignalConnectionData)
	return Signal.Disconnect(self)
end

-- Fires the event; every connected listener runs on the recycled runner thread
function Utils.FireSignal(self: SignalData, ...: any)
	return Signal.Fire(self, ...)
end

-- Yields until the next fire, then returns its arguments.
-- The listener resumes the caller thread instead of the caller waiting in a busy loop.
function Utils.Wait(self: SignalData): (...any)
	return Signal.Wait(self)
end

-- Returns the number of connected listeners
function Utils.GetListenerCount(self: SignalData): number
	return Signal.GetListenerCount(self)
end

-- Disconnects every connection of every signal created through Utils/Signal.
function Utils.DisconnectAll()
	return Signal.DisconnectAll()
end

--[[ String Manipulation
    -- String manipulation functions are useful for working with strings in Lua. Here are some common functions:
    -- Utils.Trim/Strip: Removes leading and trailing whitespace from a string.
    -- Utils.Capitalize: Capitalizes the first letter of a string.
    -- Utils.StartsWith: Checks if a string starts with a given substring.
    -- Utils.EndsWith: Checks if a string ends with a given substring.
    -- Utils.Join: Joins a table of strings into a single string with a given separator. Basically table.concat but under a different name.
	-- Utils.Prefix: Adds a prefix to the string.
	-- Utils.Suffix: Adds a suffix to the string.
	-- Utils.PadLeft: Adds a prefix to the string a specific amount of times.
	-- Utils.PadRight: Adds a suffix to the string a specific amount of times.
	-- Utils.Truncate: Truncates a string to a specific length with the option to add a prefix.
    -- Maybe more soon?
]]

-- Shared helper for Trim/Strip: removes leading and trailing whitespace from a string.
local function baseTrimStrip(String: string): string
	return String:match("^%s*(.-)%s*$") or String
end

-- Removes leading and trailing whitespace from a string.
function Utils.Trim(String: string): string
	return baseTrimStrip(String)
end

-- Removes leading and trailing whitespace from a string.
function Utils.Strip(String: string): string
	return baseTrimStrip(String)
end

-- Capitalizes the first letter of a string and lowercases the rest.
function Utils.Capitalize(String: string): string
	return String:sub(1, 1):upper() .. String:sub(2):lower()
end

-- Returns true if String starts with Substring.
function Utils.StartsWith(String: string, Substring: string): boolean
	return String:sub(1, #Substring) == Substring
end

-- Returns true if String ends with Substring.
function Utils.EndsWith(String: string, Substring: string): boolean
	if #Substring == 0 then
		return true
	end

	return String:sub(-#Substring) == Substring
end

-- Joins a table of strings and any extra string arguments into a single string using Separator.
-- If you do not have a table of the strings, then you may input them into vargs (e.g. Utils.Join(Separator, nil, str1, st2, etc.))
function Utils.Join(Separator: string, Strings: {string}, ...: string): string
	local AllStrings = {table.unpack(Strings)}
	for _, Str in ipairs({...}) do
		table.insert(AllStrings, Str)
	end

	return table.concat(AllStrings, Separator)
end

-- Prepends Prefix to String.
function Utils.Prefix(String: string, Prefix: string): string
	return `{Prefix}{String}`
end

-- Appends Suffix to String.
function Utils.Suffix(String: string, Suffix: string): string
	return `{String}{Suffix}`
end

-- Prepends PaddingString repeated Length times to String.
function Utils.PadLeft(String: string, Length: number, PaddingString: string): string
	return `{PaddingString:rep(Length)}{String}`
end

-- Appends PaddingString repeated Length times to String.
function Utils.PadRight(String: string, Length: number, PaddingString: string): string
	return `{String}{PaddingString:rep(Length)}`
end

-- Truncates String to Length characters; if it was cut short, Prefix (optional) is appended after it.
function Utils.Truncate(String: string, Length: number, Prefix: string?): string
	if #String <= Length then
		return String
	end

	return `{String:sub(1, Length)}{Prefix or ""}`
end

-- Word-wraps String into an array of lines of at most Width characters. Words longer than Width
-- are hard-cut into chunks; the result has no leading/trailing whitespace on any line.
function Utils.Wrap(String: string, Width: number): {string}
	local Lines = {}
	local CurrentLine = ""
	for Word in String:gmatch("%S+") do
		if #Word > Width then
			if #CurrentLine > 0 then
				table.insert(Lines, CurrentLine)
				CurrentLine = ""
			end
			while #Word > Width do
				table.insert(Lines, Word:sub(1, Width))
				Word = Word:sub(Width + 1)
			end
			CurrentLine = Word
		elseif #CurrentLine == 0 then
			CurrentLine = Word
		elseif #CurrentLine + 1 + #Word <= Width then
			CurrentLine ..= " " .. Word
		else
			table.insert(Lines, CurrentLine)
			CurrentLine = Word
		end
	end

	if #CurrentLine > 0 then
		table.insert(Lines, CurrentLine)
	end

	return Lines
end

--[[ Math Utilities
    -- Math utility functions are useful for performing common mathematical operations in Lua. Here are some common functions:
    -- Utils.IsEven: Checks if a number is even.
    -- Utils.IsOdd: Checks if a number is odd.
    -- Utils.IsClose: Checks if two numbers are close to each other within a given tolerance.
    -- Maybe more soon?

    --- Subcategory: Randomness
        -- Utils.RandomChoice: Returns a random element from a table.
        -- Utils.RandomFloat: Returns a random float between two numbers and with a specific amount of decimals.
        -- Utils.RandomWeightedChoice: Returns a random element from a table based on weights.
        -- Utils.RandomColor: Returns a random Color3.
]]

-- Numbers/Math
-- Returns true if Number is even.
function Utils.IsEven(Number: number): boolean
	return Number % 2 == 0
end

-- Returns true if Number is odd.
function Utils.IsOdd(Number: number): boolean
	return Number % 2 ~= 0
end

-- Returns true if Number1 and Number2 are within Tolerance of each other.
function Utils.IsClose(Number1: number, Number2: number, Tolerance: number): boolean
	return math.abs(Number1 - Number2) <= Tolerance
end

-- Returns the sum of all given numbers.
function Utils.Sum(...: number): number
	local Total = 0
	for Index = 1, select("#", ...) do
		Total += select(Index, ...)
	end

	return Total
end

-- Returns the average of all given numbers (0 when none are given).
function Utils.Average(...: number): number
	local Count = select("#", ...)
	if Count == 0 then
		return 0
	end

	return Utils.Sum(...) / Count
end

-- Returns the median of all given numbers (0 when none are given).
function Utils.Median(...: number): number
	local Values = {...}
	if #Values == 0 then
		return 0
	end

	table.sort(Values)
	local Middle = #Values // 2
	if #Values % 2 == 0 then
		return (Values[Middle] + Values[Middle + 1]) / 2
	end

	return Values[Middle + 1]
end

-- Randomness
-- Returns a random value from Table.
function Utils.RandomChoice(Table: GenericTable): any
	local Keys = {}
	for Key in pairs(Table) do
		table.insert(Keys, Key)
	end
	local RandomKey = Keys[math.random(1, #Keys)]
	return Table[RandomKey]
end

-- Returns a random number between Min and Max, rounded to Decimals decimal places.
function Utils.RandomFloat(Min: number, Max: number, Decimals: number): number
	local Multiplier = 10 ^ Decimals
	return math.round(math.random() * (Max - Min) * Multiplier + Min * Multiplier) / Multiplier
end

-- Returns a random key and value from Table, weighted by each entry's Weight field.
function Utils.RandomWeightedChoice(Table: WeightedTable): any
	local TotalWeight = 0
	for _, Value in pairs(Table) do
		if Value.Weight < 0 then warn("[Utils - Randomness] Negative weight detected in RandomWeightedChoice. This may cause unexpected behavior.") end
		TotalWeight += Value.Weight
	end

	local RandomWeight = math.random() * TotalWeight
	local CumulativeWeight = 0

	for Key, Value in pairs(Table) do
		CumulativeWeight += Value.Weight
		if RandomWeight <= CumulativeWeight then
			return Key, Value
		end
	end

	return nil -- Should never reach here if weights are set correctly
end

-- Returns a random Color3.
function Utils.RandomColor(): Color3
	return Color3.new(math.random(), math.random(), math.random())
end

-- Returns a random integer usable as a seed.
-- Might increase limit
function Utils.RandomSeed(): number
	return math.random(1, 2147483647)
end

-- Returns a random integer between Min and Max (inclusive).
function Utils.RandomInt(Min: number, Max: number): number
	return math.random(Min, Max)
end

--[[ Tween Utilities
    -- Tween utility functions are useful for creating and managing tweens in Roblox. Here are some common functions:
    -- Utils.NewTweenInfo: Creates a new TweenInfo object and saves it for future use.
        -- Tweens created with NewTweenInfo are stored in Utils.TweenInfos and can be accessed by name.
        -- You can optimize memory usage by setting IsTweenStorageWeak to true, which will weakly reference the stored TweenInfos and allow them to be garbage collected if memory usage is high.
            -- This may cause some of the created TweenInfos to be destroyed, so use with caution.
    -- Maybe more soon?
]]

-- Creates a TweenInfo, stores it in Utils.TweenInfos under Name, and returns it.
function Utils.NewTweenInfo(Name: string, Time: number, EasingStyle: Enum.EasingStyle, EasingDirection: Enum.EasingDirection, RepeatCount: number, Reverses: boolean): TweenInfo
	local TweenInfo = TweenInfo.new(Time, EasingStyle, EasingDirection, RepeatCount, Reverses)
	Utils.TweenInfos[Name] = TweenInfo
	return Utils.TweenInfos[Name]
end

--[[ Time Utilities
    -- Time utility functions are useful for working with time in Roblox. Here are some common functions:
    -- Utils.FormatTime: Formats a unix timestamp into a date/time string (e.g., "2026-09-02 14:30:45", "2 September 2026", "14:30:45").
	-- Utils.FormatRelativeTime: Formats a unix timestamp relative to now (e.g., "Just now", "5 minutes ago", "in 2 days and 13 hours", "in 2d 13h").
	-- Utils.TimeDifference: Returns the signed seconds between now and a unix timestamp (negative = in the past).
    
    --- Subcategory: Time Conversion
        -- Utils.ToMilliseconds: Converts a time value (in seconds, minutes, hours, days, weeks, months or years) to milliseconds.
        -- Utils.ToSeconds: Converts a time value (in milliseconds, minutes, hours, days, weeks, months or years) to seconds.
        -- Utils.ToMinutes: Converts a time value (in milliseconds, seconds, hours, days, weeks, months or years) to minutes.
        -- Utils.ToHours: Converts a time value (in milliseconds, seconds, minutes, days, weeks, months or years) to hours.
        -- Utils.ToDays: Converts a time value (in milliseconds, seconds, minutes, hours, weeks, months or years) to days.
        -- Utils.ToWeeks: Converts a time value (in milliseconds, seconds, minutes, hours, days, months or years) to weeks.
        -- Utils.ToMonths: Converts a time value (in milliseconds, seconds, minutes, hours, days, weeks or years) to months.
        -- Utils.ToYears: Converts a time value (in milliseconds, seconds, minutes, hours, days, weeks or months) to years.
    -- Maybe more soon?
]]

-- Shared helper: formats a duration with a template. Tokens: {y} {mo} {w} {d} {h} {m} {s}
-- (unpadded, omitted when zero), doubled variants like {hh} (zero-padded to 2 digits, always shown),
-- and word variants like {hours} (pluralized, omitted when zero). Everything else is literal text;
-- separators around omitted tokens are dropped. MaxUnit caps the largest unit; a nil template
-- returns the legacy space-separated style ("2 Years 3 Hours").
local function formatDuration(Time: number, MaxUnit: string?, Template: string?): string
	local Units = {
		{Name = "Years", Short = "y", Seconds = 31536000},
		{Name = "Months", Short = "mo", Seconds = 2592000},
		{Name = "Weeks", Short = "w", Seconds = 604800},
		{Name = "Days", Short = "d", Seconds = 86400},
		{Name = "Hours", Short = "h", Seconds = 3600},
		{Name = "Minutes", Short = "m", Seconds = 60},
		{Name = "Seconds", Short = "s", Seconds = 1}
	}
	local WordSingular = {
		years = "year", months = "month", weeks = "week", days = "day",
		hours = "hour", minutes = "minute", seconds = "second"
	}
	local WordShort = {
		years = "y", months = "mo", weeks = "w", days = "d",
		hours = "h", minutes = "m", seconds = "s"
	}
	local UnitKeys = {y = true, mo = true, w = true, d = true, h = true, m = true, s = true}

	local StartIndex = 1
	for Index, Unit in ipairs(Units) do
		if Unit.Name == MaxUnit then
			StartIndex = Index
			break
		end
	end

	local Values = {}
	local Remaining = Time
	for Index = StartIndex, #Units do
		local Unit = Units[Index]
		Values[Unit.Short] = Index == #Units and Remaining or math.floor(Remaining / Unit.Seconds)
		Remaining -= Values[Unit.Short] * Unit.Seconds
	end

	if Template == nil then
		local Parts = {}
		for Index = StartIndex, #Units do
			local Unit = Units[Index]
			if Values[Unit.Short] > 0 then
				table.insert(Parts, `{Values[Unit.Short]} {Unit.Name}`)
			end
		end
		return table.concat(Parts, " ")
	end

	-- Parse the template into alternating literal/token segments
	local Segments: {{Text: string?, Key: string?, Short: string?, Padded: boolean?, Word: boolean?}} = {}
	local Pos = 1
	while Pos <= #Template do
		local Open = Template:find("{", Pos, true)
		if not Open then
			table.insert(Segments, {Text = Template:sub(Pos)})
			break
		end
		if Open > Pos then
			table.insert(Segments, {Text = Template:sub(Pos, Open - 1)})
		end
		local Close = Template:find("}", Open, true)
		if not Close then
			table.insert(Segments, {Text = Template:sub(Open)})
			break
		end
		local Token = Template:sub(Open + 1, Close - 1)
		local Lower = Token:lower()
		if WordShort[Lower] then
			table.insert(Segments, {Key = Lower, Short = WordShort[Lower], Word = true})
		else
			local Padded = Token:len() == 2 and Token:sub(1, 1) == Token:sub(2, 2)
			local Key = Padded and Lower:sub(1, 1) or Lower
			if UnitKeys[Key] then
				table.insert(Segments, {Key = Key, Padded = Padded})
			else
				table.insert(Segments, {Text = "{" .. Token .. "}"})
			end
		end
		Pos = Close + 1
	end

	-- A token is shown when it's padded or its value is nonzero; a literal is kept only
	-- when both of its neighboring tokens are shown (single-shown gaps become a space)
	local Shown = {}
	for Index, Segment in ipairs(Segments) do
		if Segment.Key then
			Shown[Index] = Segment.Padded or (Values[Segment.Short or Segment.Key] or 0) > 0
		end
	end

	local Parts = {}
	for Index, Segment in ipairs(Segments) do
		if Segment.Key then
			if Shown[Index] then
				local Value = Values[Segment.Short or Segment.Key] or 0
				if Segment.Word then
					table.insert(Parts, `{Value} {Value == 1 and WordSingular[Segment.Key] or Segment.Key}`)
				elseif Segment.Padded then
					table.insert(Parts, string.format("%02d", Value))
				else
					table.insert(Parts, tostring(Value))
				end
			end
		elseif Segment.Text ~= nil then
			local Text = Segment.Text
			if Text ~= "" then
				local PrevShown = Shown[Index - 1]
				local NextShown = Shown[Index + 1]
				if Index == 1 then
					if NextShown then
						table.insert(Parts, Text)
					end
				elseif Index == #Segments then
					if PrevShown then
						table.insert(Parts, Text)
					end
				elseif PrevShown and NextShown then
					table.insert(Parts, Text)
elseif PrevShown ~= NextShown then
				-- A joiner (", ", ":", " and ") becomes a space; a unit suffix like "m " sticks to its shown unit
				local Stripped = Segment.Text:gsub("[%s,:]", "")
				if Stripped == "" or Stripped == "and" then
					table.insert(Parts, " ")
				elseif PrevShown then
					table.insert(Parts, Segment.Text)
				end
			end
			end
		end
	end

	local Result = table.concat(Parts)
	if Template:find(":") then
		Result = Result:gsub("^[%s:]+", ""):gsub("[%s:]+$", ""):gsub("::+", ":")
	else
		Result = Result:gsub("^[%s,]+", ""):gsub("[%s,]+$", ""):gsub(" +", " ")
	end

	return Result
end

-- Shared helper: formats a unix timestamp into a date/time template. Tokens:
-- {y} 4-digit year, {yy} 2-digit year, {mo} month (zero-padded), {d} day, {dd} zero-padded day,
-- {h} hour, {hh} zero-padded hour, {m} minute, {mm} zero-padded minute, {s} second, {ss} zero-padded second,
-- {Month} full month name, {Mon} abbreviated month name, {Day} weekday name. Everything else is literal text.
local function formatDate(UnixTimestamp: number, Template: string): string
	local T = os.date("*t", UnixTimestamp)
	local MonthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
	local MonthAbbrev = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
	local DayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

	local function pad(Value: number): string
		return string.format("%02d", Value)
	end

	return Template:gsub("{(%a+)}", function(Token)
		if Token == "y" then return tostring(T.year) end
		if Token == "yy" then return tostring(T.year % 100) end
		if Token == "mo" then return pad(T.month) end
		if Token == "d" then return tostring(T.day) end
		if Token == "dd" then return pad(T.day) end
		if Token == "h" then return tostring(T.hour) end
		if Token == "hh" then return pad(T.hour) end
		if Token == "m" then return tostring(T.min) end
		if Token == "mm" then return pad(T.min) end
		if Token == "s" then return tostring(T.sec) end
		if Token == "ss" then return pad(T.sec) end
		if Token == "Month" then return MonthNames[T.month] end
		if Token == "Mon" then return MonthAbbrev[T.month] end
		if Token == "Day" then return DayNames[T.wday] end
		return "{" .. Token .. "}"
	end)
end

-- Formats a unix timestamp into a date/time string.
-- Format can be a preset ("DateTime" (default) → "2026-09-02 14:30:45", "Date" → "2026-09-02",
-- "Clock" → "14:30:45", "Short" → "2 Sep 26", "Long" → "2 September 2026") or a custom template
-- using the tokens documented on formatDate (e.g. "{h}:{mm}:{ss}" for an unpadded clock).
function Utils.FormatTime(UnixTimestamp: number, Format: string?): string
	local Template: string
	if Format == nil or Format == "DateTime" then
		Template = "{yy}-{mo}-{dd} {hh}:{mm}:{ss}"
	elseif Format == "Date" then
		Template = "{yy}-{mo}-{dd}"
	elseif Format == "Clock" then
		Template = "{hh}:{mm}:{ss}"
	elseif Format == "Short" then
		Template = "{d} {Mon} {y}"
	elseif Format == "Long" then
		Template = "{d} {Month} {y}"
	else
		Template = Format
	end

	return formatDate(UnixTimestamp, Template)
end

-- Formats a unix timestamp as a relative timestamp against now: "Just now", "5 minutes ago", "in 2 days and 13 hours".
-- Past timestamps get "ago", future ones get "in ...". Short uses compact units ("in 2d 13h").
-- Format accepts the same presets/templates as FormatTime and overrides Short when given.
function Utils.FormatRelativeTime(UnixTimestamp: number, Short: boolean?, Format: string?): string
	local Difference = UnixTimestamp - os.time()
	local Template: string?
	local DefaultVerbose = false
	if Format == "Clock" then
		Template = "{hh}:{mm}:{ss}"
	elseif Format == "Short" then
		Template = "{h}h {m}m {s}s"
	elseif Format == "Long" or (Format == nil and not Short) then
		Template = "{years}, {months}, {weeks}, {days}, {hours}, {minutes} and {seconds}"
		DefaultVerbose = Format == nil and not Short
	elseif Format == nil and Short then
		Template = "{y}y {mo}mo {w}w {d}d {h}h {m}m {s}s"
	else
		Template = Format
	end

	local Result = formatDuration(math.abs(Difference), nil, Template)
	-- The default verbose style joins its last two units with "and" even when middle units are skipped
	if DefaultVerbose and not Result:find(" and ") then
		Result = Result:gsub(",(%s+)([^,]+)$", " and %2")
	end
	if Result == "" then
		return "Just now"
	end

	return (Difference < 0 and `{Result} ago` or `in {Result}`)
end

-- Returns how far in the future UnixTimestamp is (UnixTimestamp - os.time()), in seconds.
-- Negative means it's in the past: TimeDifference(os.time() - 300) == -300, TimeDifference(os.time() + 600) == 600.
function Utils.TimeDifference(UnixTimestamp: number): number
	return UnixTimestamp - os.time()
end

-- Formats a duration (in seconds) as a countdown string.
-- Format presets: "Clock" (default) → hh:mm:ss, "MMSS" → mm:ss with total minutes (can exceed 59),
-- "Short" → 5h 4m 3s, "Long" → 5 hours, 4 minutes and 3 seconds. Custom templates use the same
-- tokens as the duration engine: {h} {m} {s} (omitted when zero), {hh} {mm} {ss} (always shown,
-- zero-padded), and word tokens like {hours} {minutes} {seconds} (pluralized).
function Utils.FormatCountdown(Seconds: number, Format: string?): string
	if Format == "MMSS" then
		return string.format("%02d:%02d", math.floor(Seconds / 60), math.floor(Seconds % 60))
	end

	local Template: string
	if Format == nil or Format == "Clock" then
		Template = "{hh}:{mm}:{ss}"
	elseif Format == "Short" then
		Template = "{h}h {m}m {s}s"
	elseif Format == "Long" then
		Template = "{hours}, {minutes} and {seconds}"
	else
		Template = Format
	end

	return formatDuration(Seconds, nil, Template)
end

-- Time Conversion
-- Converts a time value in the given Unit (e.g., "Minutes") to milliseconds.
function Utils.ToMilliseconds(Time: number, Unit: string): number
	local Conversion = {
		Seconds = 1000,
		Minutes = 60000,
		Hours = 3600000,
		Days = 86400000,
		Weeks = 604800000,
		Months = 2592000000,
		Years = 31536000000
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Hours") to seconds.
function Utils.ToSeconds(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.001,
		Minutes = 60,
		Hours = 3600,
		Days = 86400,
		Weeks = 604800,
		Months = 2592000,
		Years = 31536000
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Seconds") to minutes.
function Utils.ToMinutes(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.0000166667,
		Seconds = 0.0166667,
		Hours = 60,
		Days = 1440,
		Weeks = 10080,
		Months = 43200,
		Years = 525600
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Minutes") to hours.
function Utils.ToHours(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.000000277778,
		Seconds = 0.000277778,
		Minutes = 0.0166667,
		Days = 24,
		Weeks = 168,
		Months = 720,
		Years = 8760
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Hours") to days.
function Utils.ToDays(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.0000000115741,
		Seconds = 0.0000115741,
		Minutes = 0.000694444,
		Hours = 0.0416667,
		Weeks = 7,
		Months = 30,
		Years = 365
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Days") to weeks.
function Utils.ToWeeks(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.00000000165344,
		Seconds = 0.00000165344,
		Minutes = 0.0000992063,
		Hours = 0.00595238,
		Days = 0.142857,
		Months = 4.28571,
		Years = 52.1429
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Weeks") to months.
function Utils.ToMonths(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.000000000385802,
		Seconds = 0.000000385802,
		Minutes = 0.0000231481,
		Hours = 0.00138889,
		Days = 0.0333333,
		Weeks = 0.233333,
		Years = 12
	}
	return Time * (Conversion[Unit] or 1)
end

-- Converts a time value in the given Unit (e.g., "Months") to years.
function Utils.ToYears(Time: number, Unit: string): number
	local Conversion = {
		Milliseconds = 0.0000000000317098,
		Seconds = 0.0000000317098,
		Minutes = 0.00000190259,
		Hours = 0.000114155,
		Days = 0.00273973,
		Weeks = 0.0191781,
		Months = 0.0833333
	}
	return Time * (Conversion[Unit] or 1)
end

--[[ Instance Manipulation
    -- Instance manipulation functions are useful for working with Roblox instances. Here are some common functions:

    --- Subcategory: Instance Searching
        -- Utils.GetChildrenOfClass: Returns all children of a given class type.
        -- Utils.GetDescendantsOfClass: Returns all descendants of a given class type.

    --- Subcategory: Attribute/Property Manipulation
        -- Utils.GetAttributes: Returns a table of all attributes of an instance.
        -- Utils.GetProperties: Returns a table of all properties of an instance.
        -- Utils.SetAttributes: Sets multiple attributes of an instance from a table.
        -- Utils.CopyAttributes: Copies all attributes from one instance to another.
        -- Utils.CopyProperties: Copies all properties from one instance to another.
        -- Utils.AttributeDiff: Compares the attributes of two instances OR one instance and a table of default attributes and returns a table containing the differences.
        -- Utils.PropertyDiff: Compares the properties of two instances OR one instance and that instance's class' default properties and returns a table containing the differences.
        -- Utils.HasAttribute: Checks if an instance has a specific attribute.
        -- Utils.HasProperty: Checks if an instance has a specific property.
    -- Maybe more soon?
]]

-- Instance Searching
-- Returns all direct children of Instance that are of class ClassName (or a subclass of it).
function Utils.GetChildrenOfClass(Instance: Instance, ClassName: string): {Instance}
	local Children = {}
	for _, Child in ipairs(Instance:GetChildren()) do
		if Child:IsA(ClassName) then
			table.insert(Children, Child)
		end
	end
	return Children
end

-- Returns all descendants of Instance that are of class ClassName (or a subclass of it).
function Utils.GetDescendantsOfClass(Instance: Instance, ClassName: string): {Instance}
	local Descendants = {}
	for _, Descendant in ipairs(Instance:GetDescendants()) do
		if Descendant:IsA(ClassName) then
			table.insert(Descendants, Descendant)
		end
	end
	return Descendants
end

-- Attribute/Property Manipulation
-- Returns a table of all attributes set on Instance.
function Utils.GetAttributes(Instance: Instance): GenericTable
	return Instance:GetAttributes()
end

-- Returns a table of all readable value properties of Instance (only properties readable by Basic, user-script security are included).
function Utils.GetProperties(Instance: Instance): GenericTable
	local Properties = {}

	local PropertyList = Utils.PropertyListCache[Instance.ClassName]
	if PropertyList == nil then
		local Success, List = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, Instance.ClassName, {
			Security = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
		})
		if not Success then
			return Properties
		end
		PropertyList = List
		Utils.PropertyListCache[Instance.ClassName] = List
	end

	for _, Property in ipairs(PropertyList) do
		local ReadSuccess, Value = pcall(function()
			return (Instance :: any)[Property.Name]
		end)

		if ReadSuccess then
			Properties[Property.Name] = Value
		end
	end

	return Properties
end

-- Sets multiple attributes on Instance from a table of name to value pairs.
function Utils.SetAttributes(Instance: Instance, Attributes: GenericTable)
	for AttributeName, AttributeValue in pairs(Attributes) do
		Instance:SetAttribute(AttributeName, AttributeValue)
	end
end

-- Copies all attributes from Source to Target.
function Utils.CopyAttributes(Source: Instance, Target: Instance)
	local Attributes = Utils.GetAttributes(Source)
	Utils.SetAttributes(Target, Attributes)
end

-- Copies all writable value properties from Source to Target (only properties writable by Basic, user-script security are included). Skips read-only properties and Parent.
function Utils.CopyProperties(Source: Instance, Target: Instance)
	local PropertyList = Utils.PropertyListCache[Source.ClassName]
	if PropertyList == nil then
		local Success, List = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, Source.ClassName, {
			Security = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
		})
		if not Success then
			return
		end
		PropertyList = List
		Utils.PropertyListCache[Source.ClassName] = List
	end

	for _, Property in ipairs(PropertyList) do
		if Property.Permits.Write ~= nil and Property.Name ~= "Parent" then
			local ReadSuccess, Value = pcall(function()
				return (Source :: any)[Property.Name]
			end)

			if ReadSuccess then
				pcall(function()
					(Target :: any)[Property.Name] = Value
				end)
			end
		end
	end
end

-- Compares the attributes of Instance against another instance's or a table of attributes, returning {InstanceValue, ComparisonValue} for each difference. Attributes only on the comparison appear as {nil, ComparisonValue}.
function Utils.AttributeDiff(Instance: Instance, Comparison: Instance | GenericTable): GenericTable
	local Diff = {}
	local InstanceAttributes = Utils.GetAttributes(Instance)
	local ComparisonAttributes = {}

	if typeof(Comparison) == "table" then
		ComparisonAttributes = Comparison
	elseif typeof(Comparison) == "Instance" then
		ComparisonAttributes = Utils.GetAttributes(Comparison)
	end

	for AttributeName, AttributeValue in pairs(InstanceAttributes) do
		if ComparisonAttributes[AttributeName] ~= AttributeValue then
			Diff[AttributeName] = {AttributeValue, ComparisonAttributes[AttributeName]}
		end
	end

	for AttributeName, AttributeValue in pairs(ComparisonAttributes) do
		if InstanceAttributes[AttributeName] == nil then
			Diff[AttributeName] = {nil, AttributeValue}
		end
	end

	return Diff
end

-- Compares the properties of InputtedInstance against another instance's properties, a table of properties, or (if omitted) the class' default properties, returning {InstanceValue, ComparisonValue} for each difference.
function Utils.PropertyDiff(InputtedInstance: Instance, Comparison: Instance | GenericTable?): GenericTable
	local Diff = {}
	local ComparisonProperties = {}

	if typeof(Comparison) == "table" then
		ComparisonProperties = Comparison
	elseif typeof(Comparison) == "Instance" then
		ComparisonProperties = Utils.GetProperties(Comparison)
	else
		local Success, DefaultInstance = pcall(Instance.new, InputtedInstance.ClassName)
		if Success then
			ComparisonProperties = Utils.GetProperties(DefaultInstance)
			DefaultInstance:Destroy()
		end
	end

	local InstanceProperties = Utils.GetProperties(InputtedInstance)

	for PropertyName, PropertyValue in pairs(InstanceProperties) do
		if ComparisonProperties[PropertyName] ~= PropertyValue then
			Diff[PropertyName] = {PropertyValue, ComparisonProperties[PropertyName]}
		end
	end

	for PropertyName, PropertyValue in pairs(ComparisonProperties) do
		if InstanceProperties[PropertyName] == nil then
			Diff[PropertyName] = {nil, PropertyValue}
		end
	end

	return Diff
end

-- Returns true if Instance has an attribute named AttributeName.
function Utils.HasAttribute(Instance: Instance, AttributeName: string): boolean
	return Instance:GetAttribute(AttributeName) ~= nil
end

-- Returns true if Instance has a property named PropertyName.
function Utils.HasProperty(Instance: Instance, PropertyName: string): boolean
	local PropertyList = Utils.PropertyListCache[Instance.ClassName]
	if PropertyList == nil then
		local Success, List = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, Instance.ClassName, {
			Security = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
		})
		if not Success then
			return false
		end
		PropertyList = List
		Utils.PropertyListCache[Instance.ClassName] = List
	end

	for _, Property in ipairs(PropertyList) do
		if Property.Name == PropertyName then
			return true
		end
	end

	return false
end

--[[ Value Utilities
    -- Value utility functions are useful for working with generic values in Roblox. Here are some common functions:
    -- Utils.Coalesce: Returns the first non-nil value from a list of values.
    -- Utils.Default: Returns the value if it is not nil, otherwise returns the default value.
    -- Utils.Fallback: Returns the value if it is not nil, otherwise returns the fallback value in order from a table until a non-nil value is found.
    -- Utils.Negate: Returns the inverse of the value inputted.
    -- Utils.Toggle: Returns the opposite of the boolean value inputted.
]]

-- Returns the first non-nil argument.
function Utils.Coalesce(...: any): any
	for Index = 1, select("#", ...) do
		local Value = select(Index, ...)
		if Value ~= nil then
			return Value
		end
	end
	return nil
end

-- Returns Value if it isn't nil, otherwise returns DefaultValue.
function Utils.Default(Value: any, DefaultValue: any): any
	if Value ~= nil then
		return Value
	end

	return DefaultValue
end

-- Returns Value if it isn't nil, otherwise returns the first non-nil value from Fallbacks.
function Utils.Fallback(Value: any, Fallbacks: {any}): any
	if Value ~= nil then
		return Value
	end

	for _, FallbackValue in pairs(Fallbacks) do
		if FallbackValue ~= nil then
			return FallbackValue
		end
	end

	return nil
end

-- If a boolean is inputted, it will return the opposite boolean.
-- If a number is inputted, it will return the negative of that number.
-- If a string is inputted, it will return the reversed string.
-- If a table is inputted, it will return a new table with all values negated.
-- Does not support cyclic tables. If a cyclic table is inputted, it will recurse infinitely.
function Utils.Negate(Value: any): any
	if type(Value) == "boolean" then
		return not Value
	elseif type(Value) == "number" then
		return -Value
	elseif type(Value) == "string" then
		return Value:reverse()
	elseif type(Value) == "table" then
		local NegatedTable = {}
		for Key, Val in pairs(Value) do
			NegatedTable[Key] = Utils.Negate(Val)
		end
		return NegatedTable
	else
		return nil
	end
end

-- Returns the opposite of the given boolean.
function Utils.Toggle(Value: boolean): boolean
	return not Value
end

--[[ Task/Threading/Delay Utilities
    -- Task utility functions are useful for working with tasks, threads, and delays in Roblox. Here are some common functions:
    -- Utils.Debounce: Returns a function that will only execute when the previous call has finished.
    -- Utils.Throttle: Returns a function that will only execute once every Delay seconds.
    -- Utils.Backoff: Returns a function that will execute after a certain amount of time has passed since the last call, with an increasing delay each time.
]]

-- Returns a function that only calls Function when the previous call has finished.
-- While Function is still running, calls return nil; once it returns, the next call runs.
function Utils.Debounce(Function: (...any) -> any): (...any) -> any
	local Busy = false

	return function(...)
		if Busy then
			return nil
		end

		Busy = true

		local Success, Result = pcall(Function, ...)

		Busy = false

		if not Success then
			error(Result, 2)
		end

		return Result
	end
end

-- Returns a function that only calls Function once every Delay seconds; throttled calls return nil.
-- Delay can be a number (scaled by InitialDelay, default 1) or a function that computes the delay from the arguments.
function Utils.Throttle(Function: (...any) -> any, Delay: ((...any) -> number) | number, InitialDelay: number?): (...any) -> any
	local LastCall = 0

	return function(...)
		local Now = os.clock()

		local CurrentDelay: number
		if type(Delay) == "function" then
			CurrentDelay = Delay(...)
		else
			CurrentDelay = Delay * (InitialDelay or 1)
		end

		if Now - LastCall < CurrentDelay then
			return nil
		end

		LastCall = Now

		return Function(...)
	end
end

-- Returns an object with a BackoffFunction that calls Function once per delay cycle, and a live CallCount of calls made.
-- If Delay is a function, it is called with the arguments to get the delay; if it is a number, the delay is Delay * InitialDelay (InitialDelay defaults to 1).
-- With CallLimit, the function stops after that many calls.
function Utils.Backoff(Function: GenericFunction, Delay: ((...any) -> number) | number, CallLimit: number?, InitialDelay: number?): {BackoffFunction: GenericFunction, CallCount: number}
	local State = {CallCount = 0}

	State.BackoffFunction = function(...)
		if CallLimit and State.CallCount >= CallLimit then
			return
		end

		State.CallCount += 1

		local CurrentDelay: number
		if type(Delay) == "function" then
			CurrentDelay = Delay(...)
		else
			CurrentDelay = Delay * (InitialDelay or 1)
		end

		local Args = {...}
		task.delay(CurrentDelay, function()
			Function(table.unpack(Args))
			State.BackoffFunction(table.unpack(Args))
		end)
	end

	return State
end

-- Creates a repeating timer control object: Start() runs Function every Seconds (firing OnAdvance with the
-- tick count), Stop() halts it, Reset() restarts the tick count (keeps running if it was). OnStart, OnStop,
-- OnReset and OnAdvance(TickCount) are Utils Signals. If LoopCount is given, the timer stops automatically
-- after that many ticks and fires OnLooped(TickCount).
function Utils.Interval(Seconds: number, Function: ((TickCount: number) -> ())?, LoopCount: number?): GenericTable
	local Interval = {}

	local Meta: any = {
		Running = false,
		TickCount = 0,
		Connection = nil,
		OnStart = Utils.NewSignal(),
		OnStop = Utils.NewSignal(),
		OnReset = Utils.NewSignal(),
		OnAdvance = Utils.NewSignal(),
		OnLooped = Utils.NewSignal(),
	}

	local function Tick()
		Meta.TickCount += 1

		if Function then
			Function(Meta.TickCount)
		end

		Meta.OnAdvance:Fire(Meta.TickCount)

		if LoopCount and Meta.TickCount >= LoopCount then
			Meta.OnLooped:Fire(Meta.TickCount)
			Meta.Running = false
			Meta.Connection = nil
			Meta.OnStop:Fire()
			return
		end

		Meta.Connection = task.delay(Seconds, Tick)
	end

	Meta.__index = function(_, Key): any
		if Key == "Start" then
			return function()
				if Meta.Running then
					return
				end
				Meta.Running = true
				Meta.TickCount = 0
				Meta.OnStart:Fire()
				Meta.Connection = task.delay(Seconds, Tick)
			end
		elseif Key == "Stop" then
			return function()
				if not Meta.Running then
					return
				end
				Meta.Running = false
				if Meta.Connection then
					Meta.Connection:Cancel()
				end
				Meta.Connection = nil
				Meta.OnStop:Fire()
			end
		elseif Key == "Reset" then
			return function()
				local WasRunning = Meta.Running
				if Meta.Connection then
					Meta.Connection:Cancel()
				end
				Meta.Connection = nil
				Meta.Running = false
				Meta.TickCount = 0
				Meta.OnReset:Fire()
				if WasRunning then
					Meta.Running = true
					Meta.Connection = task.delay(Seconds, Tick)
				end
			end
		elseif Key == "OnStart" then
			return Meta.OnStart
		elseif Key == "OnStop" then
			return Meta.OnStop
		elseif Key == "OnReset" then
			return Meta.OnReset
		elseif Key == "OnAdvance" then
			return Meta.OnAdvance
		elseif Key == "OnLooped" then
			return Meta.OnLooped
		end

		return nil
	end

	return (setmetatable(Interval, Meta) :: any) :: GenericTable
end

-- Calls Function with the given arguments; if it errors, retries up to Attempts total calls,
-- waiting Delay seconds between attempts. Returns the first successful result, or nil, ErrorMessage
-- when every attempt fails.
function Utils.Retry(Function: (...any) -> any, Attempts: number, Delay: number?, ...: any): any
	local LastError: any = nil
	for Attempt = 1, Attempts do
		local Success, Result = pcall(Function, ...)
		if Success then
			return Result
		end

		LastError = Result
		if Attempt < Attempts and Delay ~= nil and Delay > 0 then
			task.wait(Delay)
		end
	end

	return nil, LastError
end

--[[ Function Utilities
    -- Function utility functions (sounds weird i know) are useful for working with functions in Luau. Here are some common functions:
    -- Utils.Once: Returns a function that will only execute once, no matter how many times it is called.
	-- Utils.Memoize: Returns a function that if the same inputs are given, it will return a cached value.
]]

function Utils.Once(Function: GenericFunction): GenericFunction
	local HasRun = false
	return function(...)
		if not HasRun then
			HasRun = true
			Function(...)
		end
	end
end

-- Returns a function that caches the result of Function per unique set of arguments.
-- Keys are built by VALUE: primitives compare by value, tables are compared deeply (order-independent,
-- cycle-safe), and function arguments are computed (called with no arguments) and keyed by their result.
-- A function argument that is itself a Memoize wrapper is treated as stable by identity instead of being
-- called. Nil results are cached too. The cache lives in Utils.MemoizeCache, keyed by the original function.
function Utils.Memoize(Function: GenericFunction): GenericFunction
	local Cache = Utils.MemoizeCache[Function] or {}

	local function BuildKey(Value: any, Visited: {[any]: boolean}, Depth: number): string
		local ValueType = type(Value)
		if ValueType == "boolean" or ValueType == "number" or ValueType == "string" or ValueType == "nil" then
			return `{ValueType}:{tostring(Value)}`
		end

		if Depth > 32 or Visited[Value] then
			return `{ValueType}:{tostring(Value)}`
		end

		if ValueType == "function" then
			if Utils.MemoizedFunctionSet[Value] then
				return `function:{tostring(Value)}`
			end

			local Success, Result = pcall(Value)
			if Success then
				return `function({BuildKey(Result, Visited, Depth + 1)})`
			end

			return `function:{tostring(Value)}`
		end

		if ValueType == "table" then
			Visited[Value] = true
			local KeyParts = {}
			for Key, Child in pairs(Value) do
				table.insert(KeyParts, `{BuildKey(Key, Visited, Depth + 1)}={BuildKey(Child, Visited, Depth + 1)}`)
			end
			table.sort(KeyParts)
			Visited[Value] = nil

			return "table({" .. table.concat(KeyParts, "&") .. "})"
		end

		return `{ValueType}:{tostring(Value)}`
	end

	local Wrapper: GenericFunction = function(...)
		local Args = {...}
		local KeyParts = {}
		local Visited = {}
		for _, Arg in ipairs(Args) do
			table.insert(KeyParts, BuildKey(Arg, Visited, 0))
		end
		local Key = table.concat(KeyParts, "|")

		if Cache[Key] ~= nil then
			return Cache[Key][1]
		end

		local Result = Function(...)
		Cache[Key] = {Result}

		return Result
	end

	Utils.MemoizedFunctionSet[Wrapper] = true

	return Wrapper
end

--[[ Color Utilities
    -- Color utility functions are useful for working with colors in Roblox. Here are some common functions:
    -- Utils.InvertColor: Returns the inverted color of the inputted Color3.
    -- Utils.GrayscaleColor: Returns the grayscale version of the inputted Color3.
    -- Utils.LightenColor: Returns a lighter version of the inputted Color3 by a given factor.
    -- Utils.DarkenColor: Returns a darker version of the inputted Color3 by a given factor.
    -- Utils.GetColorBrightness: Returns the perceived brightness of the inputted Color3.

	--- Subcategory: Color Palettes
		-- Utils.NewColorPalette: Creates a new ColorPalette table and saves it for future use.
        -- Tweens created with NewColorPalette are stored in Utils.ColorPalettes and can be accessed by name.
        -- You can optimize memory usage by setting IsColorStorageWeak to true, which will weakly reference the stored ColorPalettes and allow them to be garbage collected if memory usage is high.
            -- This may cause some of the created ColorPalettes to be destroyed, so use with caution.
		-- This function might be extremely useless but I dont really know
]]

function Utils.InvertColor(Color: Color3): Color3
	return Color3.new(1 - Color.R, 1 - Color.G, 1 - Color.B)
end

function Utils.GrayscaleColor(Color: Color3): Color3
	local Gray = (Color.R + Color.G + Color.B) / 3
	return Color3.new(Gray, Gray, Gray)
end

function Utils.LightenColor(Color: Color3, Factor: number): Color3
	local R = math.clamp(Color.R + Factor, 0, 1)
	local G = math.clamp(Color.G + Factor, 0, 1)
	local B = math.clamp(Color.B + Factor, 0, 1)
	return Color3.new(R, G, B)
end

function Utils.DarkenColor(Color: Color3, Factor: number): Color3
	local R = math.clamp(Color.R - Factor, 0, 1)
	local G = math.clamp(Color.G - Factor, 0, 1)
	local B = math.clamp(Color.B - Factor, 0, 1)
	return Color3.new(R, G, B)
end

function Utils.GetColorBrightness(Color: Color3): number
	return (Color.R * 0.299 + Color.G * 0.587 + Color.B * 0.114)
end

-- Returns black or white, whichever contrasts Color the most (same weights as GetColorBrightness,
-- thresholded at 186/255 like the classic "optimal" text color rule).
function Utils.GetContrastColor(Color: Color3): Color3
	local Brightness = Color.R * 0.299 + Color.G * 0.587 + Color.B * 0.114
	if Brightness <= 0.729 then
		return Color3.new(1, 1, 1)
	end

	return Color3.new()
end

-- Creates a ColorPalette table from the given colors, stores it in Utils.ColorPalettes under Name, and returns it.
-- BackgroundColor and TextColor are optional; they're affected by the IsColorStorageWeak setting like TweenInfos.
function Utils.NewColorPalette(Name: string, PrimaryColor: Color3, AccentColor: Color3, SecondaryColor: Color3, ComplementaryColor: Color3, BackgroundColor: Color3?, TextColor: Color3?): ColorPalette
	Utils.ColorPalettes[Name] = {
		PrimaryColor = PrimaryColor,
		AccentColor = AccentColor,
		SecondaryColor = SecondaryColor,
		ComplementaryColor = ComplementaryColor,

		BackgroundColor = BackgroundColor,
		TextColor = TextColor
	}

	return Utils.ColorPalettes[Name]
end

--[[ UI Utilities
    -- UI utility functions are useful for working with Roblox UI elements. Here are some common functions:
    -- Utils.NewContrastWipe: Creates a sharp two-color wipe where content is always the inverse of what's behind it.
    -- Maybe more soon?
]]

-- Creates a contrast wipe and returns a ContrastWipe control object: Play() runs the wipe (restartable), Pause()/Resume() stop and continue it,
-- Cancel() cancels it, Wait() yields until the wipe finishes, and OnFinished is a Utils Signal that fires when the wipe completes. Nothing plays until Play() is called.
-- Uses UIGradients: the Background (color A) sweeps to color B (RevealedColor or the content's own color), and a duplicate copy of Content
-- sits on top with the opposite gradient, so the content always shows the color that contrasts its side of the wipe. No clips, no position math.
-- StartDirection can be a direction ("Left"/"Right"/"Up"/"Down", default "Right") or any angle in degrees (e.g. 127).
-- TweenInfo can be an existing Utils.TweenInfos name or a raw TweenInfo.
function Utils.NewContrastWipe(Background: GuiObject, Content: GuiObject, TweenInfo: TweenInfo | string, RevealedColor: Color3?, StartDirection: Direction | number?): ContrastWipe
	local Info: TweenInfo
	if type(TweenInfo) == "string" then
		Info = Utils.TweenInfos[TweenInfo]
		if not Info then
			error(`[Utils - UI] TweenInfo "{TweenInfo}" was not found in Utils.TweenInfos`)
		end
	else
		Info = TweenInfo
	end

	if not Info then
		error(`[Utils - UI] Expected a TweenInfo or a Utils.TweenInfos name, got {typeof(TweenInfo)}`)
	end

	local BackgroundColor = Background.BackgroundColor3
	local Revealed: Color3
	if typeof(RevealedColor) == "Color3" then
		Revealed = RevealedColor
	else
		Revealed = Content.BackgroundColor3
		if Content:IsA("TextLabel") or Content:IsA("TextButton") then
			Revealed = (Content :: TextLabel).TextColor3
		elseif Content:IsA("ImageLabel") or Content:IsA("ImageButton") then
			Revealed = (Content :: ImageLabel).ImageColor3
		end
	end

	local Direction = StartDirection or "Right"
	local Rotation = 0
	if Direction == "Right" then
		Rotation = 0
	elseif Direction == "Left" then
		Rotation = 180
	elseif Direction == "Up" then
		Rotation = 90
	elseif Direction == "Down" then
		Rotation = 270
	elseif type(Direction) == "number" then
		Rotation = Direction
	else
		error(`[Utils - UI] Invalid StartDirection "{tostring(StartDirection)}"; expected "Left", "Right", "Up", "Down" or an angle in degrees`)
	end

	-- The park side flips with the gradient's orientation: the first half of the rotation circle parks the
	-- boundary at +1, the second half parks it at -1 (a fixed sign would invert half the angles)
	local RestSign = (Rotation % 360) < 180 and 1 or -1

	-- The background is a hard-edged sweep from its own color to the revealed color
	-- (the boundary is a sharp line: keypoints jump at position 0.5, and Offset moves it)
	local BackgroundGradient = Instance.new("UIGradient")
	BackgroundGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BackgroundColor),
		ColorSequenceKeypoint.new(0.499, BackgroundColor),
		ColorSequenceKeypoint.new(0.501, Revealed),
		ColorSequenceKeypoint.new(1, Revealed),
	})
	BackgroundGradient.Rotation = Rotation
	BackgroundGradient.Parent = Background

	-- A duplicate copy of the content sits on top, unchanged, with the opposite gradient:
	-- the opacity holds at 0 until the boundary position, then jumps straight to 1
	local MaskedCopy = Content:Clone() :: GuiObject
	MaskedCopy.ZIndex = Content.ZIndex + 1
	MaskedCopy.Parent = Content.Parent

	local ContentGradient = Instance.new("UIGradient")
	ContentGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.499, 0),
		NumberSequenceKeypoint.new(0.501, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	ContentGradient.Rotation = Rotation
	ContentGradient.Parent = MaskedCopy

	-- The original content becomes the "revealed" layer: recolored to the background's color
	local RecolorObjects = {Content}
	for _, Descendant in ipairs(Content:GetDescendants()) do
		if Descendant:IsA("GuiObject") then
			table.insert(RecolorObjects, Descendant)
		end
	end
	for _, Object in ipairs(RecolorObjects) do
		if Object:IsA("UIStroke") then
			local StrokeObject = Object :: UIStroke
			StrokeObject.Color = BackgroundColor
		else
			Object.BackgroundColor3 = BackgroundColor
			Object.BorderColor3 = BackgroundColor

			if Object:IsA("TextLabel") or Object:IsA("TextButton") then
				local TextObject = Object :: TextLabel
				TextObject.TextColor3 = BackgroundColor
				TextObject.TextStrokeColor3 = BackgroundColor
			elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
				local ImageObject = Object :: ImageLabel
				ImageObject.ImageColor3 = BackgroundColor
			end
		end
	end

	-- Rest state: boundary parked off the first side (a full axis-length out, so it fully covers any angle)
	BackgroundGradient.Offset = Vector2.new(RestSign, 0)
	ContentGradient.Offset = Vector2.new(RestSign, 0)

	local OnFinished = Utils.NewSignal()
	local BackgroundTween: Tween?
	local ContentTween: Tween?

	local function Play()
		if BackgroundTween then
			BackgroundTween:Cancel()
		end
		if ContentTween then
			ContentTween:Cancel()
		end

		BackgroundGradient.Offset = Vector2.new(RestSign, 0)
		ContentGradient.Offset = Vector2.new(RestSign, 0)

		local NewBackgroundTween = TweenService:Create(BackgroundGradient, Info, {
			Offset = Vector2.new(-RestSign, 0)
		})
		local NewContentTween = TweenService:Create(ContentGradient, Info, {
			Offset = Vector2.new(-RestSign, 0)
		})
		BackgroundTween = NewBackgroundTween
		ContentTween = NewContentTween

		NewBackgroundTween.Completed:Connect(function(State)
			if State == Enum.PlaybackState.Completed then
				OnFinished:Fire()
			end
		end)

		NewBackgroundTween:Play()
		NewContentTween:Play()
	end

	local function Cancel()
		if BackgroundTween then
			BackgroundTween:Cancel()
		end
		if ContentTween then
			ContentTween:Cancel()
		end
	end

	local function Pause()
		if BackgroundTween then
			BackgroundTween:Pause()
		end
		if ContentTween then
			ContentTween:Pause()
		end
	end

	local function Resume()
		if BackgroundTween then
			BackgroundTween:Play()
		end
		if ContentTween then
			ContentTween:Play()
		end
	end

	local function Wait()
		return Utils.Wait(OnFinished)
	end

	return {
		Play = Play,
		Pause = Pause,
		Resume = Resume,
		Cancel = Cancel,
		Wait = Wait,
		OnFinished = OnFinished,
	}
end

return Utils
