TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Countdown", {
	font: "Roboto"
	size: ScreenScale 20
	weight: 550
}

surface.CreateFont "NMW AU Cooldown", {
	font: "Roboto"
	size: ScrH! * 0.125
	weight: 550
}

surface.CreateFont "NMW AU Taskbar", {
	font: "Roboto"
	size: ScrH! * 0.026
	weight: 550
}

surface.CreateFont "NMW AU Start Subtext", {
	font: "Roboto"
	size: ScreenScale 10
	weight: 500
}

surface.CreateFont "NMW AU ConVar List", {
	font: "Roboto"
	size: ScrH! * 0.023
	weight: 550
}

hud = {}

MAT_BUTTONS = {
	kill: Material "au/gui/hudbuttons/kill.png"
	use: Material "au/gui/hudbuttons/use.png"
	report: Material "au/gui/hudbuttons/report.png"
	vent: Material "au/gui/hudbuttons/vent.png"
}

COLOR_WHITE = Color 255, 255, 255
COLOR_BLACK = Color 0, 0, 0
COLOR_BLINK = Color 255, 64, 64

hud.Init = =>
	@__oldCommsSabotaged = false

	@SetSize ScrW!, ScrH!

	hook.Add "OnScreenSizeChanged", "NMW AU Hud Size", ->
		@SetSize ScrW!, ScrH!

	margin = ScreenScale 5

	with @buttons = @Add "Panel"
		\SetSize ScrW! - margin * 6, ScrH! * 0.19
		\AlignLeft margin * 3
		\AlignBottom margin
		\SetZPos -1

	with @buttonsTwo = @Add "Panel"
		\SetSize ScrW! - margin * 6, ScrH! * 0.19
		\AlignLeft margin * 3
		\AlignBottom margin * 2 + ScrH! * 0.19
		\SetZPos -1

hud.SetTaskbarValue = (value) =>
	if IsValid @taskbar
		refW, refH = @taskbar\GetParent!\GetSize!

		@taskbar\SizeTo refW * value, refH, 2, 0.1

COLOR_OUTLINE = Color 0, 0, 0, 160

hud.SetupButtons = (state, impostor) =>
	localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]

	for v in *@buttons\GetChildren!
		v\Remove!

	@buttons\SetAlpha 0
	@buttons\AlphaTo 255, 2

	if state == GAMEMODE.GameState.Preparing
		-- The convar list.
		with @Add "Panel"
			m = ScrW! * 0.01
			\DockMargin m, m, m, m
			\SetWide ScrW! * 0.35
			\Dock LEFT

			white = Color 255, 255, 255
			green = Color 32, 255, 32
			.Paint = ->
				surface.SetFont "NMW AU Taskbar"
				tW, tH = surface.GetTextSize "A"

				conVars = GAMEMODE\IsGameCommencing! and GAMEMODE.ConVarSnapshots or GAMEMODE.ConVars
				i = 0
				for categoryId, category in ipairs GAMEMODE.ConVarsDisplay
					for conVarTable in *category.ConVars
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
							when "Select"
								TRANSLATE("hud.cvar.#{conVarName}.#{conVar\GetInt!}")

						if value
							i += 1

							draw.SimpleTextOutlined "#{TRANSLATE("cvar." .. conVarName)}: #{value}", "NMW AU ConVar List",
								tW * 0.1, (i - 1) * tH * 1.05 + (categoryId - 1) * tH * 1.05, GAMEMODE\IsGameCommencing! and green or white,
								TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, COLOR_OUTLINE

		-- Round overlay.
		@roundOverlay = with @Add "Panel"

			\SetZPos 30001
			\SetSize ScrW!, ScrH! * 0.125
			\SetPos 0, ScrH! * 0.75

			with \Add "Panel"
				margin = ScrW! * 0.25
				\DockMargin margin, 0, margin, 0
				\Dock FILL

				-- Right
				with \Add "Panel"
					\SetWide 0.5 * ScrW! * 0.25
					\Dock RIGHT

					if GAMEMODE.MapManifest
						crewSize = 0.25 * \GetWide!

						-- Imposter Count Container
						with \Add "DOutlinedLabel"
							\Dock BOTTOM
							\SetTall 0.5 * ScrH! * 0.125
							\SetColor Color 255, 255, 255
							\SetContentAlignment 8
							\SetText ""
							\SetFont "NMW AU Start Subtext"
							.Think = ->
								imposterCount = math.min GAMEMODE.ConVars.ImposterCount\GetInt!,
									GAMEMODE\GetImposterCount GAMEMODE\GetFullyInitializedPlayerCount!

								\SetText tostring TRANSLATE("prepare.imposterCount") imposterCount

						-- Count container.
						with \Add "Panel"
							\DockPadding 0, 0, crewSize * 0.5, 0
							\Dock TOP
							\SetTall 0.5 * ScrH! * 0.125

							-- Crewmate
							with \Add "Panel"
								\SetSize crewSize, crewSize
								\DockMargin crewSize * 0.25, 0, 0, 0
								\Dock RIGHT

								-- A slightly unreadable chunk of garbage code
								-- responsible for layering the crewmate sprite.
								layers = {}
								for i = 1, 2
									with layers[i] = \Add "AmongUsCrewmate"
										\Dock FILL
										\SetColor Color 255, 0, 0
										\SetFlipX true

							-- Label
							with \Add "DOutlinedLabel"
								\SetFont "NMW AU Countdown"
								\SetText "..."
								\SetContentAlignment 6
								\Dock FILL

								red    = Color 220, 32, 32
								yellow = Color 255, 255, 30
								white  = Color 255, 255, 255

								.Think = ->
									playerCount = GAMEMODE\GetFullyInitializedPlayerCount!
									needed = GAMEMODE.ConVars.MinPlayers\GetInt!
									maxPlayers = game.MaxPlayers!

									\SetText "#{playerCount}/#{maxPlayers}"

									\SetColor if playerCount > needed
										white
									elseif playerCount == needed
										yellow
									else
										red

				-- Middle
				with \Add "Panel"
					\SetWide ScrW! * 0.25
					\Dock RIGHT

					with \Add "DOutlinedLabel"
						\SetTall 0.5 * ScrH! * 0.125
						\Dock TOP
						\SetText ""
						\SetContentAlignment 5
						\SetFont "NMW AU Countdown"
						\SetColor Color 255, 255, 255
						.Think = ->
							\SetText tostring if not GAMEMODE.MapManifest
								TRANSLATE "prepare.invalidMap"
							elseif GAMEMODE.ClientSideConVars.SpectatorMode\GetBool!
								TRANSLATE "prepare.spectator"
							elseif not GAMEMODE.ConVars.ForceAutoWarmup\GetBool! and CAMI.PlayerHasAccess LocalPlayer!, GAMEMODE.PRIV_START_ROUND
								TRANSLATE "prepare.admin"
							else
								TRANSLATE "prepare.warmup"

					with \Add "DOutlinedLabel"
						\SetTall 0.5 * ScrH! * 0.125
						\Dock BOTTOM
						\SetText ""
						\SetContentAlignment 5
						\SetFont "NMW AU Start Subtext"
						\SetColor Color 255, 255, 255

						.Think = ->
							needed = GAMEMODE.ConVars.MinPlayers\GetInt!

							\SetText tostring if not GAMEMODE.MapManifest
								TRANSLATE "prepare.invalidMap.subText"
							elseif GAMEMODE\GetFullyInitializedPlayerCount! < needed
								TRANSLATE "prepare.waitingForPlayers"
							elseif not GAMEMODE.ConVars.ForceAutoWarmup\GetBool! and CAMI.PlayerHasAccess LocalPlayer!, GAMEMODE.PRIV_START_ROUND
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
	with @Add "Panel"
		\SetTall ScrH! * 0.09
		\Dock TOP
		pad = ScrH! * 0.015
		\DockPadding pad, pad, pad, pad

		with \Add "Panel"
			\SetWide ScrW! * 0.35
			\Dock LEFT

			pad = ScrH! * 0.003
			\DockPadding pad, pad, pad, pad

			outerColor = Color 0, 0, 0
			.Paint = (_, w, h) ->
				draw.RoundedBox 6, 0, 0, w, h, outerColor

			with \Add "Panel"
				\Dock FILL

				pad = ScrH! * 0.008
				\DockPadding pad, pad, pad, pad

				innerColor = Color 170, 188, 188
				taskBarOuterColor = Color 51, 51, 51

				pad = ScrH! * 0.005
				.Paint = (_, w, h) ->
					draw.RoundedBox 4, 0, 0, w, h, innerColor

					draw.RoundedBox 4, pad, pad, w - pad*2, h - pad*2, taskBarOuterColor

				with \Add "Panel"
					\Dock FILL

					@taskBarLabel = with \Add "DOutlinedLabel"
						\SetColor Color 255, 255, 255
						\SetZPos 1
						\SetFont "NMW AU Taskbar"
						\SetText "  " .. TRANSLATE "tasks.totalCompleted"
						\SetContentAlignment 4

						-- If there's a time limit, dock the timer to the right side.
						if GAMEMODE\GetTimeLimit! > 0
							with \Add "DOutlinedLabel"
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

					with @taskbar = \Add "Panel"
						taskBarInnerColor = Color 68, 216, 68

						.Paint = (_, w, h) ->
							surface.SetDrawColor taskBarInnerColor
							surface.DrawRect 0, 0, w, h

						\NewAnimation 0, 0, 0, ->
							refW, refH = @taskbar\GetParent!\GetSize!
							@taskbar\SetSize 0, refH

							@taskBarLabel\SetSize refW, refH

		-- The task list.
		@taskBoxContainer = with @Add "Panel"
			local taskLabel

			margin = ScrH! * 0.015
			\DockMargin margin, 0, 0, 0
			\SetWide ScrW! * 0.35
			\Dock LEFT

			-- Label container.
			with \Add "Panel"
				\Dock TOP
				\SetTall ScrH! * 0.05

				taskLabel = with \Add "DOutlinedLabel"
					\Dock LEFT

					key = string.upper input.LookupBinding("gmod_undo") or "?"

					text = "(#{key}) " .. tostring TRANSLATE if impostor
						"hud.fakeTasks"
					else
						"hud.tasks"

					\SetText "  #{text}  "

					\SetFont "NMW AU Taskbar"
					\SetContentAlignment 5

					oldPaint = .Paint
					.Paint = (w, h) =>
						surface.SetDrawColor 255, 255, 255, 16
						surface.DrawRect 0, 0, w, h
						oldPaint @, w, h

					\SizeToContentsX!

			@tasks = {}
			@taskBox = with \Add "Panel"
				\Dock FILL
				padding = ScrW! * 0.005
				\DockPadding padding, 0, 0, 0

				.PerformLayout = ->
					local max
					for child in *\GetChildren!
						sizeX = child\GetContentSize!
						if not max or sizeX > max
							max = sizeX

					_, childHeight = \ChildrenSize!
					.__maxWidth  = padding * 2 + (max or 0)
					.__maxHeight = childHeight

				\InvalidateLayout!

				.Paint = (_, w, h) ->
					surface.SetDrawColor 255, 255, 255, 16
					labelW, labelH = taskLabel\GetSize!

					surface.DrawRect 0, 0,
						.__maxWidth or 0, .__maxHeight

	if localPlayerTable
		-- Use button. Content-aware.
		with @use = @buttons\Add "Panel"
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
					if ent\GetClass! == "prop_vent" or ent\GetClass! == "func_vent"
						MAT_BUTTONS.vent

				if not mat
					mat = MAT_BUTTONS.use

				-- Like, jesus christ man.
				surface.SetDrawColor COLOR_WHITE
				surface.SetMaterial mat

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!

		-- Use button. Content-aware.
		with @report = @buttonsTwo\Add "Panel"
			\SetWide @buttonsTwo\GetTall!
			\DockMargin 0, 0, ScreenScale(5), 0
			\Dock RIGHT

			.Think = =>
				if IsValid GAMEMODE.ReportHighlight
					\SetAlpha 255
				else
					\SetAlpha 32

			mat = MAT_BUTTONS.report
			.Paint = (_, w, h) ->
				-- Here we are again.
				surface.SetDrawColor COLOR_WHITE
				surface.SetMaterial mat

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!

		-- Kill button for imposerts. Content-aware.
		if impostor
			with @AddTaskEntry!
				\SetText tostring TRANSLATE "hud.sabotageAndKill"
				\SetColor Color 255, 0, 0

			with @kill = @buttons\Add "Panel"
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

					surface.SetDrawColor COLOR_WHITE.r, COLOR_WHITE.g, COLOR_WHITE.b, alpha
					surface.DrawTexturedRect 0, 0, w, h

					render.PopFilterMag!
					render.PopFilterMin!

					if GAMEMODE.GameData.KillCooldownOverride or (GAMEMODE.GameData.KillCooldown and GAMEMODE.GameData.KillCooldown >= CurTime!)
						time = if GAMEMODE.GameData.KillCooldownOverride
							GAMEMODE.GameData.KillCooldownOverride
						else
							math.max(0, GAMEMODE.GameData.KillCooldown - CurTime!)

						if time > 0
							draw.SimpleTextOutlined string.format("%d", math.floor time),
								"NMW AU Cooldown", w * 0.5, h * 0.5, COLOR_WHITE,
								TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, COLOR_BLACK

		-- The player icon!
		-- for some reason this thing wants to be DPanel
		-- why??
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

				\SetFOV 36
				\SetCamPos \GetCamPos! - Vector 0, 0, 4
				with \GetEntity!
					playerColor = localPlayerTable.color\ToVector!
					.GetPlayerColor = -> playerColor

					\SetAngles Angle 0, 90, 0
					\SetPos \GetPos! - Vector 0, 0, 4

				.LayoutEntity = ->

				textColor = if GAMEMODE.GameData.Imposters[localPlayerTable]
					Color 255, 32, 32
				else
					Color 255, 255, 255

				oldPaint = .Paint
				.Paint = (_, w, h) ->
					-- le old huge chunk of stencil code. shall we?
					render.ClearStencil!

					render.SetStencilEnable true
					render.SetStencilTestMask 0xFF
					render.SetStencilWriteMask 0xFF
					render.SetStencilReferenceValue 0x01

					render.SetStencilCompareFunction STENCIL_NEVER
					render.SetStencilFailOperation STENCIL_REPLACE
					render.SetStencilZFailOperation STENCIL_REPLACE

					surface.DrawPoly circle

					render.SetStencilCompareFunction STENCIL_LESSEQUAL
					render.SetStencilFailOperation STENCIL_KEEP
					render.SetStencilZFailOperation STENCIL_KEEP

					\SetAlpha 255 * if GAMEMODE.GameData.DeadPlayers[localPlayerTable]
						0.65
					else
						1

					oldPaint _, w, h

					render.SetStencilEnable false

					surface.DisableClipping true
					draw.SimpleTextOutlined localPlayerTable.nickname or "", "NMW AU Taskbar",
						w/2, -size * 0.1, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, COLOR_OUTLINE
					surface.DisableClipping false

--- Displays a countdown.
-- @param time Target time.
hud.Countdown = (time) =>
	@countdownTime = time

	if IsValid @countdown
		@countdown\Remove!

	with @countdown = @Add "Panel"
		\SetSize @GetWide!, @GetTall! * 0.1
		\SetPos 0, @GetTall! * 0.7

		color = Color 255, 255, 255
		.Paint = (_, w, h) ->
			draw.SimpleTextOutlined TRANSLATE("hud.countdown")(math.floor math.max 0, @countdownTime - CurTime!),
				"NMW AU Countdown",
				w * 0.5, h * 0.25, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, COLOR_OUTLINE

			if @countdownTime - CurTime! <= 0
				_\Remove!

hud.HideTaskList = (state) =>
	if IsValid @taskBoxContainer
		if state
			@taskBoxContainer\Hide!
		else
			@taskBoxContainer\Show!

hud.ToggleTaskList = (value) =>
	if IsValid @taskBox
		if value == nil
			value = not @taskBox.__hiding

		@taskBox.__hiding = value

		if not @taskBox.__hiding
			@taskBox\Show!
			@taskBox\AlphaTo 255, 0.1, 0
		else
			@taskBox\AlphaTo 0, 0.1, 0, ->
				@taskBox\Hide!

hud.AddTaskEntry = =>
	return unless IsValid @taskBox

	return with @taskBox\Add "DOutlinedLabel"
		\Dock TOP

		\SetTall ScrH! * 0.04
		\SetContentAlignment 4
		\SetFont "NMW AU Taskbar"

		-- Self-descriptive.
		shouldBlink = false
		.SetBlink = (value) =>
			shouldBlink = value

		-- Shim SetColor so we can manipulate the actual color the way we want.
		-- Used primarily for making the task label blink.
		local oldColor
		referenceColor = COLOR_WHITE
		oldSetColor    = .SetColor
		.SetColor = (clr) =>
			referenceColor = clr

		-- Override think for important stuff.
		.Think = (this) ->
			-- If we should blink, blink.
			clr = if shouldBlink and math.floor((SysTime! * 4) % 2) == 0
				COLOR_BLINK
			else
				referenceColor

			-- If the color has been changed, let the panel know.
			if clr ~= oldColor
				oldColor = clr
				oldSetColor this, clr

				if .OnBlink
					\OnBlink!

		-- Gotta call InvalidateParent since changing the text
		-- changes the entry width.
		oldSetText = .SetText
		.SetText = (...) =>
			oldSetText @, ...
			@InvalidateParent!

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
					@__commsBlinker = GAMEMODE\HUD_AddTaskEntry!
					if IsValid @__commsBlinker then with @__commsBlinker
						\SetColor Color 255, 230, 0
						\SetText tostring TRANSLATE "tasks.commsSabotaged"
						\SetBlink true

					if not LocalPlayer!\IsImposter!
						for task in *@tasks
							task\Hide!

					\SetText "  " .. TRANSLATE "tasks.totalCompleted.sabotaged"
					\SetColor Color 255, 64, 64

					@taskbar\AlphaTo 0, 1

				-- Comms have been fixed.
				-- Restore the task list and remove the blinker.
				-- Fix the taskbar text.
				else
					if IsValid @__commsBlinker
						@__commsBlinker\Remove!

					if not LocalPlayer!\IsImposter!
						for task in *@tasks
							task\Show!

					\SetText "  " .. TRANSLATE "tasks.totalCompleted"
					\SetColor Color 255, 255, 255

					@taskbar\AlphaTo 255, 1

			@__oldCommsSabotaged = commsSabotaged

return vgui.RegisterTable hud, "Panel"
