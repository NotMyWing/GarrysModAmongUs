AddCSLuaFile!

ENT.Base  = "base_anim"
ENT.Type  = "anim"

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Initialize = =>
	if SERVER
		@SetMoveType MOVETYPE_VPHYSICS
		@SetSolid SOLID_VPHYSICS
		@SetUseType SIMPLE_USE
		if @Model
			@SetModel @Model

		if @Links
			newLinks = {}

			for _, ent in ipairs ents.GetAll!
				if @Links[ent\GetName!]
					table.insert newLinks, ent

			@Links = newLinks
	else
		@SetRenderBounds @OBBMins!, @OBBMaxs!

if SERVER
	ENT.Use = (ply) =>
		if SERVER
			if playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]
				GAMEMODE\Player_Vent playerTable, @

	ENT.KeyValue = (key, value) =>
		if key == "model"
			@Model = value

		if key == "Link"
			@Links or= {}
			if name = string.match(value, "([^,]+),")
				@Links[name] = true

		if key == "viewangle"
			@ViewAngle = Angle value
