AddCSLuaFile!

ENT.Base  = "base_anim"
ENT.Type  = "anim"

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Initialize = =>
	if SERVER
		@SetMoveType MOVETYPE_VPHYSICS
		@SetSolid SOLID_VPHYSICS
		if self.Model
			@SetModel self.Model
		@SetUseType SIMPLE_USE

	else
		@SetRenderBounds @OBBMins!, @OBBMaxs!

	@AddEFlags EFL_FORCE_CHECK_TRANSMIT

ENT.Draw = =>
	@DrawModel!

ENT.Use = (ply) =>
	if playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]
		GAMEMODE\Task_Start playerTable, @GetTaskName!

ENT.KeyValue = (key, value) =>
	if key == "model"
		self.Model = value
	if key == "areaname"
		@SetArea value
	if key == "customdata"
		@SetCustomData value
	if key == "taskname"
		@SetTaskName value
	if "On" == string.sub key, 1, 2
		@StoreOutput key, value

ENT.Draw = =>
	@DrawModel!

ENT.SetupDataTables = =>
	@NetworkVar "String", 0, "Area"
	@NetworkVar "String", 1, "TaskName"
	@NetworkVar "String", 2, "CustomData"

ENT.UpdateTransmitState = -> TRANSMIT_ALWAYS 
