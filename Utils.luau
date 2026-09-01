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
local WeakValueTable = {__mode = "v"}
local _WeakKeyTable = {__mode = "k"}

--// Storage
Utils.TweenInfos = {}

--// Initialization
if IsTweenStorageWeak then
    setmetatable(Utils.TweenInfos, WeakValueTable)
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
-- Creates a deep copy of a table, including nested tables. Attempts JSON serialization first, then falls back to a recursive copy if the data isn't serializable (or if SkipJSON is true).
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

-- Compares two tables and returns a table of differences. Each diff entry is {Table1Value, Table2Value}; keys only in Table2 appear as {nil, Table2Value}. Nested tables are compared recursively.
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

-- Shuffles the elements of Table in place and returns it. If Recursive, nested tables are shuffled in place too.
function Utils.Shuffle(Table: Table, Recursive: boolean?): Table
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

-- Returns a new table containing only the keys in Keys from Table.
function Utils.Pick(Table: Table, Keys: {any}): Table
    return basePickOmit(Table, Keys, true)
end

-- Returns a new table containing everything from Table except the keys in Keys.
function Utils.Omit(Table: Table, Keys: {any}): Table
    return basePickOmit(Table, Keys, false)
end

-- Returns a new list containing only unique values from Table. If Recursive, nested tables are deduplicated recursively.
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

-- Merges Table2 into a copy of Table1 (Table2 wins on duplicate keys). If Recursive, nested tables are merged recursively.
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

-- Returns a new table with only the values for which FilterFunction returns true. If Recursive, nested tables are filtered recursively.
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
    -- Utils.Trim/Strip: Removes leading and trailing whitespace from a string.
    -- Utils.Capitalize: Capitalizes the first letter of a string.
    -- Utils.StartsWith: Checks if a string starts with a given substring.
    -- Utils.EndsWith: Checks if a string ends with a given substring.
    -- Utils.Join: Joins a table of strings into a single string with a given separator. Basically table.concat but under a different name.
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

-- Randomness
-- Returns a random value from Table.
function Utils.RandomChoice(Table: Table): any
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

--[[ Tween Utilities
    -- Tween utility functions are useful for creating and managing tweens in Roblox. Here are some common functions:
    -- Utils.NewTweenInfo: Creates a new TweenInfo object and saves it for future use.
        -- Tweens created with NewTweenInfo are stored in Utils.TweenInfos and can be accessed by name.
        -- You can optimize memory usage by setting IsTweenStorageWeak to true, which will weakly reference the stored tweens and allow them to be garbage collected if memory usage is high.
            -- This may cause some of the created tweens to be destroyed, so use with caution.
    -- Maybe more soon?
]]

-- Creates a TweenInfo, stores it in Utils.TweenInfos under Name, and returns it.
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

-- Formats a time value (in seconds) into a human-readable string (e.g., "1h 30m 45s"). MaxUnit (default: "Seconds") is the largest unit displayed.
function Utils.FormatTime(Time: number, MaxUnit: string?): string
    local Units = {
        {Name = "Years", Seconds = 31536000},
        {Name = "Months", Seconds = 2592000},
        {Name = "Weeks", Seconds = 604800},
        {Name = "Days", Seconds = 86400},
        {Name = "Hours", Seconds = 3600},
        {Name = "Minutes", Seconds = 60},
        {Name = "Seconds", Seconds = 1}
    }

    local StartIndex = 1
    for Index, Unit in ipairs(Units) do
        if Unit.Name == MaxUnit then
            StartIndex = Index
            break
        end
    end

    local ResultParts = {}
    for Index = StartIndex, #Units do
        local Unit = Units[Index]
        if Time >= Unit.Seconds then
            local Count = math.floor(Time / Unit.Seconds)
            Time -= Count * Unit.Seconds
            table.insert(ResultParts, Count .. " " .. Unit.Name)
        end
    end

    return table.concat(ResultParts, " ")
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

-- Converts a time value in the given Unit (e.g., "Months") to years.
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
function Utils.GetAttributes(Instance: Instance): Table
    return Instance:GetAttributes()
end

-- Returns a table of all readable value properties of Instance (only properties readable by Basic, user-script security are included).
function Utils.GetProperties(Instance: Instance): Table
    local Properties = {}

    local Success, PropertyList = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, Instance.ClassName, {
        Security = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
    })
    
    if not Success then
        return Properties
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
function Utils.SetAttributes(Instance: Instance, Attributes: Table)
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
    local Success, PropertyList = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, Source.ClassName, {
        Security = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
    })
    if not Success then
        return
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
function Utils.AttributeDiff(Instance: Instance, Comparison: Instance | Table): Table
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
function Utils.PropertyDiff(InputtedInstance: Instance, Comparison: Instance | Table?): Table
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
    local Success, PropertyList = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, Instance.ClassName, {
        Security = SecurityCapabilities.new(Enum.SecurityCapability.Basic)
    })
    if not Success then
        return false
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
    for _, Value in ipairs({...}) do
        if Value ~= nil then
            return Value
        end
    end
    return nil
end

-- Returns Value if it isn't nil, otherwise returns DefaultValue.
function Utils.Default(Value: any, DefaultValue: any): any
    return Value ~= nil and Value or DefaultValue
end

-- Returns Value if it isn't nil, otherwise returns the first non-nil value from Fallbacks.
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

-- Returns the opposite of the given boolean.
function Utils.Toggle(Value: boolean): boolean
    return not Value
end

--[[ Task/Threading/Delay Utilities
    -- Task utility functions are useful for working with tasks, threads, and delays in Roblox. Here are some common functions:
    -- Utils.Debounce: Returns a function that will only execute after a certain amount of time has passed since the last call.
    -- Utils.Backoff: Returns a function that will execute after a certain amount of time has passed since the last call, with an increasing delay each time.
]]

-- Returns a function that only calls Function if at least Delay seconds have passed since the last call.
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

-- Returns an object with a BackoffFunction that calls Function once per delay cycle, and a live CallCount of calls made.
-- If Delay is a function, it is called with the arguments to get the delay; if it is a number, the delay is Delay * InitialDelay (InitialDelay defaults to 1).
-- With CallLimit, the function stops after that many calls.
function Utils.Backoff(Function: (...any) -> (), Delay: ((...any) -> number) | number, CallLimit: number?, InitialDelay: number?): {BackoffFunction: (...any) -> (), CallCount: number}
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

return Utils