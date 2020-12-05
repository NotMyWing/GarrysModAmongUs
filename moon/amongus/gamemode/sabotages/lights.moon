local FOG_ENABLED
FOG_MUL = 0

if CLIENT
	colorModifyParams = {
		"$pp_colour_addr": 0
		"$pp_colour_addg": 0
		"$pp_colour_addb": 0
		"$pp_colour_brightness": 0
		"$pp_colour_contrast": 1
		"$pp_colour_colour": 1
		"$pp_colour_mulr": 0
		"$pp_colour_mulg": 0
		"$pp_colour_mulb": 0
	}

	hook.Add "RenderScreenspaceEffects", "NMW AU Sabotage Fog Sharpen", ->
		-- Modulate the fog if it's enabled.
		if FOG_ENABLED and FOG_MUL < 1
			FOG_MUL = math.min 1, FOG_MUL + FrameTime! * 0.3
		elseif not FOG_ENABLED and FOG_MUL > 0
			FOG_MUL = math.max 0, FOG_MUL - FrameTime! * 0.5

		if FOG_MUL ~= 0 and not GAMEMODE.GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]]
			colorModifyParams["$pp_colour_colour"] = 1 - (0.5 * FOG_MUL)
			colorModifyParams["$pp_colour_contrast"] = 1 - (0.75 * FOG_MUL)
			DrawColorModify colorModifyParams
			DrawSharpen 1 * FOG_MUL, 3 * FOG_MUL
comms = {
	Init: (data) =>
		@Base.Init @, data

		if SERVER
			@SetMajor true
			@SetPersistent true
			@SetNetworkable "Lights"

	OnStart: =>
		@Base.OnStart @
		if SERVER
			local btn
			for ent in *ents.GetAll!
				if ent.GetSabotageName and ent\GetSabotageName! == @GetHandler!
					btn = ent
					break

			if btn
				@SetActivationButtons btn
				@SetLights GAMEMODE.Util.Shuffle { true, true, false, false, false }
		else
			@__taskEntry = with GAMEMODE\HUD_AddTaskEntry!
				\SetColor Color 255, 230, 0
				\SetText "..."
				\SetBlink true
				.OnBlink = ->
					\SetText GAMEMODE.Lang.GetEntry("tasks.lightsSabotaged") 100 * (1 - FOG_MUL)

			FOG_ENABLED = true

	OnButtonUse: (playerTable, button) =>
		if SERVER
			GAMEMODE\Sabotage_OpenVGUI playerTable, @, button

	OnSubmit: (playerTable, data) =>
		if @__lights[data] ~= nil
			@__lights[data] = not @__lights[data]

			@SetLights table.Copy @__lights

			for state in *@__lights
				return unless state

			@End!

	OnEnd: =>
		@Base.OnEnd @
		if SERVER
			@SetActivationButtons!
		elseif IsValid @__taskEntry
			@__taskEntry\Remove!

			FOG_ENABLED = nil

	SetLights: (value) =>
		@__lights = value
		if SERVER
			@SetDirty!

	GetLights: => @__lights
}

if CLIENT
	with comms
		.CreateVGUI = =>
			base = vgui.Create "AmongUsSabotageBase"

			with base
				\SetSabotage @
				\Setup with vgui.Create "Panel"
					max_size = ScrH! * 0.7

					\SetSize max_size, max_size * 0.325
					\SetBackgroundColor Color 64, 64, 64

					for i = 1, 2
						with \Add "Panel"
							margin = ScrH! * 0.01
							\DockMargin margin * 4, 0, margin * 4, margin * 4
							\SetTall ScrH! * 0.05
							\Dock BOTTOM

							with \Add "Panel"
								\SetTall ScrH! * 0.05

								for j = 1, 5
									if i == 2
										with \Add "Panel"
											\SetWide ScrH! * 0.05
											\DockMargin 0, 0, ScrH! * 0.05, 0
											\Dock LEFT

											active = Color 32, 250, 32
											inactive = Color 8, 8, 8

											.Paint = (_, w, h) ->
												surface.SetDrawColor @GetLights![j] and active or inactive
												surface.DrawRect 0, 0, w, h
									else
										with \Add "DButton"
											\SetWide ScrH! * 0.05
											\DockMargin 0, 0, ScrH! * 0.05, 0
											\Dock LEFT
											\SetText ""
											.DoClick = ->
												if @GetActive!
													base\Submit j, false

								\NewAnimation 0, 0, 0, ->
									\InvalidateLayout!
									\NewAnimation 0, 0, 0, ->
										\SizeToChildren true, false
										\Center!
				\Popup!

			return base

return comms
