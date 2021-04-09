comms = {
	Init: (data) =>
		@Base.Init @, data

		if SERVER
			@SetMajor true
			@SetPersistent true
			@SetNetworkable "Position"

	OnStart: =>
		@Base.OnStart @
		if SERVER
			@SetPosition math.random -110, 110
			GAMEMODE\SetCommunicationsDisabled true

			local btn
			for ent in *ents.GetAll!
				if ent.GetSabotageName and ent\GetSabotageName! == @GetHandler!
					btn = ent
					break

			if btn
				@SetActivationButtons btn

	OnButtonUse: (playerTable, button) =>
		if SERVER
			GAMEMODE\Sabotage_OpenVGUI playerTable, @, button

	OnSubmit: =>
		@End!

	OnEnd: =>
		@Base.OnEnd @
		if SERVER
			GAMEMODE\SetCommunicationsDisabled false
			@SetActivationButtons!

	SetPosition: (value) =>
		@__position = value
		if SERVER
			@SetDirty!

	GetPosition: => @__position or 0
}

if CLIENT
	ROTATION_MATRIX = Matrix!

	COLOR_ACTIVE = Color 0, 255, 0
	COLOR_INACTIVE = Color 255, 0, 0

	COMMONS = {asset, Material("au/gui/sabotages/common/#{asset}.png", "smooth") for asset in *{
		"light"
		"lightshine"
	}}

	ASSETS = {asset, Material("au/gui/sabotages/comms/#{asset}.png", "smooth") for asset in *{
		"radio"
		"headphones"
		"dial"
	}}

	-- Swiggity swooty.
	comms.SetPosition = (value) =>
		@__position = value
		@__theta = nil

	OSCIL_COUNT = 200
	comms.CreateVGUI = (data) =>
		base = vgui.Create "AmongUsSabotageBase"

		-- Create sounds and attach them to the button (radio).
		sounds =
			radio: CreateSound data.button, "au/panel_comms_radio.wav"
			static: CreateSound data.button, "au/panel_comms_static.wav"

		sounds.radio\PlayEx 0, 100

		sounds.static\PlayEx 0.25, 100

		-- Set up a hook to catch and clean sounds up.
		hook.Add "Think", "GMAU Comms Thinker", ->
			for _, sound in pairs sounds
				continue if not sound
				if sound\IsPlaying! and not IsValid base
					sound\Stop!

			if not IsValid base
				hook.Remove "Think", "GMAU Comms Thinker"

		with base
			\SetSabotage @
			\Setup with vgui.Create "DImage"
				if not @__theta
					validPositions = {}
					-- You know what? This is the definition of jank.
					-- I didn't want to implement proper weighted random.
					for i = -110, 110, 10
						if 10 < math.abs @GetPosition! - i
							table.insert validPositions, i

					@__theta = table.Random validPositions

				correct = false
				accumulator = 0
				submitted = false

				.Think = ->
					-- Determine whether we should increment/decrement the accumulator.
					changed = if correct and accumulator < 1.25
						accumulator = math.min 1.25, accumulator + FrameTime! * 0.5
						true

					elseif not correct and accumulator > 0
						accumulator = math.max 0, accumulator - FrameTime! * 0.5
						true

					-- If the accumulator value was changed earlier...
					if changed
						clamped = math.Clamp accumulator, 0, 1

						-- Modulate sounds.
						sounds.static\ChangeVolume 0.25 * (1 - clamped)
						sounds.radio\ChangeVolume 0.25 * clamped

						-- Submit.
						if accumulator == 1.25 and not submitted
							submitted = true
							base\Submit!

				max_size = ScrH! * 0.75
				\SetSize max_size, (max_size / 505) * 349
				\SetMaterial ASSETS.radio

				oscilWidth  = (max_size / 505) * 196
				oscilHeight = (max_size / 505) * 121

				leftOscilX = (max_size / 505) * 37
				rightOscilX = (max_size / 505) * 276
				oscilY = (max_size / 505) * 37

				headphonesWidth = (max_size / 505) * 577
				headphonesHeight = (max_size / 505) * 486

				headphonesOffsetX = (max_size / 505) * -72
				headphonesOffsetY = (max_size / 505) * -136

				-- Override Paint and draw headphones behind the panel.
				-- Hacky but gets the job done.
				oldPaint = .Paint
				.Paint = (w, h) =>
					old = DisableClipping true

					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial ASSETS.headphones
					surface.DrawTexturedRect headphonesOffsetX, headphonesOffsetY,
						headphonesWidth, headphonesHeight

					DisableClipping old

					oldPaint @, w, h

				-- Left oscillator.
				-- Fast sin.
				with \Add "Panel"
					\SetPos leftOscilX, oscilY
					\SetSize oscilWidth, oscilHeight
					.Paint = (_, w, h) ->
						surface.SetDrawColor 0, 255, 0

						local prev
						for i = 1, OSCIL_COUNT
							value = 0.5 + (math.sin CurTime! * 15 + i * 0.1) * 0.2
							if prev
								-- Multiply and flip the values.
								cy = h - h * value
								py = h - h * prev

								-- Flip the values again.
								cx = w - w * ((i - 1) / (OSCIL_COUNT - 1))
								px = w - w * ((i - 2) / (OSCIL_COUNT - 1))

								-- This will probably look horrible for 4K players.
								-- But oh well!
								surface.DrawLine cx, cy, px, py

							prev = value

				-- Right oscillator.
				-- Fast sin with noise.
				with \Add "Panel"
					\SetPos rightOscilX, oscilY
					\SetSize oscilWidth, oscilHeight
					.Paint = (_, w, h) ->
						surface.SetDrawColor 0, 255, 0

						local prev
						for i = 1, OSCIL_COUNT
							distortion = math.abs(@GetPosition! - @__theta) / 110

							value = 0.5 + (math.sin CurTime! * 15 + i * 0.1) * 0.2 +
								((math.random! * 2) - 1) * 0.1 * distortion +
								((math.random! * 2) - 1) * 0.01

							if prev
								-- Multiply and flip the values.
								cy = h - h * value
								py = h - h * prev

								cx = w * ((i - 1) / (OSCIL_COUNT - 1))
								px = w * ((i - 2) / (OSCIL_COUNT - 1))

								-- This will probably look horrible for 4K players.
								-- But oh well!
								surface.DrawLine cx, cy, px, py

							prev = value

				dialX = (max_size / 505) * 381
				dialY = (max_size / 505) * 252
				dialWidth = (max_size / 505) * 122
				dialHeight = (max_size / 505) * 137
				dialMax = math.max dialWidth, dialHeight

				dialOriginX = (max_size / 505) * 122 / 2
				dialOriginY = (max_size / 505) * 79

				-- Dial.
				with \Add "Button"
					\SetPos dialX - dialMax/2, dialY - dialMax/2
					\SetSize dialMax, dialMax
					\SetText ""
					.Paint = (_, w, h) ->
						-- If the player is holding the dial,
						-- point it towards the cursor.
						if \IsDown!
							cursorX, cursorY = \LocalCursorPos!

							@__theta = math.Clamp (math.NormalizeAngle -90 + math.deg(
								math.atan2 dialOriginY - cursorY, dialOriginX - cursorX
							)), -110, 110

							correct = 8 > math.abs @GetPosition! - @__theta

						-- Prepare the rotation matrix.
						ltsx, ltsy = _\LocalToScreen 0, 0
						v = Vector ltsx + dialOriginX, ltsy + dialOriginY

						with ROTATION_MATRIX
							\Identity!
							\Translate v
							\Rotate Angle 0, @__theta, 0
							\Translate -v

						surface.DisableClipping true
						cam.PushModelMatrix ROTATION_MATRIX, true

						surface.SetDrawColor 255, 255, 255

						-- Draw the dial.
						surface.SetMaterial ASSETS.dial
						surface.DrawTexturedRect 0, 0,
							dialWidth, dialHeight

						cam.PopModelMatrix!
						surface.DisableClipping false

				lightWidth = (max_size / 505) * 24
				lightHeight = (max_size / 505) * 24
				lightOffsetX = (max_size / 505) * 476
				lightOffsetY = (max_size / 505) * 166

				-- Right LED.
				-- Becomes greener the longer the dial is held at the correct position.
				with \Add "Panel"
					\SetSize lightWidth, lightHeight
					\SetPos lightOffsetX - lightWidth, lightOffsetY

					.Paint = (_, w, h) ->
						surface.SetDrawColor 0, 255 * math.min(accumulator, 1), 0
						surface.SetMaterial COMMONS.light
						surface.DrawTexturedRect 0, 0, w, h

					with \Add "DImage"
						\Dock FILL
						\SetMaterial COMMONS.lightshine

				-- LED.
				--
				with \Add "Panel"
					\SetSize lightWidth, lightHeight
					\SetPos lightOffsetX - lightWidth * 2 - lightWidth / 4, lightOffsetY

					.Paint = (_, w, h) ->
						surface.SetDrawColor (accumulator > 1) and COLOR_ACTIVE or COLOR_INACTIVE
						surface.SetMaterial COMMONS.light
						surface.DrawTexturedRect 0, 0, w, h

					with \Add "DImage"
						\Dock FILL
						\SetMaterial COMMONS.lightshine

			\Popup!

return comms
