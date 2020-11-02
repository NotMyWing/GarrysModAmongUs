export CRISIS_ENABLED = false
if CLIENT
	clr = Color 255, 20, 20, 64

	nextTick = 0
	hook.Add "PreDrawHUD", "NMW AU Crisis", ->
		if CRISIS_ENABLED
			if SysTime! > nextTick
				nextTick = SysTime! + 2.5
				surface.PlaySound "au/alarm_sabotage.wav"

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
				GAMEMODE\CheckWin GAMEMODE.GameOverReason.Imposter

			buttons = {}
			for ent in *ents.GetAll!
				if ent.GetSabotageName and ent\GetSabotageName! == @GetHandler!
					table.insert buttons, ent

			@SetActivationButtons buttons
		else
			CRISIS_ENABLED = true
			@__taskEntry = with GAMEMODE\HUD_AddTaskEntry!
				\SetColor Color 255, 230, 0
				\SetText "..."
				\SetBlink true
				.Think = ->
					time = math.max 0, @GetMeltdownTime! - CurTime!
					\SetText GAMEMODE.Lang.GetEntry("tasks.reactorSabotaged") time, @GetSubmits!, #@GetActivationButtons!

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
}

if CLIENT
	with reactor
		.CreateVGUI = =>
			base = vgui.Create "AmongUsSabotageBase"

			with base
				\SetSabotage @
				\Setup with vgui.Create "DPanel"
					max_size = ScrH! * 0.35

					\SetSize max_size, max_size * 0.55

					\SetBackgroundColor Color 64, 64, 64
					with \Add "DButton"
						margin = ScrH! * 0.01
						\DockMargin margin * 4, 0, margin * 4, margin * 4
						\SetTall ScrH! * 0.05
						\SetFont "NMW AU PlaceholderText"
						\Dock BOTTOM
						\SetText "Submit"
						.OnDepressed = ->
							base\Submit 1, false
						.OnReleased = ->
							base\Submit 0, false

				\Popup!

			return base

return reactor
