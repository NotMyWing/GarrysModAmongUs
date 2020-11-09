TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Countdown", {
	font: "Arial"
	size: ScreenScale 20
	weight: 500
	outline: true
}

surface.CreateFont "NMW AU Cooldown", {
	font: "Arial"
	size: ScrH! * 0.125
	weight: 500
	outline: true
}

surface.CreateFont "NMW AU Taskbar", {
	font: "Roboto"
	size: ScrH! * 0.025
	weight: 600
	outline: true
}

surface.CreateFont "NMW AU Start Subtext", {
	font: "Arial"
	size: ScreenScale 10
	weight: 500
	outline: true
}

hud = {}

MAT_BUTTONS = {
	kill: Material "au/gui/hudbuttons/kill.png"
	use: Material "au/gui/hudbuttons/use.png"
	report: Material "au/gui/hudbuttons/report.png"
	vent: Material "au/gui/hudbuttons/vent.png"
}

COLOR_BTN = Color 255, 255, 255

hud.Init = =>
	@__oldCommsSabotaged = false

	@SetSize ScrW!, ScrH!

	hook.Add "OnScreenSizeChanged", "NMW AU Hud Size", ->
		@SetSize ScrW!, ScrH!

	with @buttons = @Add "DPanel"
		\SetTall ScrH! * 0.20

		margin = ScreenScale 5
		\DockMargin margin, margin, margin, margin
		\Dock BOTTOM
		\SetZPos -1

		.Paint = ->

hud.SetTaskbarValue = (value) =>
	if IsValid @taskbar
		refW, refH = @taskbar\GetParent!\GetSize!

		@taskbar\SizeTo refW * value, refH, 2, 0.1

CREW_LAYERS = {
	Material "au/gui/crewmateicon/crewmate1.png", "smooth"
	Material "au/gui/crewmateicon/crewmate2.png", "smooth"
}

hud.SetupButtons = (state, impostor) =>
	localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]

	for _, v in ipairs @buttons\GetChildren!
		v\Remove!

	@buttons\SetAlpha 0
	@buttons\AlphaTo 255, 2

	if state == GAMEMODE.GameState.Preparing
		-- The convar list.
		with @Add "DPanel"
			m = ScrW! * 0.01
			\DockMargin m, m, m, m
			\SetWide ScrW! * 0.35
			\Dock LEFT

			white = Color 255, 255, 255
			green = Color 32, 255, 32
			.Paint = ->
				surface.SetFont "NMW AU Taskbar"
				_, tH = surface.GetTextSize "A"

				conVars = GAMEMODE\IsGameCommencing! and GAMEMODE.ConVarSnapshots or GAMEMODE.ConVars
				i = 0
				for categoryId, category in ipairs GAMEMODE.ConVarsDisplay
					for _, conVarTable in ipairs category.ConVars
						type   = conVarTable[1]
						conVar = conVars[conVarTable[2]]
						conVarName = conVar\GetName!

						value = switch type
							when "Int"
								conVar\GetInt!
							when "Time"
								TRANSLATE("hud.cvar.time") conVar\GetInt!
							when "String"
								conVar\GetString!
							when "Bool"
								conVar\GetBool! and TRANSLATE("hud.cvar.enabled") or TRANSLATE("hud.cvar.disabled")
							when "Mod"
								"#{conVar\GetFloat!}x"

						if value
							i += 1

							draw.SimpleText "#{TRANSLATE("cvar." .. conVarName)}: #{value}", "NMW AU Taskbar",
								0, (i - 1) * tH * 1.05 + (categoryId - 1) * tH * 1.05, GAMEMODE\IsGameCommencing! and green or white

		-- Round overlay.
		@roundOverlay = with @Add "DPanel"
			nextCheck = 0
			local initializedPlayers

			\SetZPos 30001
			\SetSize ScrW!, ScrH! * 0.125
			\SetPos 0, ScrH! * 0.75
			.Paint = ->
			.Think = ->
				if GAMEMODE.ConVarSnapshots and SysTime! > nextCheck
					nextCheck = SysTime! + 0.5
					initializedPlayers = GAMEMODE\GetFullyInitializedPlayers!

			with \Add "DPanel"
				margin = ScrW! * 0.25
				\DockMargin margin, 0, margin, 0
				\Dock FILL
				.Paint = ->

				-- Right
				with \Add "DPanel"
					\SetWide 0.5 * ScrW! * 0.25
					\Dock RIGHT
					.Paint = ->

					if GAMEMODE.MapManifest
						crewSize = 0.25 * \GetWide!

						-- Imposter Count Container
						with \Add "DLabel"
							\Dock BOTTOM
							\SetTall 0.5 * ScrH! * 0.125
							\SetColor Color 255, 255, 255
							\SetContentAlignment 8
							\SetText ""
							\SetFont "NMW AU Start Subtext"
							.Think = ->
								if initializedPlayers
									imposterCount = math.min GAMEMODE.ConVars.ImposterCount\GetInt!, GAMEMODE\GetImposterCount #initializedPlayers

									\SetText tostring TRANSLATE("prepare.imposterCount") imposterCount

						-- Count container.
						with \Add "DPanel"
							\DockPadding 0, 0, crewSize * 0.5, 0
							\Dock TOP
							\SetTall 0.5 * ScrH! * 0.125
							.Paint = ->

							-- Crewmate
							with \Add "DPanel"
								\SetSize crewSize, crewSize
								\DockMargin crewSize * 0.25, 0, 0, 0
								\Dock RIGHT
								.Paint = ->

								-- A slightly unreadable chunk of garbage code
								-- responsible for layering the crewmate sprite.
								layers = {}
								for i = 1, 2
									with layers[i] = \Add "DPanel"
										\Dock FILL
										.Image = CREW_LAYERS[i]
										.Paint = GAMEMODE.Render.DermaFitImage
								layers[1].Color = Color 255, 0, 0

							-- Label
							with \Add "DLabel"
								\SetFont "NMW AU Countdown"
								\SetText "..."
								\SetContentAlignment 6
								\Dock FILL

								red    = Color 220, 32, 32
								yellow = Color 255, 255, 30
								white  = Color 255, 255, 255

								.Think = ->
									if initializedPlayers
										playerCount = #player.GetAll!
										needed = GAMEMODE.ConVars.MinPlayers\GetInt!

										\SetText "#{playerCount}/#{needed}"

										\SetColor if playerCount > needed
											white
										elseif playerCount == needed
											yellow
										else
											red

				-- Middle
				with \Add "DPanel"
					\SetWide ScrW! * 0.25
					\Dock RIGHT
					.Paint = ->

					with \Add "DLabel"
						\SetTall 0.5 * ScrH! * 0.125
						\Dock TOP
						\SetText ""
						\SetContentAlignment 5
						\SetFont "NMW AU Countdown"
						\SetColor Color 255, 255, 255
						.Think = ->
							\SetText tostring if not GAMEMODE.MapManifest
								TRANSLATE "prepare.invalidMap"
							elseif not GAMEMODE.ConVars.ForceAutoWarmup\GetBool! and LocalPlayer!\IsAdmin!
								TRANSLATE "prepare.admin"
							else
								TRANSLATE "prepare.warmup"

					with \Add "DLabel"
						\SetTall 0.5 * ScrH! * 0.125
						\Dock BOTTOM
						\SetText ""
						\SetContentAlignment 5
						\SetFont "NMW AU Start Subtext"
						\SetColor Color 255, 255, 255

						.Think = ->
							if initializedPlayers
								playerCount = #initializedPlayers
								needed = GAMEMODE.ConVars.MinPlayers\GetInt!

								\SetText tostring if not GAMEMODE.MapManifest
									TRANSLATE "prepare.invalidMap.subText"
								elseif playerCount < needed
									TRANSLATE "prepare.waitingForPlayers"
								elseif not GAMEMODE.ConVars.ForceAutoWarmup\GetBool! and LocalPlayer!\IsAdmin!
									TRANSLATE("prepare.pressToStart") string.upper input.LookupBinding("jump") or "???"
								else
									if not (GAMEMODE.ConVars.ForceAutoWarmup\GetBool! or GAMEMODE\IsOnAutoPilot!)
										TRANSLATE "prepare.waitingForAdmin"
									else
										time = math.max 0, GetGlobalFloat("NMW AU AutoPilotTimer") - CurTime!
										if time > 0
											TRANSLATE("prepare.commencing") time
										else
											""

		return

	-- The task bar. A clustertruck of panels.
	with @Add "DPanel"
		\SetTall ScrH! * 0.09
		\Dock TOP
		pad = ScrH! * 0.015
		\DockPadding pad, pad, pad, pad
		.Paint = ->

		with \Add "DPanel"
			\SetWide ScrW! * 0.35
			\Dock LEFT

			pad = ScrH! * 0.003
			\DockPadding pad, pad, pad, pad

			outerColor = Color 0, 0, 0
			.Paint = (_, w, h) ->
				draw.RoundedBox 6, 0, 0, w, h, outerColor

			with \Add "DPanel"
				\Dock FILL

				pad = ScrH! * 0.008
				\DockPadding pad, pad, pad, pad

				innerColor = Color 170, 188, 188
				taskBarOuterColor = Color 51, 51, 51

				pad = ScrH! * 0.005
				.Paint = (_, w, h) ->
					draw.RoundedBox 4, 0, 0, w, h, innerColor

					draw.RoundedBox 4, pad, pad, w - pad*2, h - pad*2, taskBarOuterColor

				with \Add "DPanel"
					\Dock FILL
					.Paint = ->

					@taskBarLabel = with \Add "DLabel"
						\SetColor Color 255, 255, 255
						\SetZPos 1
						\SetFont "NMW AU Taskbar"
						\SetText "  " .. TRANSLATE "tasks.totalCompleted"

						-- If there's a time limit, dock the timer to the right side.
						if GAMEMODE\GetTimeLimit! > 0
							with \Add "DLabel"
								\SetWide ScrW! * 0.08
								\Dock RIGHT
								\SetText "..."
								\SetContentAlignment 6
								\SetFont "NMW AU Taskbar"
								\SetColor Color 255, 255, 255

								red = false
								.Think = ->
									time = GAMEMODE\GetTimeLimit!
									if time <= 60 and not red
										red = true
										\SetColor Color 255, 0, 0

									\SetText string.FormattedTime(time, "%02i:%02i") .. "  "

					with @taskbar = \Add "DPanel"
						taskBarInnerColor = Color 68, 216, 68

						.Paint = (_, w, h) ->
							surface.SetDrawColor taskBarInnerColor
							surface.DrawRect 0, 0, w, h

						\NewAnimation 0, 0, 0, ->
							refW, refH = @taskbar\GetParent!\GetSize!
							@taskbar\SetSize 0, refH

							@taskBarLabel\SetSize refW, refH

	if localPlayerTable
		-- The task list.
		@taskBoxContainer = with @Add "DPanel"
			margin = ScrH! * 0.015
			\DockMargin margin, 0, 0, 0
			\SetWide ScrW! * 0.35
			\Dock LEFT
			.Paint = ->

			with \Add "DPanel"
				\SetTall ScrH! * 0.05
				margin = ScrH! * 0.0075
				\Dock TOP

				key = string.upper input.LookupBinding("gmod_undo") or "?"
				text = "(#{key}) " .. tostring TRANSLATE if impostor
					"hud.fakeTasks"
				else
					"hud.tasks"

				text = "  #{text}  "

				.Paint = (_, w, h) ->
					surface.SetFont "NMW AU Taskbar"
					tW = surface.GetTextSize text

					surface.SetDrawColor 255, 255, 255, 16
					surface.DrawRect 0, 0, tW, h

					draw.SimpleTextOutlined text, "NMW AU Taskbar",
						0, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 64)

			@tasks = {}
			@taskBox = with \Add "DPanel"
				\Dock FILL
				.Paint = ->

		-- Use/report button. Content-aware.
		with @use = @buttons\Add "DPanel"
			\SetWide @buttons\GetTall!
			\DockMargin 0, 0, ScreenScale(5), 0
			\Dock RIGHT

			.Think = =>
				if IsValid GAMEMODE.UseHighlight
					\SetAlpha 255
				else
					\SetAlpha 32

			.Paint = (_, w, h) ->
				ent = GAMEMODE.UseHighlight
				mat = @UseButtonOverride or if IsValid ent
					if 0 ~= ent\GetNW2Int "NMW AU PlayerID"
						MAT_BUTTONS.report
					elseif ent\GetClass! == "prop_vent" or ent\GetClass! == "func_vent"
						MAT_BUTTONS.vent

				if not mat
					mat = MAT_BUTTONS.use

				-- Like, jesus christ man.
				surface.SetDrawColor COLOR_BTN
				surface.SetMaterial mat

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!

		-- Kill button for imposerts. Content-aware.
		if impostor
			with @kill = @buttons\Add "DPanel"
				\SetWide @buttons\GetTall!
				\DockMargin 0, 0, ScreenScale(5), 0
				\Dock RIGHT

				.Paint = (_, w, h) ->
					-- Honestly I wish I had a wrapper for this kind of monstrosities.
					surface.SetMaterial MAT_BUTTONS.kill

					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC

					alpha = if GAMEMODE.GameData.KillCooldown >= CurTime!
						32
					elseif IsValid(GAMEMODE.KillHighlight) and not GAMEMODE.GameData.Imposters[GAMEMODE.KillHighlight]
						255
					else
						32

					surface.SetDrawColor COLOR_BTN.r, COLOR_BTN.g, COLOR_BTN.b, alpha
					surface.DrawTexturedRect 0, 0, w, h

					render.PopFilterMag!
					render.PopFilterMin!

					if GAMEMODE.GameData.KillCooldownOverride or (GAMEMODE.GameData.KillCooldown and GAMEMODE.GameData.KillCooldown >= CurTime!)
						time = if GAMEMODE.GameData.KillCooldownOverride
							GAMEMODE.GameData.KillCooldownOverride
						else
							math.max(0, GAMEMODE.GameData.KillCooldown - CurTime!)

						if time > 0
							draw.DrawText string.format("%d", math.ceil time),
								"NMW AU Cooldown", w * 0.5, h * 0.15, Color(255,255,255,255), TEXT_ALIGN_CENTER

		-- The player icon!
		with @playerIcon = @buttons\Add "DPanel"
			\SetWide @buttons\GetTall!
			\Dock LEFT

			size = \GetWide!
			circle = GAMEMODE.Render.CreateCircle size/2, size/2, size/2, 90

			.Paint = ->
				surface.SetAlphaMultiplier 0.8
				surface.SetDrawColor localPlayerTable.color
				draw.NoTexture!
				surface.DrawPoly circle
				surface.SetAlphaMultiplier 1

			with \Add "DModelPanel"
				\Dock FILL
				\SetModel LocalPlayer!\GetModel!
				\SetColor localPlayerTable.color
				\SetFOV 36
				\SetCamPos \GetCamPos! - Vector 0, 0, 18
				with \GetEntity!
					\SetAngles Angle 0, 45, 0
					\SetPos \GetPos! - Vector 0, 0, 4
				.LayoutEntity = ->

				textColor = if GAMEMODE.GameData.Imposters[localPlayerTable]
					Color 255, 32, 32
				else
					Color 255, 255, 255

				oldPaint = .Paint
				.Paint = (_, w, h) ->
					-- le old huge chunk of stencil code. shall we?
					with render
						.ClearStencil!

						.SetStencilEnable true
						.SetStencilTestMask 0xFF
						.SetStencilWriteMask 0xFF
						.SetStencilReferenceValue 0x01

						.SetStencilCompareFunction STENCIL_NEVER
						.SetStencilFailOperation STENCIL_REPLACE
						.SetStencilZFailOperation STENCIL_REPLACE

						surface.DrawPoly circle

						.SetStencilCompareFunction STENCIL_LESSEQUAL
						.SetStencilFailOperation STENCIL_KEEP
						.SetStencilZFailOperation STENCIL_KEEP

					\SetAlpha 255 * if GAMEMODE.GameData.DeadPlayers[localPlayerTable]
						0.35
					else
						1

					oldPaint _, w, h

					render.SetStencilEnable false

					surface.DisableClipping true
					draw.SimpleTextOutlined localPlayerTable.nickname or "", "NMW AU Taskbar",
						w/2, -size * 0.1, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color 0, 0, 0, 220
					surface.DisableClipping false

--- Displays a countdown.
-- @param time Target time.
hud.Countdown = (time) =>
	@countdownTime = time

	if IsValid @countdown
		@countdown\Remove!

	with @countdown = @Add "DPanel"
		\SetSize @GetWide!, @GetTall! * 0.1
		\SetPos 0, @GetTall! * 0.7

		color = Color 255, 255, 255
		.Paint = (_, w, h) ->
			draw.DrawText TRANSLATE("hud.countdown")(math.floor math.max 0, @countdownTime - CurTime!),
				"NMW AU Countdown",
				w * 0.5, h * 0.25, color, TEXT_ALIGN_CENTER

			if @countdownTime - CurTime! <= 0
				_\Remove!

hud.HideTaskList = (state) =>
	if IsValid @taskBoxContainer
		if state
			@taskBoxContainer\Hide!
		else
			@taskBoxContainer\Show!

hud.ToggleTaskList = =>
	if IsValid @taskBox
		if @taskBox\IsVisible!
			@taskBox\Hide!
		else
			@taskBox\Show!

hud.AddTaskEntry = =>
	return with @taskBox\Add "DPanel"
		\SetTall ScrH! * 0.04
		\Dock TOP

		color = Color 255, 255, 255
		.SetColor = (value) =>
			color = value

		blink = false
		colorBlink = Color 255, 64, 64
		.SetBlink = (value) =>
			blink = value

		text = ""
		.SetText = (value) =>
			text = value

		.Paint = (_, w, h) ->
			surface.SetDrawColor 255, 255, 255, 16
			surface.DrawRect 0, 0, w, h

			clr = if blink and math.floor((SysTime! * 4) % 2) == 0
				colorBlink
			else
				color

			if .OnBlink and clr ~= .__oldColor
				.__oldColor = clr
				\OnBlink!

			draw.SimpleTextOutlined text, "NMW AU Taskbar",
				ScrW! * 0.0075, h/2, clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 64)

hud.Think = =>
	if IsValid @roundOverlay
		with @roundOverlay
			shouldHide = IsValid(@countdown) or
				GAMEMODE\IsGameCommencing! or
				GAMEMODE\IsGameInProgress!

			if shouldHide and \IsVisible!
				\Hide!
			elseif not shouldHide and not \IsVisible!
				\Show!

	if @taskBarLabel
		commsSabotaged = GAMEMODE\GetCommunicationsDisabled!

		-- Repeatedly check if the communications have been sabotaged.
		-- A better way would be sending a net message, but for now it's like that.
		if @__oldCommsSabotaged ~= commsSabotaged
			with @taskBarLabel
				-- Comms have been sabotaged.
				-- Wipe the task list and add a blinker.
				-- Mess with the taskbar text.
				if commsSabotaged
					@__commsBlinker = with @AddTaskEntry!
						\SetColor Color 255, 230, 0
						\SetText TRANSLATE "tasks.commsSabotaged"
						\SetBlink true

					if not GAMEMODE.GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]]
						for task in *@tasks
							task\Hide!

					\SetText "  " .. TRANSLATE "tasks.totalCompleted.sabotaged"
					\SetColor Color 255, 64, 64

					@SetTaskbarValue 0

				-- Comms have been fixed.
				-- Restore the task list and remove the blinker.
				-- Fix the taskbar text.
				else
					if IsValid @__commsBlinker
						@__commsBlinker\Remove!

					if not GAMEMODE.GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]]
						for task in *@tasks
							task\Show!

					\SetText "  " .. TRANSLATE "tasks.totalCompleted"
					\SetColor Color 255, 255, 255

			@__oldCommsSabotaged = commsSabotaged

hud.Paint = ->

return vgui.RegisterTable hud, "DPanel"
