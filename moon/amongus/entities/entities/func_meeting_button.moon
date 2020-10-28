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
		@SetModel self.Model
		@SetUseType SIMPLE_USE
	else
		@SetRenderBounds @OBBMins!, @OBBMaxs!

ENT.Use = (ply) =>
	if SERVER
		if ply\GetNW2Int("NMW AU Meetings") <= 0
			return

		time = GetGlobalFloat("NMW AU NextMeeting") - CurTime!

		if time > 0
			return

		if GAMEMODE\Meeting_Start ply
			@EmitSound "au/panel_emergencybutton.wav", 60
			ply\SetNW2Int "NMW AU Meetings", ply\GetNW2Int("NMW AU Meetings") - 1

ENT.KeyValue = (key, value) =>
	if key == "model"
		self.Model = value

if CLIENT
	TRANSLATE = GAMEMODE.Lang.GetEntryFunc

	ENT.Draw = =>
		@DrawModel!

	ENT.DrawTranslucent = =>
		@DrawModel!

		if not GAMEMODE\IsGameInProgress!
			return

		pos = @GetPos!
		pos = pos + Vector( 0, 0, math.cos( CurTime() / 2 ) + 30 )

		angle = (pos - LocalPlayer!\EyePos!)\Angle!
		angle = Angle( 0, angle.y, 0 )
		angle.y = angle.y + math.sin( CurTime() ) * 10

		angle\RotateAroundAxis( angle\Up(), -90 )
		angle\RotateAroundAxis( angle\Forward(), 90 )

		time = GetGlobalFloat("NMW AU NextMeeting") - CurTime!
		lines = if time > 0
			TRANSLATE("meetingButton.cooldown") math.floor time
		else
			TRANSLATE("meetingButton.default") LocalPlayer!\Nick!, LocalPlayer!\GetNW2Int "NMW AU Meetings"

		surface.SetFont( "NMW AU Meeting Button" )
		_, tH = surface.GetTextSize "A"

		spacing = tH * 0
		totalH = #lines * tH + (#lines - 1) * spacing

		cam.Start3D2D( pos, angle, 0.075 )
		do
			for i, line in ipairs lines
				tW = surface.GetTextSize line.text

				draw.SimpleText line.text, "NMW AU Meeting Button", -tW / 2, -totalH/2 + ((i - 1) * tH) + math.max(0, (i - 2) * spacing), line.color or Color(255, 255, 255)
		cam.End3D2D()
