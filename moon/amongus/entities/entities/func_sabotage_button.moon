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
		if @GetBrushPlaneCount! > 0
			@__nextGarrysModIsDumbCheck = CurTime! + 5

	@AddEFlags EFL_FORCE_CHECK_TRANSMIT

ENT.SetupDataTables = =>
	@NetworkVar "String", 0, "Area"
	@NetworkVar "String", 1, "SabotageName"
	@NetworkVar "String", 2, "CustomData"

if CLIENT
	ENT.Draw = =>
		@DrawModel!

	ENT.Think = =>
		if @__nextGarrysModIsDumbCheck and CurTime! > @__nextGarrysModIsDumbCheck
			@__nextGarrysModIsDumbCheck = @__nextGarrysModIsDumbCheck + 10

			@SetRenderBounds @OBBMins!, @OBBMaxs!

else
	ENT.KeyValue = (key, value) =>
		if key == "model"
			@Model = value
		if key == "areaname"
			@SetArea value
		if key == "customdata"
			@SetCustomData value
		if key == "sabotagename"
			@SetSabotageName value
		if "On" == string.sub key, 1, 2
			@StoreOutput key, value

	ENT.Use = (ply) =>
		if GAMEMODE.GameData and GAMEMODE.GameData.SabotageButtons
			sabotageId = GAMEMODE.GameData.SabotageButtons[@]
			playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

			if sabotageId and playerTable and GAMEMODE.GameData.Sabotages[sabotageId]
				GAMEMODE.GameData.Sabotages[sabotageId]\ButtonUse playerTable, @

	ENT.UpdateTransmitState = -> TRANSMIT_ALWAYS
