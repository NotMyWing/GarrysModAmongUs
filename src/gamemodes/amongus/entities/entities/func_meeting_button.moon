AddCSLuaFile!

if CLIENT
	surface.CreateFont "NMW AU Meeting Button", {
		font: "Roboto"
		size: ScrH! * 0.125
		weight: 550
		outline: false
		antialias: true
	}

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

if SERVER
	ENT.KeyValue = (key, value) =>
		if key == "model"
			@Model = value

	ENT.Use = (ply) =>
		if SERVER
			return if ply\GetNWInt("NMW AU Meetings") <= 0

			time = GetGlobalFloat("NMW AU NextMeeting") - CurTime!

			return if time > 0

			if GAMEMODE\Meeting_Start ply
				@EmitSound "au/panel_emergencybutton.ogg", 60
				ply\SetNWInt "NMW AU Meetings", ply\GetNWInt("NMW AU Meetings") - 1


if CLIENT
	TRANSLATE = GAMEMODE.Lang.GetEntry

	ENT.Think = =>
		return unless GAMEMODE\IsGameInProgress!

		-- Translate the button text.
		-- This has been moved to @Think because of the table churn.
		-- We don't want to create multiple throwaway tables 60+ times per second.
		-- Do we?
		if not @__nextLineUpdate or CurTime! > @__nextLineUpdate
			@__nextLineUpdate = CurTime! + 0.5
			time = GetGlobalFloat("NMW AU NextMeeting") - CurTime!

			@__textLines = if GAMEMODE\IsMeetingDisabled!
				TRANSLATE("meetingButton.crisis")!
			elseif time > 0
				TRANSLATE("meetingButton.cooldown") math.floor time
			else
				TRANSLATE("meetingButton.default") LocalPlayer!\Nick!, LocalPlayer!\GetNWInt "NMW AU Meetings"

		if @__nextGarrysModIsDumbCheck and CurTime! > @__nextGarrysModIsDumbCheck
			@__nextGarrysModIsDumbCheck = @__nextGarrysModIsDumbCheck + 10

			@SetRenderBounds @OBBMins!, @OBBMaxs!

	COLOR_BLACK = Color 0, 0, 0, 128
	ENT.DrawTranslucent = =>
		@DrawModel!

		return unless GAMEMODE\IsGameInProgress!
		return unless @__textLines

		-- Position the text above the highest point of the meeting button.
		-- This might cause issues if the button doesn't have a collision model.
		pos = @OBBMaxs!
		pos += @GetPos! + Vector -pos.x, -pos.y, math.cos(CurTime! / 2) + 30

		-- Make the text face the player.
		-- Additionaly, make it wiggle a little. Just for fun.
		angle = (pos - LocalPlayer!\EyePos!)\Angle!
		with angle
			.p = 0
			.y = angle.y + math.sin(CurTime!) * 10
			.r = 0

			\RotateAroundAxis \Up!, -90
			\RotateAroundAxis \Forward!, 90

		-- Fetch the line height.
		-- Determine the total text height.
		surface.SetFont "NMW AU Meeting Button"
		_, lineHeight = surface.GetTextSize "A"
		totalHeight = #@__textLines * lineHeight + #@__textLines - 1

		-- Setup the 3D2D context.
		cam.Start3D2D pos, angle, 0.075
		do
			for i, line in ipairs @__textLines
				posX = 0
				posY = -totalHeight/2 + (i - 1) * lineHeight + math.max 0, i - 2

				-- Draw a "better" outline.
				passes = 6
				for i = -passes/2, passes/2
					for j = -passes/2, passes/2
						continue if i == 0 or j == 0

						offsetX = 2 * i
						offsetY = 2 * j
						draw.SimpleText line.text, "NMW AU Meeting Button",
							posX + offsetX, posY + offsetY, COLOR_BLACK, TEXT_ALIGN_CENTER

				-- Draw the actual text.
				draw.SimpleText line.text, "NMW AU Meeting Button",
					posX, posY,
					line.color or Color(255, 255, 255),
					TEXT_ALIGN_CENTER

		cam.End3D2D!
