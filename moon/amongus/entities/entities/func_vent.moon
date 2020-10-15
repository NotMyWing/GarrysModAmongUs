AddCSLuaFile!

if CLIENT
	surface.CreateFont "NMW AU Meeting Button", {
		font: "Arial"
		size: ScrH! * 0.125
		weight: 500
		outline: true
		antialias: true
	}

ENT.Base  = "base_anim"
ENT.Type  = "anim"

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Initialize = =>
	if SERVER
		@SetMoveType MOVETYPE_VPHYSICS
		@SetSolid SOLID_VPHYSICS
		@SetModel @Model
		@SetUseType SIMPLE_USE
		@SetAngles Angle 0, 0, 0

		if @Links
			newLinks = {}

			for _, ent in ipairs ents.GetAll!
				if @Links[ent\GetName!]
					table.insert newLinks, ent

			@Links = newLinks
	else
		@SetRenderBounds @OBBMins!, @OBBMaxs!

ENT.Draw = =>
	@DrawModel!

ENT.Use = (ply) =>
	if SERVER
		if playerTable = GAMEMODE.ActivePlayersMap[ply]
			GAMEMODE\Vent playerTable, @

ENT.KeyValue = (key, value) =>
	if key == "model"
		@Model = value

	if key == "Link"
		@Links or= {}
		if name = string.match(value, "([^,]+),")
			@Links[name] = true

	if key == "viewangle"
		@ViewAngle = Angle value

ENT.Draw = =>
	@DrawModel!