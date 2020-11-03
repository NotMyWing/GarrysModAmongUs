convarAccessors = {
	"Bool"
	"Default"
	"Float"
	"HelpText"
	"Int"
	"Max"
	"Min"
	"Name"
	"String"
}

class ConVarSnapshotWrapper
	new: (@__convar) =>
		for accessor in *convarAccessors
			@["Get#{accessor}"] = => @__snapshot[accessor]

	TakeSnapshot: => with @__convar
		@__snapshot = {}

		for accessor in *convarAccessors
			@__snapshot[accessor] = @__convar["Get#{accessor}"] @__convar

		return @

	ImportSnapshot: (value) => @__snapshot = table.Copy value
	ExportSnapshot: => table.Copy @__snapshot

GM.ConVarSnapshots = {name, ConVarSnapshotWrapper(cvar) for name, cvar in pairs GM.ConVars}

--- Takes snapshot of each registered game mode ConVar.
GM.ConVarSnapshot_Take = =>
	for name, wrp in pairs @ConVarSnapshots
		wrp\TakeSnapshot!

--- Exports snapshots of all ConVars.
-- @return ConVar snapshots.
GM.ConVarSnapshot_ExportAll = => with output = {}
	for name, wrp in pairs @ConVarSnapshots
		output[name] = wrp\ExportSnapshot!

--- Imports given snapshots.
-- @param input ConVar snapshots.
GM.ConVarSnapshot_ImportAll = (input) =>
	for name, snapshot in pairs input
		if @ConVarSnapshots[name]
			@ConVarSnapshots[name]\ImportSnapshot snapshot
