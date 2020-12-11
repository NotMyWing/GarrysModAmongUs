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

if SERVER
	ENT.KeyValue = (key, value) =>
		if key == "model"
			@Model = value

	ENT.Use = (ply) =>
		GAMEMODE\Player_OpenVGUI ply, "meetingButton"

if CLIENT
	TRANSLATE = GAMEMODE.Lang.GetEntry

	COLOR_BLACK = Color 0, 0, 0

	ASSETS = {asset, Material("au/gui/meeting/button/#{asset}.png", "smooth") for asset in *{
		"background"
		"bubble"
		"button"
		"button_clip"
		"lid_closed"
		"lid_open"
	}}

	ENT.Think = =>
		if @__nextGarrysModIsDumbCheck and CurTime! > @__nextGarrysModIsDumbCheck
			@__nextGarrysModIsDumbCheck = @__nextGarrysModIsDumbCheck + 10

			@SetRenderBounds @OBBMins!, @OBBMaxs!

	hook.Add "GMAU OpenVGUI", "NMW AU Meeting Button", (payload, identifier) ->
		return unless identifier == "meetingButton"

		with base = vgui.Create "AmongUsVGUIBase"
			\Setup with panel = vgui.Create "DImage"
				local lidOpen, bubbleText
				textLines = {}

				size = math.min ScrH!, ScrW!

				\SetSize size, size

				\SetMaterial (GAMEMODE.MapManifest and
					GAMEMODE.MapManifest.MeetingButtonBackground
				) or ASSETS.background

				lidClosedPosX  = (142 / 505) * size
				lidClosedPosY  = (127 / 505) * size
				lidClosedSizeX = (224 / 505) * size
				lidClosedSizeY = (173 / 505) * size

				lidOpenedPosX  = (324 / 505) * size
				lidOpenedPosY  = (30  / 505) * size
				lidOpenedSizeX = (148 / 505) * size
				lidOpenedSizeY = (284 / 505) * size

				bubbleSizeX = (406 / 505) * size
				bubbleSizeY = (204 / 505) * size
				bubblePaddingSide  = (8  / 505) * size
				bubblePaddingTop   = (96 / 505) * size
				bubbleMarginBottom = (32 / 505) * size

				buttonPosX  = (166 / 505) * size
				buttonPosY  = (141 / 505) * size
				buttonSizeX = (172 / 505) * size
				buttonSizeY = (181 / 505) * size
				buttonHitBoxSizeY = (138 / 505) * size
				buttonClip = (35 / 505) * size

				buttonJump = (16 / 505) * size

				button_clip = with \Add "Panel"
					\SetSize buttonSizeX, buttonSizeY
					\SetPos  buttonPosX , buttonPosY - buttonClip

					button = with \Add "DImage"
						\SetSize buttonSizeX, buttonSizeY
						\SetPos  0 , buttonClip

						\SetMaterial ASSETS.button

						base.OnOpen = ->
							return unless lidOpen\IsVisible!
							\MoveTo 0, buttonClip - buttonJump, 0.1, nil, nil, ->
								\MoveTo 0, buttonClip, 0.1

				frontOverlay = with \Add "DImage"
					\SetSize buttonSizeX, buttonSizeY
					\SetPos  buttonPosX , buttonPosY

					\SetMaterial ASSETS.button_clip

				buttonHitBox = with \Add "DButton"
					\SetSize buttonSizeX, buttonHitBoxSizeY
					\SetPos buttonPosX , buttonPosY
					\SetZPos 1

					\SetText ""
					.Paint = ->
					.DoClick = -> GAMEMODE\Net_MeetingRequest! if lidOpen\IsVisible!

				lidOpen = with \Add "DImage"
					\SetSize lidOpenedSizeX, lidOpenedSizeY
					\SetPos  lidOpenedPosX , lidOpenedPosY

					\SetMaterial ASSETS.lid_open
					\Hide!

				lidClosed = with \Add "DImage"
					\SetSize lidClosedSizeX, lidClosedSizeY
					\SetPos  lidClosedPosX , lidClosedPosY

					\SetMaterial ASSETS.lid_closed
					\Hide!

				bubble = with \Add "DImage"
					\SetSize bubbleSizeX, bubbleSizeY
					\CenterHorizontal!
					\AlignBottom bubbleMarginBottom

					\DockPadding bubblePaddingSide, bubblePaddingTop,
						bubblePaddingSide, bubblePaddingSide

					\SetMaterial ASSETS.bubble

					surface.CreateFont "NMW AU Meeting Button Text", {
						font: "Roboto"
						size: bubbleSizeY / 8
						weight: 550
					}

					bubbleText = with \Add "Panel"
						\Dock FILL
						.Paint = (_, w, h) ->
							-- Fetch the line height.
							-- Determine the total text height.
							surface.SetFont "NMW AU Meeting Button Text"
							_, lineHeight = surface.GetTextSize "A"
							totalHeight = #textLines * lineHeight + #textLines - 1

							for i, line in ipairs textLines
								posX = w / 2
								posY = h / 2 - totalHeight/2 + (i - 1) * lineHeight + math.max 0, i - 2

								-- Draw the text.
								draw.SimpleText line.text, "NMW AU Meeting Button Text",
									posX, posY,
									line.color or COLOR_BLACK,
									TEXT_ALIGN_CENTER

				.Think = =>
					return unless GAMEMODE\IsGameInProgress!

					-- Translate the button text.
					-- This has been moved to @Think because of the table churn.
					-- We don't want to create multiple throwaway tables 60+ times per second.
					-- Do we?
					if not @__nextLineUpdate or CurTime! > @__nextLineUpdate
						@__nextLineUpdate = CurTime! + 0.5
						time = GetGlobalFloat("NMW AU NextMeeting") - CurTime!

						textLines = if GAMEMODE\IsMeetingDisabled!
							lidClosed\Show!
							lidOpen\Hide!
							TRANSLATE("meetingButton.crisis")!

						elseif time > 0
							lidClosed\Show!
							lidOpen\Hide!
							TRANSLATE("meetingButton.cooldown") math.floor time

						else
							lidClosed\Hide!
							lidOpen\Show!
							TRANSLATE("meetingButton.default") LocalPlayer!\Nick!, LocalPlayer!\GetNWInt "NMW AU Meetings"

			\Popup!

			GAMEMODE\HUD_OpenVGUI base

		return true
