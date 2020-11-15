AddCSLuaFile!

ENT.Base  = "base_anim"
ENT.Type  = "anim"

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Initialize = =>
	if SERVER
		@SetMoveType MOVETYPE_VPHYSICS
		@SetSolid SOLID_VPHYSICS
		@SetUseType SIMPLE_USE
		if @Model
			@SetModel @Model
	else
		@SetRenderBounds @OBBMins!, @OBBMaxs!

	@AddEFlags EFL_FORCE_CHECK_TRANSMIT


ENT.SetupDataTables = =>
	@NetworkVar "String", 0, "Area"
	@NetworkVar "String", 1, "TaskName"
	@NetworkVar "String", 2, "CustomData"

if SERVER
	ENT.Use = (ply) =>
		if playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]
			GAMEMODE\Task_Start playerTable, @GetTaskName!

	ENT.KeyValue = (key, value) =>
		if key == "model"
			@Model = value
		if key == "areaname"
			@SetArea value
		if key == "customdata"
			@SetCustomData value
		if key == "taskname"
			@SetTaskName value
		if "On" == string.sub key, 1, 2
			@StoreOutput key, value

	ENT.UpdateTransmitState = -> TRANSMIT_ALWAYS
