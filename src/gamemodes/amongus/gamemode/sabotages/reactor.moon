export CRISIS_ENABLED = false
if CLIENT
	clr = Color 255, 20, 20, 64

	nextTick = 0
	hook.Add "PreDrawHUD", "NMW AU Crisis", ->
		if CRISIS_ENABLED
			if SysTime! > nextTick
				nextTick = SysTime! + 2.5
				surface.PlaySound "au/alarm_sabotage.ogg"

			if nextTick - SysTime! > 1.8
				cam.Start2D!

				surface.SetDrawColor clr
				surface.DrawRect 0, 0, ScrW!, ScrH!

				cam.End2D!

reactor = {
	Duration: 40
	Init: (data) =>
		@Base.Init @, data

		if data and data.Duration
			@Duration = data.Duration

		if SERVER
			@SetMajor true
			@SetNetworkable "MeltdownTime"
			@SetNetworkable "Submits"

	OnStart: =>
		@Base.OnStart @
		if SERVER
			@__activatedButtons = {}
			@__sabotageSubmits = {}

			@SetSubmits 0
			@SetMeltdownTime CurTime! + @Duration

			GAMEMODE.GameData.Timers[@GetVGUIID!] = true
			timer.Create @GetVGUIID!, @Duration, 1, ->
				@End!
				GAMEMODE\Game_CheckWin GAMEMODE.GameOverReason.Imposter

			buttons = {}
			for ent in *ents.GetAll!
				if ent.GetSabotageName and ent\GetSabotageName! == @GetHandler!
					table.insert buttons, ent

			@SetActivationButtons buttons
		else
			CRISIS_ENABLED = true
			@__taskEntry = GAMEMODE\HUD_AddTaskEntry!
			if IsValid @__taskEntry then with @__taskEntry
				\SetColor Color 255, 230, 0
				\SetText "..."
				\SetBlink true

				oldThink = .Think
				.Think = (this) ->
					time = math.max 0, @GetMeltdownTime! - CurTime!
					\SetText GAMEMODE.Lang.GetEntry("tasks.reactorSabotaged") time, @GetSubmits!, #@GetActivationButtons!

					oldThink this

	OnButtonUse: (playerTable, button) =>
		if SERVER
			GAMEMODE\Sabotage_OpenVGUI playerTable, @, button
			@__activatedButtons[playerTable] = button

			GAMEMODE\Sabotage_OpenVGUI playerTable, @, button, ->
				@__activatedButtons[playerTable] = nil

				@Submit playerTable, 0

	OnSubmit: (playerTable, data) =>
		data = data == 1 and true or nil

		if @__sabotageSubmits[playerTable] ~= data
			@__sabotageSubmits[playerTable] = data

			totalSubmits = {}
			for ply in pairs @__sabotageSubmits
				btn = @__activatedButtons[ply]
				if btn and not totalSubmits[btn]
					totalSubmits[btn] = true

			count = table.Count totalSubmits
			@SetSubmits count

			if @GetSubmits! == #@GetActivationButtons!
				@End!

	OnEnd: =>
		@Base.OnEnd @
		if SERVER
			GAMEMODE.GameData.Timers[@GetVGUIID!] = nil
			timer.Remove @GetVGUIID!
			@SetActivationButtons!

	SetMeltdownTime: (value) =>
		@__meltdownTime = value
		if SERVER
			@SetDirty!

	GetMeltdownTime: => @__meltdownTime or 0

	SetSubmits: (value) =>
		@__submits = value
		if SERVER
			@SetDirty!

	GetSubmits: => @__submits or 0
}

if CLIENT
	TRANSLATE = GM.Lang.GetEntry

	ASSETS = {asset, Material("au/gui/sabotages/reactor/#{asset}.png", "smooth") for asset in *{
		"base"
		"gradient"
	}}

	local textBox
	reactor.OnEnd = =>
		@Base.OnEnd @

		CRISIS_ENABLED = false
		if IsValid @__taskEntry
			@__taskEntry\Remove!

		if IsValid textBox
			textBox\SetText tostring TRANSLATE "sabotage.reactor.nominal"

	reactor.CreateVGUI = =>
		base = vgui.Create "AmongUsSabotageBase"

		with base
			\SetSabotage @
			\Setup with vgui.Create "Panel"
				max_size = ScrH! * 0.7

				\SetSize max_size, max_size

				-- Overlay.
				with \Add "DImage"
					\SetZPos 1
					\SetSize max_size, max_size
					\SetMouseInputEnabled false
					\SetMaterial ASSETS.base

					textBoxX = (max_size / 500) * 46
					textBoxY = (max_size / 500) * 30
					textBoxWidth = (max_size / 500) * 410
					textBoxHeight = (max_size / 500) * 48

					-- Text box.
					with \Add "Panel"
						\SetPos textBoxX, textBoxY
						\SetSize textBoxWidth, textBoxHeight

						textBox = with \Add "Panel"
							\Dock FILL
							\SetHeight textBoxHeight

							-- :)
							surface.CreateFont "NMW AU Reactor Text", {
								font: "Lucida Console"
								size: textBoxHeight * 0.8
							}

							-- HERE BE a wall of upvalues.
							curState = 0
							curPos = 0
							curLen = 0
							target = 0
							waitAccum = 0
							labelText = ""

							.SetText = (text) =>
								labelText = string.upper text

								surface.SetFont "NMW AU Reactor Text"
								curLen = surface.GetTextSize text

								-- Override whatever animation is going on.
								if curPos ~= 0
									curState = 4
									distance = -curPos
									waitAccum = 0
									target = 0

								-- Wait, then go right if necessary.
								elseif curLen > textBoxWidth
									waitAccum = 0
									curState = 1

							.GetText = -> labelText
							color = Color 0, 0, 0
							.Paint = (_, w, h) ->
								-- How about some Turing state machine bullshit?
								switch curState
									-- Wait before going right.
									when 1
										if curLen > textBoxWidth
											waitAccum += FrameTime!
											if waitAccum >= 1
												waitAccum = 0
												curState = 2
												target = -(curLen - textBoxWidth)

									-- Go right.
									when 2
										curPos = math.max target, curPos - FrameTime! * 300
										if curPos <= target
											curState = 3

									-- Wait before going left.
									when 3
										waitAccum += FrameTime!
										if waitAccum >= 1
											waitAccum = 0
											curState = 4
											target = 0

									-- Go left.
									when 4
										curPos = math.min target, curPos + FrameTime! * 300
										if curPos >= target
											curState = 1

								draw.SimpleText labelText, "NMW AU Reactor Text", curPos,
									h/2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER

							\SetText tostring TRANSLATE "sabotage.reactor.hold"

				underlayX = (max_size / 500) * 90
				underlayY = (max_size / 500) * 96
				underlayWidth = (max_size / 500) * 300
				underlayHeight = (max_size / 500) * 370
				gradientHeight = (max_size / 500) * 84

				-- UNDERlay!!!!!
				with \Add "DButton"
					\SetPos underlayX, underlayY
					\SetSize underlayWidth, underlayHeight
					\SetText ""

					.OnDepressed = ->
						base\Submit 1, false
						textBox\SetText tostring TRANSLATE "sabotage.reactor.waiting"

					.OnReleased = ->
						base\Submit 0, false
						textBox\SetText tostring TRANSLATE "sabotage.reactor.hold"

					.Paint = (_, w, h) ->
						surface.SetDrawColor 255, 45, 0
						surface.DrawRect 0, 0, w, h

						if \IsDown!
							surface.SetDrawColor 255, 255, 255
							surface.SetMaterial ASSETS.gradient

							currentY = h/2 + h * 0.5 * math.sin CurTime!
							surface.DrawTexturedRect 0, currentY - gradientHeight / 2,
								w, gradientHeight

			\Popup!

		return base

return reactor
