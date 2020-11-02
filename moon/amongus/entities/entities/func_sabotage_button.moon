AddCSLuaFile!

ENT.Base  = "base_anim"
ENT.Type  = "anim"

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Initialize = =>
	if SERVER
		@SetMoveType MOVETYPE_VPHYSICS
		@SetSolid SOLID_VPHYSICS
		@SetModel self.Model
		@SetUseType SIMPLE_USE

	else
		@SetRenderBounds @OBBMins!, @OBBMaxs!

	@AddEFlags EFL_FORCE_CHECK_TRANSMIT

ENT.Draw = =>
	@DrawModel!

ENT.Use = (ply) =>
	if GAMEMODE.GameData and GAMEMODE.GameData.SabotageButtons
		sabotageId = GAMEMODE.GameData.SabotageButtons[@]
		playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

		if sabotageId and playerTable and GAMEMODE.GameData.Sabotages[sabotageId]
			GAMEMODE.GameData.Sabotages[sabotageId]\ButtonUse playerTable, @

ENT.KeyValue = (key, value) =>
	if key == "model"
		self.Model = value
	if key == "areaname"
		@SetArea value
	if key == "customdata"
		@SetCustomData value
	if key == "sabotagename"
		@SetSabotageName value
	if "On" == string.sub key, 1, 2
		@StoreOutput key, value

ENT.Draw = =>
	@DrawModel!

ENT.SetupDataTables = =>
	@NetworkVar "String", 0, "Area"
	@NetworkVar "String", 1, "SabotageName"
	@NetworkVar "String", 2, "CustomData"

ENT.UpdateTransmitState = -> TRANSMIT_ALWAYS
