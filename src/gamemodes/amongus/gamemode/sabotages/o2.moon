export CRISIS_ENABLED = false
if CLIENT
	clr = Color 255, 20, 20, 64

	nextTick = 0
	hook.Add "PreDrawHUD", "NMW AU Crisis", ->
		if CRISIS_ENABLED
			if SysTime! > nextTick
				nextTick = SysTime! + 2
				surface.PlaySound "au/alarm_sabotage.ogg"

			if nextTick - SysTime! > 1.5
				cam.Start2D!

				surface.SetDrawColor clr
				surface.DrawRect 0, 0, ScrW!, ScrH!

				cam.End2D!

o2 = {
	Duration: 40
	Init: (data) =>
		@Base.Init @, data

		if data and data.Duration
			@Duration = data.Duration

		if SERVER
			@SetMajor true
			@SetNetworkable "MeltdownTime"
			@SetNetworkable "Submits"
			@SetNetworkable "NeededSubmits"
			@SetNetworkable "Code"

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

			@SetCode math.random 10000, 100000
			@SetNeededSubmits #buttons
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
					\SetText GAMEMODE.Lang.GetEntry("tasks.oxygenSabotaged") time, @GetSubmits!, @GetNeededSubmits!

					oldThink this

	OnButtonUse: (playerTable, button) =>
		if SERVER
			GAMEMODE\Sabotage_OpenVGUI playerTable, @, button
			@__activatedButtons[playerTable] = button
		else
			@__lastUsedButton = button

	OnSubmit: (playerTable, data) =>
		if btn = @__activatedButtons[playerTable]
			return if data ~= @GetCode!

			removed = false

			activationButtons = @GetActivationButtons!
			for id, button in ipairs activationButtons
				if button == btn
					table.remove activationButtons, id
					removed = true
					break

			if removed
				@SetActivationButtons table.Copy activationButtons

				@SetSubmits @GetSubmits! + 1
				if @GetSubmits! == @GetNeededSubmits!
					@End!

	OnEnd: =>
		@Base.OnEnd @
		if SERVER
			GAMEMODE.GameData.Timers[@GetVGUIID!] = nil
			timer.Remove @GetVGUIID!
			@SetActivationButtons!

		else
			CRISIS_ENABLED = false
			if IsValid @__taskEntry
				@__taskEntry\Remove!

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

	SetNeededSubmits: (value) =>
		@__neededSubmits = value
		if SERVER
			@SetDirty!

	GetNeededSubmits: => @__neededSubmits or 0

	SetCode: (value) =>
		@__code = value
		if SERVER
			@SetDirty!

	GetCode: => @__code or ""
}

if CLIENT
	surface.CreateFont "NMW AU O2 Keypad", {
		font: "Roboto"
		size: 0.05 * math.min ScrH! * 0.8, ScrW! * 0.8
	}

	surface.CreateFont "NMW AU O2 Keypad Note", {
		font: "Roboto"
		size: 0.04 * math.min ScrH! * 0.8, ScrW! * 0.8
	}

	with o2
		.CreateVGUI = =>
			base = vgui.Create "AmongUsSabotageBase"

			with base
				\SetSabotage @
				\Setup with vgui.Create "DPanel"
					max_size = ScrH! * 0.5

					\SetSize max_size * 0.6, max_size

					\SetBackgroundColor Color 64, 64, 64

					current = ""
					code = @GetCode! or "???"

					basePaint = .Paint

					textColor = Color(0, 0, 0)
					.Paint = (_, w, h) ->
						basePaint _, w, h

						surface.SetDrawColor 250, 220, 90

						width = w * 0.75
						height = width * 0.5

						surface.DisableClipping true
						surface.DrawRect w * 0.45, h * 0.97, width, height
						draw.SimpleText "today's code", "NMW AU O2 Keypad Note", w * 0.55, h * 0.97 + height * 0.33, textColor, nil, TEXT_ALIGN_CENTER
						draw.SimpleText code, "NMW AU O2 Keypad Note", w * 0.55, h * 0.97 + height * 0.66, textColor, nil, TEXT_ALIGN_CENTER
						surface.DisableClipping false

					buttonSize = 0.275 * math.min \GetSize!
					with \Add "Panel"
						\SetSize 3 * buttonSize, 5.5 * buttonSize
						\Center!

						with \Add "Panel"
							\Dock TOP
							\SetTall 1 * buttonSize
							\DockMargin 0, 0, 0, buttonSize * 0.5
							.Paint = (_, w, h) ->
								draw.RoundedBox 6, 0, 0, w, h, Color 32, 32, 32
								draw.SimpleText current, "NMW AU O2 Keypad", w * 0.05, h/2, Color(255, 255, 255), nil, TEXT_ALIGN_CENTER

						for j = 1, 3
							with \Add "Panel"
								\Dock TOP
								\SetTall 1 * buttonSize

								for i = 1, 3
									with \Add "DButton"
										\SetWide buttonSize
										\SetFont "NMW AU PlaceholderText"
										\Dock LEFT
										\SetText tostring (j - 1) * 3 + i
										.DoClick = ->
											if #current < 5
												current ..= \GetText!

						with \Add "Panel"
							\Dock TOP
							\SetTall 1 * buttonSize

							-- Clear
							with \Add "DButton"
								\SetWide buttonSize
								\SetFont "NMW AU PlaceholderText"
								\Dock LEFT
								\SetText "X"
								.DoClick = ->
									current = ""

							-- 0
							with \Add "DButton"
								\SetWide buttonSize
								\SetFont "NMW AU PlaceholderText"
								\Dock LEFT
								\SetText tostring 0
								.DoClick = ->
									if #current < 5
										current ..= \GetText!

							-- Submit
							with \Add "DButton"
								\SetWide buttonSize
								\SetFont "NMW AU PlaceholderText"
								\Dock LEFT
								\SetText "Submit"
								.DoClick = ->
									num = tonumber current
									if num == code
										base\Submit code, true
									else
										current = ""
				\Popup!

			return base

return o2
