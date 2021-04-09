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
			not false ~= hook.Call "GMAU Lights ShouldFade", nil, ply

		isFogEnabled = GetGlobalBool "NMW AU LightsOff"

		-- Modulate the fog if it's enabled.
		if isFogEnabled and FOG_MUL < 1
			FOG_MUL = math.min 1, FOG_MUL + FrameTime! * 0.4
		elseif not isFogEnabled and FOG_MUL > 0
			FOG_MUL = math.max 0, FOG_MUL - FrameTime! * 0.6

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
			not false ~= hook.Call "GMAU Lights ShouldFade", nil, ply

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
			not false ~= hook.Call "GMAU Lights ShouldFade", nil, ply

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

lights = {
	Init: (data) =>
		@Base.Init @, data

		if SERVER
			@SetMajor true
			@SetPersistent true
			@SetNetworkable "Lights"
			@SetNetworkable "Reverse"

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
				@SetReverse GAMEMODE.Util.Shuffle { true, true, false, false, false }

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

	SetReverse: (value) =>
		@__reverse = value
		if SERVER
			@SetDirty!

	GetReverse: => @__reverse
}

if CLIENT
	COLOR_ACTIVE = Color 0, 255, 0
	COLOR_INACTIVE = Color 26, 77, 26

	ASSETS = {asset, Material("au/gui/sabotages/lights/#{asset}.png", "smooth") for asset in *{
		"base"
		"switch"
		"switchshadow"
		"light"
		"lightshine"
		"switchflipped"
		"wires"
	}}

	SOUNDS =
		switch: "au/panel_electrical_switch.ogg"

	class LimitedLinkedList
		new: (@__max = 1, @__count = 0) =>
		getFirst: => @__first
		getLast: => @__last
		getCount: => math.min @__max, @__count

		push: (value) =>
			@__count += 1 if @__count <= @__max

			node = { :value }

			-- If the first element already exists...
			if @__first
				-- link the new node to it and vice versa.
				node.next = @__first
				@__first.prev = node

			-- otherwise make the new node the last element.
			else
				@__last = node

			@__first = node

			-- If we've reached the max amount of elements,
			-- unlink the last one and tell the GC to get rid of it.
			if @__count > @__max
				@__last = @__last.prev
				@__last.next = nil

	lights.SetLights = (value) =>
		@__lights = value

		return if not @__reverse
		return if not @downSwitches or not @upSwitches

		@__numActive = 0
		for i = 1, 5
			@__numActive += 1 if value[i]

			upSwitch = @__reverse[i] and @downSwitches[i] or @upSwitches[i]
			downSwitch =  @__reverse[i] and @upSwitches[i] or @downSwitches[i]

			upSwitch\SetVisible value[i] if IsValid upSwitch
			downSwitch\SetVisible not value[i] if IsValid downSwitch

	OSCIL_COUNT = 120

	PAINT_OSCIL = (w, h) =>
		current = @ValueList\getFirst!
		surface.SetDrawColor 0, 255, 0

		i = 1
		-- Traverse the linked list.
		while current
			if current.prev
				-- Multiply and flip the values.
				cy = h - h * current.value
				py = h - h * current.prev.value

				-- Flip the values again.
				cx = w - w * ((i - 1) / (OSCIL_COUNT - 1))
				px = w - w * ((i - 2) / (OSCIL_COUNT - 1))

				-- This will probably look horrible for 4K players.
				-- But oh well!
				surface.DrawLine cx, cy, px, py

			current = current.next
			i += 1

	lights.CreateVGUI = =>
		base = vgui.Create "AmongUsSabotageBase"

		with base
			\SetSabotage @
			\Setup with vgui.Create "DImage"
				-- Count the amount of active lights.
				@__numActive = 0
				for i = 1, 5
					@__numActive += 1 if @GetLights![i]

				max_size = ScrH! * 0.85

				\SetSize max_size, max_size
				\SetMaterial ASSETS.base

				oscilWidth  = (max_size / 504) * 422
				oscilHeight = (max_size / 504) * 58

				oscilX = (max_size / 504) * 42
				topOscilY = (max_size / 504) * 40
				midOscilY = (max_size / 504) * 140
				botOscilY = (max_size / 504) * 240

				wiresWidth = (max_size / 504) * 530
				wiresHeight = (max_size / 504) * 525

				wiresOffsetX = (max_size / 504) * -50
				wiresOffsetY = (max_size / 504) * -150

				-- Override Paint and draw wires behind the panel.
				-- Hacky but gets the job done.
				oldPaint = .Paint
				.Paint = (w, h) =>
					old = DisableClipping true

					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial ASSETS.wires
					surface.DrawTexturedRect w/2 - wiresWidth/2 + wiresOffsetX,
						h/2 - wiresHeight/2 + wiresOffsetY,
						wiresWidth, wiresHeight

					DisableClipping old

					oldPaint @, w, h

				-- Top oscillator.
				-- Random data. Fast.
				with \Add "Panel"
					-- Define the oscillation function to avoid duplicating code.
					oscFunc = ->
						0.1 + math.random! * 0.8

					\SetPos oscilX, topOscilY
					\SetSize oscilWidth, oscilHeight
					.Paint = PAINT_OSCIL

					-- Pre-fill the linked list with data.
					.ValueList = LimitedLinkedList OSCIL_COUNT
					for i = 1, OSCIL_COUNT
						.ValueList\push oscFunc!

					nextOscillation = 0
					.Think = ->
						-- Roughly 120 oscillations per second.
						-- Avoid oscillating faster with higher FPS.
						if nextOscillation < CurTime!
							nextOscillation = CurTime! + 0.016

							-- Double push because Think is FPS-bound.
							-- lmao
							for i = 1, 2
								.ValueList\push oscFunc!

				-- Middle oscillator.
				-- Horizontal bar that displays the amount of active lights,
				-- ships with annoying flickering.
				with \Add "Panel"
					\SetPos oscilX, midOscilY
					\SetSize oscilWidth, oscilHeight

					with \Add "Panel"
						margin = oscilHeight * 0.1
						\DockMargin margin, margin, margin, margin
						\Dock FILL

						.Paint = (_, w, h) ->
							surface.SetDrawColor 0, 255, 0
							surface.DrawRect 0, 0,
								w * ((@__numActive / 5) * 0.98 + math.random! * 0.02), h

				-- Bottom oscillator.
				-- Similar to the top oscillator, but instead displays useful info.
				with \Add "Panel"
					\SetPos oscilX, botOscilY
					\SetSize oscilWidth, oscilHeight

					.ValueList = LimitedLinkedList OSCIL_COUNT
					for i = 1, OSCIL_COUNT
						.ValueList\push (@__numActive / 5) * 0.9 + math.random! * 0.1

					.Paint = PAINT_OSCIL

					nextOscillation = 0
					.Think = ->
						-- Roughly 60 oscillations per second.
						-- Avoid oscillating faster with higher FPS.
						if nextOscillation < CurTime!
							nextOscillation = CurTime! + 0.016
							.ValueList\push (@__numActive / 5) * 0.9 + math.random! * 0.1

				switchOriginX = (max_size / 504) * 61
				switchOriginY = (max_size / 504) * 386
				switchYOffset = (max_size / 504) * 4
				switchSpacing = (max_size / 504) * 97
				switchWidth = (max_size / 504) * 39
				switchHeight = (max_size / 504) * 52

				lightWidth = (max_size / 504) * 32
				lightHeight = (max_size / 504) * 33
				lightOffset = (max_size / 504) * 54

				@upSwitches = {}
				@downSwitches = {}

				for i = 1, 5
					submit = ->
						if @GetActive!
							surface.PlaySound SOUNDS.switch
							base\Submit i, false

					-- Shadow.
					with \Add "DImage"
						\SetSize switchWidth, switchHeight
						\SetPos switchOriginX - switchWidth / 2 + switchSpacing * (i - 1),
							switchOriginY - switchYOffset
						\SetMaterial ASSETS.switchshadow

					-- Up switch.
					@upSwitches[i] = with \Add "DImageButton"
						\SetSize switchWidth, switchHeight
						\SetPos switchOriginX - switchWidth / 2 + switchSpacing * (i - 1),
							switchOriginY + switchYOffset - switchHeight
						\SetMaterial ASSETS.switch
						.DoClick = submit

						shouldHide = not @GetLights![i]
						if @GetReverse![i]
							shouldHide = not shouldHide

						\Hide! if shouldHide

					-- Down switch.
					@downSwitches[i] = with \Add "DImageButton"
						\SetSize switchWidth, switchHeight
						\SetPos switchOriginX - switchWidth / 2 + switchSpacing * (i - 1),
							switchOriginY - switchYOffset
						\SetMaterial ASSETS.switchflipped
						.DoClick = submit

						shouldHide = @GetLights![i]
						if @GetReverse![i]
							shouldHide = not shouldHide

						\Hide! if shouldHide

					-- LED.
					with \Add "Panel"
						\SetSize lightWidth, lightHeight
						\SetPos switchOriginX - lightWidth / 2 + switchSpacing * (i - 1),
							switchOriginY + lightOffset

						.Paint = (_, w, h) ->
							surface.SetDrawColor @GetLights![i] and COLOR_ACTIVE or COLOR_INACTIVE
							surface.SetMaterial ASSETS.light
							surface.DrawTexturedRect 0, 0, w, h

						with \Add "DImage"
							\Dock FILL
							\SetMaterial ASSETS.lightshine

			\Popup!

		return base

return lights
