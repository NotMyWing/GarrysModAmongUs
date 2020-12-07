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
		localPlayerTable = LocalPlayer!\GetAUPlayerTable!

		shouldPaint = localPlayerTable and
			not LocalPlayer!\IsImposter! and not LocalPlayer!\IsDead! and
			not false == hook.Call "GMAU Lights ShouldFade", nil, ply

		isFogEnabled = shouldPaint and GetGlobalBool "NMW AU LightsOff"

		-- Modulate the fog if it's enabled.
		if isFogEnabled and FOG_MUL < 1
			FOG_MUL = math.min 1, FOG_MUL + FrameTime! * 0.3
		elseif not isFogEnabled and FOG_MUL > 0
			FOG_MUL = math.max 0, FOG_MUL - FrameTime! * 0.5

		if FOG_MUL ~= 0 and shouldPaint
			colorModifyParams["$pp_colour_colour"] = 1 - (0.5 * FOG_MUL)
			colorModifyParams["$pp_colour_contrast"] = 1 - (0.75 * FOG_MUL)
			DrawColorModify colorModifyParams
			DrawSharpen 1 * FOG_MUL, 3 * FOG_MUL

	MAX_DISTANCE  = math.pow 128, 2
	MIN_DISTANCE  = math.pow 64, 2
	DISTANCE_DIFF = MAX_DISTANCE - MIN_DISTANCE

	valueMemo = {}

	-- Make the players fade with distance.
	-- Store the value for other hooks.
	hook.Add "PrePlayerDraw", "NMW AU Sabotage Fog", (ply) ->
		localPlayerTable = LocalPlayer!\GetAUPlayerTable!

		shouldPaint = localPlayerTable and
			not LocalPlayer!\IsImposter! and not LocalPlayer!\IsDead! and
			not false == hook.Call "GMAU Lights ShouldFade", nil, ply

		if FOG_MUL > 0 and shouldPaint
			distance = math.Clamp ply\GetPos!\DistToSqr(LocalPlayer!\GetPos!),
				MIN_DISTANCE, MAX_DISTANCE

			value = 1 - FOG_MUL * (1 - ((MAX_DISTANCE - distance) / DISTANCE_DIFF))

			valueMemo[ply] = value

			-- Don't draw at all if too far.
			if value == 0
				return true

			ply.__fogBlend = render.GetBlend!
			render.SetBlend value

	-- Restore the blend.
	hook.Add "PostPlayerDraw", "NMW AU Sabotage Fog", (ply) ->
		if ply.__fogBlend
			render.SetBlend ply.__fogBlend

			ply.__fogBlend = nil

	-- Hide the nicknames when the sabotage is active.
	hook.Add "GMAU CalcNicknames", "NMW AU Sabotage Fog", (calc) ->
		return if false == hook.Call "GMAU Lights ShouldFade", nil, ply

		if FOG_MUL > 0 and not LocalPlayer!\IsImposter!
			return true if (valueMemo[calc.player] or 1) <= 0

	-- Override the rendering of corpse models.
	corpseRenderOverride = =>
		return if false == hook.Call "GMAU Lights ShouldFade", nil, ply

		local oldBlend
		shouldPaint = localPlayerTable and
			not LocalPlayer!\IsImposter! and not LocalPlayer!\IsDead! and
			not false == hook.Call "GMAU Lights ShouldFade", nil, ply

		if FOG_MUL > 0 and not shouldPaint
			distance = math.Clamp @GetPos!\DistToSqr(LocalPlayer!\GetPos!),
				MIN_DISTANCE, MAX_DISTANCE

			value = 1 - FOG_MUL * (1 - ((MAX_DISTANCE - distance) / DISTANCE_DIFF))

			oldBlend = render.GetBlend!
			render.SetBlend value

		@DrawModel!

		render.SetBlend oldBlend if oldBlend

	-- Track all newly-created ragdolls
	hook.Add "OnEntityCreated", "NMW AU Sabotage Fog Corpse", (ent) ->
		if IsValid(ent) and GAMEMODE\IsPlayerBody(ent)
			ent.RenderOverride = corpseRenderOverride

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
			SetGlobalBool "NMW AU LightsOff", true
			local btn
			for ent in *ents.GetAll!
				if ent.GetSabotageName and ent\GetSabotageName! == @GetHandler!
					btn = ent
					break

			if btn
				@SetActivationButtons btn
				@SetLights GAMEMODE.Util.Shuffle { true, true, false, false, false }

		else
			@__taskEntry = GAMEMODE\HUD_AddTaskEntry!
			if IsValid @__taskEntry then with @__taskEntry
				\SetColor Color 255, 230, 0
				\SetText "..."
				\SetBlink true
				.OnBlink = ->
					\SetText GAMEMODE.Lang.GetEntry("tasks.lightsSabotaged") 100 * (1 - FOG_MUL)

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
			SetGlobalBool "NMW AU LightsOff", false

		elseif IsValid @__taskEntry
			@__taskEntry\Remove!

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
				\Setup with vgui.Create "DPanel"
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
