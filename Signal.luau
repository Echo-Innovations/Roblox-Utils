--// Signal
--[[
	An optimized port of stravant's thread-reusing signal by mobogreat.

	All listeners in this module run on a single recycled coroutine thread,
	so a listener may yield (e.g. task.wait()) without blocking the caller
	or paying a per-fire thread creation cost.
--]]

export type SignalConnection = SignalConnectionData & {
	Disconnect: (self: SignalConnection) -> (),
}

export type Signal = SignalData & {
	Connect: (self: Signal, Listener: (...any) -> ()) -> SignalConnection,
	Fire: (self: Signal, ...any) -> (),
	Wait: (self: Signal) -> (...any),
	GetListenerCount: (self: Signal) -> number,
}

export type SignalConnectionData = {
	Listener: (...any) -> (),
	Signal: SignalData,
	Next: SignalConnectionData?,
	IsConnected: boolean,
}

export type SignalData = {
	Id: number,
	Head: SignalConnectionData?,
	ListenerCount: number,
}

export type SignalClassType = {
	__index: SignalClassType,
	New: () -> Signal,
	Connect: (self: SignalData, Listener: (...any) -> ()) -> SignalConnection,
	Disconnect: (self: SignalConnectionData) -> (),
	DisconnectAll: () -> (),
	Fire: (self: SignalData, ...any) -> (),
	Wait: (self: SignalData) -> (...any),
	GetListenerCount: (self: SignalData) -> number,
	Signals: {SignalData},
}

local SignalClass: SignalClassType = {} :: SignalClassType
SignalClass.__index = SignalClass

-- The single recycled runner thread shared by every signal in this module:
local FreeRunnerThread: thread? = nil

-- Every signal created through this module, so they can be inspected or bulk-disconnected:
SignalClass.Signals = {} :: {SignalData}
local NextSignalId = 0

local function RunHandlerInFreeThread(Listener: (...any) -> (), ...: any)
	-- Claim the runner thread for the duration of this listener:
	local AcquiredRunnerThread = FreeRunnerThread
	FreeRunnerThread = nil
	Listener(...)
	FreeRunnerThread = AcquiredRunnerThread

	-- Suspend until resumed with the next listener:
	while true do
		RunHandlerInFreeThread(coroutine.yield())
	end
end

-- Creates a new event
function SignalClass.New(): Signal
	local NewSignal = setmetatable({
		Id = NextSignalId,
		Head = nil,
		ListenerCount = 0,
	} :: SignalData, SignalClass) :: any

	NextSignalId += 1
	table.insert(SignalClass.Signals, NewSignal)

	return NewSignal
end

-- Connects a listener; returns a connection object that can disconnect it
function SignalClass.Connect(self: SignalData, Listener: (...any) -> ()): SignalConnection
	if type(Listener) ~= "function" then
		error(`[Utils - Signal]: "listener" must be a function; Received {typeof(Listener)}`)
	end

	local Connection: SignalConnectionData = {
		Listener = Listener,
		Signal = self,
		Next = self.Head,
		IsConnected = true,
	}

	self.Head = Connection
	self.ListenerCount += 1

	return setmetatable(Connection, SignalClass) :: any
end

-- Disconnects a listener connection
function SignalClass.Disconnect(self: SignalConnectionData)
	if self.IsConnected == false then
		return
	end

	local signal = self.Signal
	self.IsConnected = false
	signal.ListenerCount -= 1

	if signal.Head == self then
		signal.Head = self.Next
	else
		local Previous = signal.Head
		while Previous ~= nil and Previous.Next ~= self do
			Previous = Previous.Next
		end
		if Previous ~= nil then
			Previous.Next = self.Next
		end
	end
end

-- Disconnects every connection of every signal created through this module.
function SignalClass.DisconnectAll()
	for _, Signal in ipairs(SignalClass.Signals) do
		local Item = Signal.Head
		while Item ~= nil do
			local NextItem = Item.Next
			SignalClass.Disconnect(Item)
			Item = NextItem
		end
	end
end

-- Fires the event; every connected listener runs on the recycled runner thread
function SignalClass.Fire(self: SignalData, ...: any)
	local Item = self.Head

	while Item ~= nil do
		if Item.IsConnected == true then
			if FreeRunnerThread == nil then
				FreeRunnerThread = coroutine.create(RunHandlerInFreeThread)
			end
			task.spawn(FreeRunnerThread :: thread, Item.Listener, ...)
		end

		Item = Item.Next
	end
end

-- Yields until the next fire, then returns its arguments.
-- The listener resumes the caller thread instead of the caller waiting in a busy loop.
function SignalClass.Wait(self: SignalData): (...any)
	local CallerThread = coroutine.running()
	local Connection: SignalConnection

	Connection = SignalClass.Connect(self, function(...: any)
		Connection:Disconnect() -- One-shot: the first fire releases the wait
		task.spawn(CallerThread, ...)
	end)

	return coroutine.yield()
end

-- Returns the number of connected listeners
function SignalClass.GetListenerCount(self: SignalData): number
	return self.ListenerCount
end

return SignalClass :: SignalClassType