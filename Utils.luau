-- Utils: A collection of utility functions (and modules?) that could be useful.

--!strict
--!native
--!optimize 2

local Utils = {}

--// Config
local IsTweenStorageWeak = true -- If true, stored tweens will be weakly referenced and may be garbage collected if memory usage is high, which can decrease memory usage but may destroy some of the created tweens.

--// Services
local HttpService = game:GetService("HttpService")
local ReflectionService = game:GetService("ReflectionService")

--// Requires
local Signal = require("./Signal")

--// Types
-- Table Types
export type Table = {[any]: any}
export type WeightedTable = {
    [any]: {Weight: number, [any]: any}
}

-- Signal Types
export type SignalConnection = Signal.SignalConnection
export type Signal = Signal.Signal
export type SignalConnectionData = Signal.SignalConnectionData
export type SignalData = Signal.SignalData
export type SignalClassType = Signal.SignalClassType

--// Constants
local WeakTable = {__mode = "v"}

--// Storage
Utils.TweenInfos = {}

--// Initialization
if IsTweenStorageWeak then
    setmetatable(Utils.TweenInfos, WeakTable)
end

--[[ Table manipulation
    -- Table manipulation functions are useful for working with tables in Lua. Here are some common functions:
    -- Utils.DeepCopy: Creates a deep copy of a table, including nested tables.
    -- Utils.DeepDiff: Compares two tables and returns a table containing the differences.
    -- Utils.Shuffle: Randomly shuffles the elements of a table in place.
    -- Utils.Pick: Create a table containing certain keys from the original table.
    -- Utils.Omit: Create a table containing everything except certain keys from the original table.
    -- Utils.Unique: Returns a new table containing only unique values from the original table.
    -- Utils.Merge: Merges two tables together, with the second table overwriting any duplicate keys in the first table.
    -- Utils.Filter: Returns a new table containing only the elements that pass a given filter function.
    -- Maybe more soon?
]]

-- SkipJSON Paramater goes directly to a looping fallback if true. Setting it to true would only be useful if you know the table contains non-serializable data. 
function Utils.DeepCopy(Table: Table, SkipJSON: boolean?): Table
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

function Utils.DeepDiff(Table1: Table, Table2: Table): Table
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

function Utils.Shuffle(Table: Table, Recursive: boolean?): Table
    local Shuffled = {}
    for _, Value in pairs(Table) do
        if type(Value) == "table" and Recursive then
            Value = Utils.Shuffle(Value, Recursive)
        end
        table.insert(Shuffled, Value)
    end

    for i = #Shuffled, 2, -1 do
        local j = math.random(i)
        Shuffled[i], Shuffled[j] = Shuffled[j], Shuffled[i]
    end

    return Shuffled
end

local function basePickOmit(Table: Table, Keys: {any}, IsPick: boolean): Table
    local Result = {}
    for Key, Value in pairs(Table) do
        local ShouldInclude = table.find(Keys, Key) ~= nil
        if (IsPick and ShouldInclude) or (not IsPick and not ShouldInclude) then
            Result[Key] = Value
        end
    end
    
    return Result
end

function Utils.Pick(Table: Table, Keys: {any}): Table
    return basePickOmit(Table, Keys, true)
end

function Utils.Omit(Table: Table, Keys: {any}): Table
    return basePickOmit(Table, Keys, false)
end

function Utils.Unique(Table: Table, Recursive: boolean?): Table
    local UniqueValues = {}
    local Result = {}

    for _, Value in pairs(Table) do
        if type(Value) == "table" and Recursive then
            Value = Utils.Unique(Value, Recursive)
        end
        if not table.find(UniqueValues, Value) then
            table.insert(UniqueValues, Value)
            table.insert(Result, Value)
        end
    end

    return Result
end

function Utils.Merge(Table1: Table, Table2: Table, Recursive: boolean?): Table
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

function Utils.Filter(Table: Table, FilterFunction: (any) -> boolean, Recursive: boolean?): Table
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

--[[ Signal
    -- Signal is an alternative to BindableEvents that is more efficient and easier to use. 
    -- It allows you to create custom events that can be connected to and fired.
    -- Utils.New: Creates a new event/signal.
    -- Utils.Connect: Connects a listener; returns a connection object that can disconnect it.
    -- Utils.Disconnect: Disconnects a listener connection.
    -- Utils.Fire: Fires the event; every connected listener runs on the recycled runner thread.
    -- Utils.Wait: Yields until the next fire, then returns its arguments.
        -- The listener resumes the caller thread instead of the caller waiting in a busy loop.

    -- Utils.GetListenerCount: Returns the number of connected listeners.

]]

-- Creates a new event/signal
function Utils.New(): Signal
    return Signal.New()
end

-- Connects a listener; returns a connection object that can disconnect it
function Utils.Connect(self: SignalData, Listener: (...any) -> ()): SignalConnection
	return Signal.Connect(self, Listener)
end

-- Disconnects a listener connection
function Utils.Disconnect(self: SignalConnectionData)
	return Signal.Disconnect(self)
end

-- Fires the event; every connected listener runs on the recycled runner thread
function Utils.Fire(self: SignalData, ...: any)
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

--[[ String Manipulation
    -- String manipulation functions are useful for working with strings in Lua. Here are some common functions:
    -- Utils.Trim: Removes leading and trailing whitespace from a string.
    -- Utils.Capitalize: Capitalizes the first letter of a string.
    -- Utils.StartsWith: Checks if a string starts with a given substring.
    -- Utils.EndsWith: Checks if a string ends with a given substring.
    -- Utils.Join: Joins a table of strings into a single string with a given separator. Basically table.concat but under a different name.
    -- Maybe more soon?
]]

function Utils.Trim(String: string): string
    return String:match("^%s*(.-)%s*$") or String
end

function Utils.Capitalize(String: string): string
    return String:sub(1, 1):upper() .. String:sub(2):lower()
end

function Utils.StartsWith(String: string, Substring: string): boolean
    return String:sub(1, #Substring) == Substring
end

function Utils.EndsWith(String: string, Substring: string): boolean
    return String:sub(-#Substring) == Substring
end

function Utils.Join(Separator: string, Strings: {string}, ...: string): string
    local AllStrings = {table.unpack(Strings)}
    for _, Str in ipairs({...}) do
        table.insert(AllStrings, Str)
    end

    return table.concat(AllStrings, Separator)
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
]]

-- Numbers/Math
function Utils.IsEven(Number: number): boolean
    return Number % 2 == 0
end

function Utils.IsOdd(Number: number): boolean
    return Number % 2 ~= 0
end

function Utils.IsClose(Number1: number, Number2: number, Tolerance: number): boolean
    return math.abs(Number1 - Number2) <= Tolerance
end

-- Randomness
function Utils.RandomChoice(Table: Table): any
    local Keys = {}
    for Key in pairs(Table) do
        table.insert(Keys, Key)
    end
    local RandomKey = Keys[math.random(1, #Keys)]
    return Table[RandomKey]
end

function Utils.RandomFloat(Min: number, Max: number, Decimals: number): number
    local Multiplier = 10 ^ Decimals
    return math.floor(math.random() * (Max - Min) * Multiplier + Min * Multiplier) / Multiplier
end

function Utils.RandomWeightedChoice(Table: WeightedTable): any
    local TotalWeight = 0
    for _, Value in pairs(Table) do
        if Value.Weight < 0 then warn("Negative weight detected in RandomWeightedChoice. This may cause unexpected behavior.") end
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

--[[ Tween Utilities
    -- Tween utility functions are useful for creating and managing tweens in Roblox. Here are some common functions:
    -- Utils.NewTweenInfo: Creates a new TweenInfo object and saves it for future use.
        -- Tweens created with NewTweenInfo are stored in Utils.TweenInfos and can be accessed by name.
        -- You can optimize memory usage by setting IsTweenStorageWeak to true, which will weakly reference the stored tweens and allow them to be garbage collected if memory usage is high.
            -- This may cause some of the created tweens to be destroyed, so use with caution.
    -- Maybe more soon?
]]

function Utils.NewTweenInfo(Name: string, Time: number, EasingStyle: Enum.EasingStyle, EasingDirection: Enum.EasingDirection, RepeatCount: number, Reverses: boolean): TweenInfo
    local TweenInfo = TweenInfo.new(Time, EasingStyle, EasingDirection, RepeatCount, Reverses)
    Utils.TweenInfos[Name] = TweenInfo
    return TweenInfo
end

--[[ Time Utilities
    -- Time utility functions are useful for working with time in Roblox. Here are some common functions:
    -- Utils.FormatTime: Formats a time value (in seconds) into a human-readable string (e.g., "1h 30m 45s").
    
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

-- Formats a time value (in seconds) into a human-readable string (e.g., "1h 30m 45s") up to inputted amount (Hours, Days, Weeks, Months, Years).
function Utils.FormatTime(Time: number, MaxUnit: string): string
    local Units = {
        {Name = "Years", Seconds = 31536000},
        {Name = "Months", Seconds = 2592000},
        {Name = "Weeks", Seconds = 604800},
        {Name = "Days", Seconds = 86400},
        {Name = "Hours", Seconds = 3600},
        {Name = "Minutes", Seconds = 60},
        {Name = "Seconds", Seconds = 1}
    }

    local ResultParts = {}
    for _, Unit in ipairs(Units) do
        if Time >= Unit.Seconds then
            local Count = math.floor(Time / Unit.Seconds)
            Time -= Count * Unit.Seconds
            table.insert(ResultParts, Count .. " " .. Unit.Name)
        end
        if Unit.Name == MaxUnit then
            break
        end
    end

    return table.concat(ResultParts, " ")
end

-- Time Conversion
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

function Utils.ToMonths(Time: number, Unit: string): number
    local Conversion = {
        Milliseconds = 0.0000000000382166,
        Seconds = 0.0000000382166,
        Minutes = 0.00000229299,
        Hours = 0.000137579,
        Days = 0.00456621,
        Weeks = 0.142857,
        Years = 12
    }
    return Time * (Conversion[Unit] or 1)
end

function Utils.ToYears(Time: number, Unit: string): number
    local Conversion = {
        Milliseconds = 0.00000000000316888,
        Seconds = 0.00000000316888,
        Minutes = 0.000000190133,
        Hours = 0.000011408,
        Days = 0.000380517,
        Weeks = 0.00547945,
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
function Utils.GetChildrenOfClass(Instance: Instance, ClassName: string): {Instance}
    local Children = {}
    for _, Child in ipairs(Instance:GetChildren()) do
        if Child:IsA(ClassName) then
            table.insert(Children, Child)
        end
    end
    return Children
end

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
function Utils.GetAttributes(Instance: Instance): Table
    return Instance:GetAttributes()
end

function Utils.GetProperties(Instance: Instance): Table
    local Properties = {}

    -- TBD

    return Properties
end

function Utils.SetAttributes(Instance: Instance, Attributes: Table)
    for AttributeName, AttributeValue in pairs(Attributes) do
        Instance:SetAttribute(AttributeName, AttributeValue)
    end
end

function Utils.CopyAttributes(Source: Instance, Target: Instance)
    local Attributes = Utils.GetAttributes(Source)
    Utils.SetAttributes(Target, Attributes)
end

function Utils.CopyProperties(Source: Instance, Target: Instance)
    local Properties = Utils.GetProperties(Source)
    -- TBD
end

function Utils.AttributeDiff(Instance: Instance, Comparision: Instance | Table): Table
    local Diff = {}
    local ComparisionAttributes = {}

    local InstanceAttributes = Utils.GetAttributes(Instance)

    if typeof(Comparision) == "Instance" then
        ComparisionAttributes = InstanceAttributes
    elseif typeof(Comparision) == "table" then
        ComparisionAttributes = Comparision
    end

    for AttributeName, AttributeValue in pairs(InstanceAttributes) do
        if ComparisionAttributes[AttributeName] ~= AttributeValue then
            Diff[AttributeName] = {AttributeValue, ComparisionAttributes[AttributeName]}
        end
    end

    for AttributeName, AttributeValue in pairs(ComparisionAttributes) do
        if not InstanceAttributes[AttributeName] then
            Diff[AttributeName] = {nil, AttributeValue}
        end
    end

    return Diff
end

function Utils.PropertyDiff(InputtedInstance: Instance, Comparision: Table?): Table
    local Diff = {}
    local ComparisionProperties = {}

    if Comparision then
        ComparisionProperties = Comparision
    else
        local DefaultInstance = Instance.new(InputtedInstance.ClassName)
        ComparisionProperties = Utils.GetProperties(DefaultInstance)
        DefaultInstance:Destroy()
    end

    for PropertyName, PropertyValue in pairs(Utils.GetProperties(InputtedInstance)) do
        if ComparisionProperties[PropertyName] ~= PropertyValue then
            Diff[PropertyName] = {PropertyValue, ComparisionProperties[PropertyName]}
        end
    end

    for PropertyName, PropertyValue in pairs(ComparisionProperties) do
        if Utils.GetProperties(InputtedInstance)[PropertyName] == nil then
            Diff[PropertyName] = {nil, PropertyValue}
        end
    end

    return Diff
end

function Utils.HasAttribute(Instance: Instance, AttributeName: string): boolean
    return Instance:GetAttribute(AttributeName) ~= nil
end

function Utils.HasProperty(Instance: Instance, PropertyName: string): boolean
    local Success, _ = pcall(function()
        return Instance[PropertyName]
    end)
    return Success
end

--[[ Value Utilities
    -- Value utility functions are useful for working with generic values in Roblox. Here are some common functions:
    -- Utils.Coalesce: Returns the first non-nil value from a list of values.
    -- Utils.Default: Returns the value if it is not nil, otherwise returns the default value.
    -- Utils.Fallback: Returns the value if it is not nil, otherwise returns the fallback value in order from a table until a non-nil value is found.
    -- Utils.Negate: Returns the inverse of the value inputted.
    -- Utils.Toggle: Returns the opposite of the boolean value inputted.
]]

function Utils.Coalesce(...: any): any
    for _, Value in ipairs({...}) do
        if Value ~= nil then
            return Value
        end
    end
    return nil
end

function Utils.Default(Value: any, DefaultValue: any): any
    return Value ~= nil and Value or DefaultValue
end

function Utils.Fallback(Value: any, Fallbacks: {any}): any
    if Value ~= nil then
        return Value
    end

    for _, FallbackValue in ipairs(Fallbacks) do
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

function Utils.Toggle(Value: boolean): boolean
    return not Value
end

--[[ Task/Threading/Delay Utilities
    -- Task utility functions are useful for working with tasks, threads, and delays in Roblox. Here are some common functions:
    -- Utils.Debounce: Returns a function that will only execute after a certain amount of time has passed since the last call.
    -- Utils.Backoff: Returns a function that will execute after a certain amount of time has passed since the last call, with an increasing delay each time.
]]

function Utils.Debounce(Function: (...any) -> (), Delay: number): (...any) -> ()
    local LastCallTime = 0
    return function(...)
        local CurrentTime = tick()
        if CurrentTime - LastCallTime >= Delay then
            LastCallTime = CurrentTime
            Function(...)
        end
    end
end

-- If delay is a number then IninitialDelay must be given. The delay is calculated as Delay() or Delay * InitialDelay
-- If CallDelay is ommitted then the function will be called indefinitely. If CallLimit is given then the function will only be called that many times.
function Utils.Backoff(Function: (...any) -> (), Delay: (...any) -> number | number, CallLimit: number?, InitialDelay: number?): {BackoffFunction: (...any) -> (), CallCount: number}
    local CallCount = 0
    local BackoffFunction
    BackoffFunction = function(...)
        if CallLimit and CallCount >= CallLimit then
            return
        end

        CallCount += 1
        local CurrentDelay = type(Delay) == "function" and Delay(...) or Delay * (InitialDelay or 1)
        task.delay(CurrentDelay, function()
            Function(...)
            BackoffFunction(...)
        end)
    end

    return {BackoffFunction = BackoffFunction, CallCount = CallCount}
end

return Utils