TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Meeting Nickname", {
	font: "Roboto"
	size: ScreenScale 15
	weight: 550
}

surface.CreateFont "NMW AU Meeting Title", {
	font: "Roboto"
	size: ScreenScale 25
	weight: 550
}

surface.CreateFont "NMW AU Meeting Time", {
	font: "Roboto"
	size: ScreenScale 16
	weight: 550
}


MAT_EMERGENCY_LAYERS = {
	Material "au/gui/meeting/emergency/layer1.png"
	Material "au/gui/meeting/emergency/layer2.png"
	Material "au/gui/meeting/emergency/layer3.png"
	Material "au/gui/meeting/emergency/layer4.png"
	Material "au/gui/meeting/emergency/text.png"
}

MAT_BODY_LAYERS = {
	Material "au/gui/meeting/body/layer1.png"
	Material "au/gui/meeting/body/layer2.png"
	Material "au/gui/meeting/body/layer3.png"
	Material "au/gui/meeting/body/text.png"
}

MAT_DISCUSS = {
	bg: Material "au/gui/meeting/discuss/yes_bg.png", "smooth"
	border: Material "au/gui/meeting/discuss/yes_border.png", "smooth"
	yes_crewLeft: Material "au/gui/meeting/discuss/yes_crewleft.png", "smooth"
	yes_crewRight: Material "au/gui/meeting/discuss/yes_crewright.png", "smooth"
	text: Material "au/gui/meeting/discuss/yes_discuss.png", "smooth"
}

MAT_MEETING_TABLET = {
	shatter: Material "au/gui/meeting/shatter.png", "smooth"
	background: Material "au/gui/meeting/bg.png", "smooth"
	tablet: Material "au/gui/meeting/voting_screen.png", "smooth"
	skip: Material "au/gui/meeting/discuss/skip.png", "smooth"
	dead: Material "au/gui/meeting/kil.png", "smooth"
	voted: Material "au/gui/meeting/voted.png", "smooth"
	skipped: Material "au/gui/meeting/skipped.png", "smooth"
	megaphone: Material "au/gui/meeting/megaphone.png", "smooth"
}

COLOR_WHITE = Color 255, 255, 255
COLOR_BLACK = Color 0, 0, 0

meeting = {}

DISCUSS_SPLASH_TIME = 3

--- Creates the famous pre-vote popup.
-- I had fun coming up with this one.
meeting.PlayBackground = (callback) =>
	with bg = @Add "DPanel"
		\SetSize @GetWide!, @GetTall!
		\SetPos 0, 0

		.rot = 33
		\NewAnimation 0.1, 0, -1, ->
			.rot = -33
			\NewAnimation 0.1, 0, -1, ->
				.rot = 0
				if callback
					callback!
				\NewAnimation 3, 0, -1, ->
					.shrinkAnim = \NewAnimation 0.35, 0

		aspect = 435/948

		.Paint = (_, w, h) ->
			ltsx, ltsy = _\LocalToScreen 0, 0
			ltsv = Vector ltsx, ltsy, 0
			v = Vector w / 2, h / 2, 0

			m = Matrix!
			m\Translate ltsv
			m\Translate v
			m\Rotate Angle 0, .rot, 0
			if .rot ~= 0
				m\Scale Vector 1.5, 1.5, 1.5
			if .shrinkAnim
				m\Scale Vector 1, ((.shrinkAnim.EndTime - SysTime!) / (.shrinkAnim.EndTime - .shrinkAnim.StartTime)), 1

			m\Translate -v
			m\Translate -ltsv

			cam.PushModelMatrix m, true
			do
				surface.DisableClipping true
				surface.SetDrawColor 255, 255, 255
				surface.SetMaterial MAT_MEETING_TABLET.background
				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!
				surface.DisableClipping false
			cam.PopModelMatrix!

--- Removes all confirm popups.
-- Kind of redundant, honestly.
meeting.PurgeConfirms = =>
	for _, btn in pairs @buttons
		btn\SetEnabled true

		if IsValid btn.confirm
			btn.confirm\Remove!

		if IsValid btn.buttonOverlay
			btn.buttonOverlay\SetEnabled true

--- Disables all buttons. Duh.
meeting.DisableAllButtons = =>
	for _, btn in pairs @buttons
		if IsValid btn.buttonOverlay
			with btn.buttonOverlay
				\SetEnabled false
				\SetMouseInputEnabled false
				\AlphaTo 0, 0.05, 0

			if IsValid btn.confirm
				btn.confirm\Remove!

meeting.CanIVote = =>
	GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!] and not GAMEMODE.GameData.DeadPlayers[LocalPlayer!]

--- Creates a confirm popup.
-- @param height Height.
-- @param id Player ID.
meeting.CreateConfirm = (height, id) =>
	return with confirm = vgui.Create "DPanel"
		\SetAlpha 0
		\SetZPos 40
		\SetTall height
		.Paint = ->

		-- Yes
		with \Add "DImageButton"
			\SetText ""
			\SetWide height
			\Dock LEFT
			\SetImage "au/gui/meeting/confirm_yes.png"
			\SetStretchToFit true
			.DoClick = ->
				surface.PlaySound "au/votescreen_lockin.wav"
				@DisableAllButtons!
				GAMEMODE\Net_SendVote id

		-- No
		with \Add "DImageButton"
			\SetText ""
			\DockMargin height * 0.2, 0, 0, 0
			\SetWide height
			\Dock LEFT
			\SetImage "au/gui/meeting/confirm_no.png"
			\SetStretchToFit true
			.DoClick = -> @PurgeConfirms!

		-- Maybe?
		\NewAnimation 0, 0, 0, ->
			\InvalidateLayout!
			\NewAnimation 0, 0, 0, ->
				\SizeToChildren true
				\InvalidateLayout!
				\AlphaTo 255, 0.1, 0

COLOR_WHITE = Color 255, 255, 255

meeting.OpenDiscuss = (caller) =>
	with @discussWindow = @Add "DPanel"
		newWidth, newHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.tablet,
			@GetWide!, 0.95 * math.min @GetTall!, @GetWide!

		\SetSize newWidth, newHeight
		\SetPos @GetWide!/2 - newWidth/2, @GetTall!/2 - newHeight/2
		\SetAlpha 0
		\AlphaTo 255, 0.1, 0
		\SetMouseInputEnabled true
		gui.EnableScreenClicker true

		time = DISCUSS_SPLASH_TIME + GAMEMODE.ConVarSnapshots.VotePreTime\GetInt! + GAMEMODE.ConVarSnapshots.VoteTime\GetInt! + 0.5
		voteEndTime = SysTime! + time

		beginAnim = {
			StartTime: SysTime! + DISCUSS_SPLASH_TIME
			EndTime: SysTime! + DISCUSS_SPLASH_TIME + GAMEMODE.ConVarSnapshots.VotePreTime\GetInt!
		}

		.Image = MAT_MEETING_TABLET.tablet
		.Paint = GAMEMODE.Render.DermaFitImage
		if LocalPlayer!\IsDead!
			.PaintOver = (_, w, h) ->
				newWidth, newHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.shatter, w, h

				surface.SetMaterial MAT_MEETING_TABLET.shatter
				surface.SetDrawColor COLOR_WHITE

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect w/2 - newWidth/2, h/2 - newHeight/2, newWidth, newHeight
				render.PopFilterMag!
				render.PopFilterMin!

		@buttons = {}

		-- Create the inner panel using the raw pixel offsets.
		with innerPanel = @discussWindow\Add "DPanel"
			\SetSize (733/856) * newWidth, (506/590) * newHeight
			\SetPos newWidth * (37/856), newWidth * (37/856)
			.Paint = ->

			sw = innerPanel\GetWide! * 0.05
			sh = innerPanel\GetTall! * 0.2

			\DockPadding sw*0.5, 0, sw*0.5, 0

			-- Add the "Who is The Imposter?" header.
			with innerPanel\Add "DPanel"
				\Dock TOP
				\SetTall sh * 0.6
				.Paint = (_, w, h) ->
					draw.SimpleTextOutlined tostring(TRANSLATE("meeting.header")), "NMW AU Meeting Title",
						w/2, h/2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0)

			-- Add the footer.
			-- This one is a lot more complicated than the header.
			with innerLower = innerPanel\Add "DPanel"
				\Dock BOTTOM
				\SetTall sh * 0.6

				paintText = (w, h, text) ->
					draw.SimpleTextOutlined text, "NMW AU Meeting Time",
						w, h/2, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0)

				-- Draw the timer in the bottom right corner.
				.Paint = (_, w, h) ->
					begin = beginAnim.EndTime - SysTime!

					paintText w, h, if begin > 0
						TRANSLATE("meeting.timer.begins") math.max 0, math.floor beginAnim.EndTime - SysTime!
					elseif @proceeding
						TRANSLATE("meeting.timer.proceeding") math.max 0, math.floor @proceeding.EndTime - SysTime!
					else
						TRANSLATE("meeting.timer.ends") math.max 0, math.floor voteEndTime - SysTime!

				-- Prepare the post-vote are that we can add voter icons to.
				@skipArea = with skipArea = innerLower\Add "DPanel"
					\Dock FILL
					\SetAlpha 0
					.Paint = ->

					with \Add "DPanel"
						\SetWide sh * 0.6
						\Dock LEFT
						.Image = MAT_MEETING_TABLET.skipped
						.Paint = GAMEMODE.Render.DermaFitImage

					skipArea.output = with \Add "DPanel"
						\DockMargin sh * 0.05, sh * 0.125, 0, sh * 0.125
						\Dock FILL
						.Paint = ->

				-- Create the skip button, again, using the raw pixel offsets.
				@buttons[0] = with skipButton = innerLower\Add "DButton"
					aspect = 27/112
					skipWidth = newWidth * 0.125
					skipHeight = aspect * skipWidth
					\SetSize skipWidth, skipHeight
					\SetPos skipWidth * 0.1, (sh * 0.6)/2 - skipHeight/2

					\SetEnabled false
					\NewAnimation 0, DISCUSS_SPLASH_TIME + GAMEMODE.ConVarSnapshots.VotePreTime\GetInt!, 0, ->
						\SetEnabled true

					\SetText ""
					.Image = MAT_MEETING_TABLET.skip
					.Paint = GAMEMODE.Render.DermaFitImage
					.DoClick = (_) ->
						return unless \IsEnabled!

						@PurgeConfirms!

						surface.PlaySound "au/votescreen_avote.wav"
						\SetEnabled false

						skipButton.confirm = with @CreateConfirm sh * 0.6
							\SetParent innerLower
							\SetPos skipWidth * 0.2 + skipWidth, 0

					-- A workaround to make this button removable.
					skipButton.buttonOverlay = skipButton
					skipButton.output = @skipArea.output

			-- Create the scroll panel that's going to contain all necessary voting stuff.
			with scroll = innerPanel\Add "DScrollPanel"
				\Dock FILL
				.Paint = ->

				-- Since docking happens on the next tick, we need to skip a frame
				-- before retrieving the width of the scroll panel.
				--
				-- Yeah.
				-- At least this is better than timer.Simple 0.
				\NewAnimation 0, 0, 0, ->
					with list = scroll\Add "DIconLayout"
						\Dock( FILL )
						\SetSpaceY scroll\GetWide! * 0.0125
						\SetSpaceX scroll\GetTall! * 0.02

						-- Sort the list of current players.
						-- Imposters get the highest priority, and dead people get the lowest priority.
						table.sort GAMEMODE.GameData.PlayerTables, (a, b) ->
							alive = IsValid(a.entity) and not GAMEMODE.GameData.DeadPlayers[a]
							va = (alive and GAMEMODE.GameData.Imposters[a] and 1) or alive and 0.5 or 0

							alive = IsValid(b.entity) and not GAMEMODE.GameData.DeadPlayers[b]
							vb = (alive and GAMEMODE.GameData.Imposters[b] and 1) or alive and 0.5 or 0

							return va > vb

						-- Now, create a button per player.
						for _, ply in ipairs GAMEMODE.GameData.PlayerTables or {}
							alive = IsValid(ply.entity) and not GAMEMODE.GameData.DeadPlayers[ply]

							-- Since the base game has shadows behind the buttons, we'll need to
							-- make a container and paint two panels on it, each with a slight offset.
							--
							-- You might want to say that I could just disable clipping, but
							-- that would make the entire thing look extremely atrocious.
							-- I tried.
							with container = list\Add "DPanel"
								\SetSize scroll\GetWide! * 0.475, scroll\GetTall! * 0.165
								.Paint = ->

								innerItemSizeW, innerItemSizeH = container\GetSize!
								offset = innerItemSizeH * 0.075
								innerItemSizeW -= offset
								innerItemSizeH -= offset

								-- Shadow
								with \Add "DPanel"
									\SetPos offset, offset
									\SetSize innerItemSizeW, innerItemSizeH
									\SetZPos -10

									color = Color 0, 0, 0, 100
									.Paint = (_, w, h) ->
										draw.RoundedBox 16, 0, 0, w, h, color

								-- The player panel itself.
								@buttons[ply.id] = with playerItem = \Add "DPanel"
									\SetSize innerItemSizeW, innerItemSizeH

									.Paint = (_, w, h) ->
										draw.RoundedBox 16, 0, 0, w, h, Color 255, 255, 255

										-- Let's enter the cringe zone.
										-- This entire chunk of code is responsible for animating
										-- the megaphone akin to the base game.
										--
										-- We need to disable clipping there, but luckily not for too long.
										if ply == caller
											value = math.min 1, math.max 0, (beginAnim.StartTime + 1 - SysTime!)

											if value == 1
												return
											elseif value ~= 0
												surface.DisableClipping true

											mWidth, mHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.megaphone, w, h

											ltsx, ltsy = _\LocalToScreen 0, 0
											ltsv = Vector ltsx, ltsy, 0
											v = Vector w - mWidth - mWidth * 0.25 + mWidth/2, h / 2, 0

											m = Matrix!
											m\Translate ltsv
											m\Translate v

											if value ~= 1
												m\Rotate Angle 0, (math.sin(math.rad(CurTime! * 1200))) * 12 * value, 0
												m\Scale (1 + value) * Vector 1, 1, 1

											m\Translate -v
											m\Translate -ltsv

											cam.PushModelMatrix m, true
											surface.SetMaterial MAT_MEETING_TABLET.megaphone
											surface.SetDrawColor Color 255, 255, 255, 255 * 1/value
											surface.DrawTexturedRect w - mWidth - mWidth * 0.25, 0, mWidth, mHeight
											cam.PopModelMatrix!

											if value ~= 0
												surface.DisableClipping false

									-- Create the crewmate icon.
									with crew = playerItem\Add "DPanel"
										\SetSize playerItem\GetTall!, playerItem\GetTall!

										pad = playerItem\GetTall! * 0.05
										\DockPadding pad, pad, pad, pad
										\Dock LEFT
										.Paint = ->

										-- A slightly unreadable chunk of garbage code
										-- responsible for layering the crewmate sprite.
										layers = {}
										for i = 1, 2
											with layers[i] = crew\Add "AmongUsCrewmate"
												\SetSize crew\GetTall! * 0.8, crew\GetTall! * 0.8
												\SetPos crew\GetWide! / 2 - \GetWide! / 2, crew\GetTall! / 2 - \GetTall! / 2
												\SetColor ply.color

										-- Create the red cross overlay if the player is kil.
										if not alive then
											with crew\Add "DPanel"
												\Dock FILL

												.Paint = (_, w, h) ->
													value = math.min 1, math.max 0, (beginAnim.StartTime + 0.4 - SysTime!) / 0.4
													if value == 1
														return
													elseif value ~= 0
														surface.DisableClipping true

													surface.SetMaterial MAT_MEETING_TABLET.dead
													surface.SetDrawColor Color 255, 255, 255, math.floor 255 * 1 / value

													surface.DrawTexturedRect -w * value, -h * value, w + w * 2 * value, h + h * 2 * value

													if value ~= 0
														surface.DisableClipping false

										-- Create the "I Voted" badge and hide it.
										--
										-- Disables clipping and because of that ends up looking slightly off.
										-- But it's better than SetPos'ing the thing constantly.
										-- Or is it?
										playerItem.voted = with crew\Add "DPanel"
											\SetAlpha 0
											.Paint = (_) ->
												return if \GetAlpha! == 0

												w = crew\GetTall!

												surface.DisableClipping true
												surface.SetMaterial MAT_MEETING_TABLET.voted
												surface.SetDrawColor COLOR_WHITE
												surface.DrawTexturedRect -w/6, -w/6, w/2, w/2
												surface.DisableClipping false

									-- Create the nickname row.
									with playerItem\Add "DPanel"
										\SetTall playerItem\GetTall! / 2
										clr = if GAMEMODE.GameData.Imposters[ply]
											Color 255, 30, 0
										else
											Color 255, 255, 255

										\Dock TOP
										.Paint = (_, w, h) ->
											draw.SimpleTextOutlined ply.nickname or "N/A", "NMW AU Meeting Nickname",
												0, h/2, clr, nil, TEXT_ALIGN_CENTER, 2, COLOR_BLACK

									-- Prepare the output row which we're going to push votes into.
									playerItem.output = with lower = playerItem\Add "DPanel"
										\SetTall playerItem\GetTall! / 2
										\Dock BOTTOM
										.Paint = ->

									-- Shadow overlay. Much like in the base game.
									with shadowOverlay = playerItem\Add "DPanel"
										\SetSize playerItem\GetWide!, playerItem\GetTall!
										\SetAlpha 100
										if alive
											\AlphaTo 0, 0.25, DISCUSS_SPLASH_TIME + GAMEMODE.ConVarSnapshots.VotePreTime\GetInt!, ->
												\SetZPos 20

										\SetZPos 40
										.Paint = (_, w, h) ->
											draw.RoundedBox 16, 0, 0, w, h, Color 0, 0, 0, 255

									-- Finally, the brains of the thingy. The hidden button above them all.
									-- Yes, I could just disable mouse events for everything else,
									-- but then I would lose the ability to dock the confirm menu to this thing.
									--
									-- Sometimes sacrifices are necessary.
									if @CanIVote!
										playerItem.buttonOverlay = with playerItem\Add "DButton"
											\SetText ""
											\SetSize playerItem\GetWide!, playerItem\GetTall!

											padding = playerItem\GetTall! * 0.05
											\DockPadding padding, padding, padding, padding
											\SetEnabled false
											\SetZPos 30
											.Paint = ->

											if alive
												\NewAnimation 0, DISCUSS_SPLASH_TIME + GAMEMODE.ConVarSnapshots.VotePreTime\GetInt!, 0, ->
													\SetEnabled true

												.DoClick = ->
													-- duh
													return unless \IsEnabled!

													@PurgeConfirms!
													surface.PlaySound "au/votescreen_avote.wav"
													playerItem.buttonOverlay\SetEnabled false

													playerItem.confirm = with @CreateConfirm playerItem.buttonOverlay\GetTall! * 0.9, ply.id
														\SetParent playerItem.buttonOverlay
														\Dock RIGHT

	-- The two crewmates talking animation you see before the meeting screen appears.
	with discussAnim = @Add "DPanel"
		size = 0.8 * math.min @GetTall!, @GetWide!
		\SetSize size, size
		\SetPos @GetWide!/2 - size/2, @GetTall!/2 - size/2

		\SetZPos 30
		\SetAlpha 0
		\AlphaTo 255, 0.1, 0
		\AlphaTo 0, 0.1, 3, ->
			\Remove!

		.Paint = (_, w, h) ->
			if not _.circle
				_.circle = GAMEMODE.Render.CreateCircle w/2, w/2, w*0.49, 64

			surface.SetMaterial MAT_DISCUSS.bg
			surface.SetDrawColor Color 255, 255, 255
			surface.DrawTexturedRect 0, 0, w, h

			-- Let's enter the cringe area once again.
			-- This code is responsible for drawing the crewmates
			-- inside the background circle using stencils.
			--
			-- Thank god Garry's Mod has stencils.
			with render
				.PushFilterMag TEXFILTER.ANISOTROPIC
				.PushFilterMin TEXFILTER.ANISOTROPIC
				.ClearStencil!

				.SetStencilEnable true
				.SetStencilTestMask 0xFF
				.SetStencilWriteMask 0xFF
				.SetStencilReferenceValue 0x01

				.SetStencilCompareFunction STENCIL_NEVER
				.SetStencilFailOperation STENCIL_REPLACE
				.SetStencilZFailOperation STENCIL_REPLACE

				surface.DrawPoly _.circle

				.SetStencilCompareFunction STENCIL_LESSEQUAL
				.SetStencilFailOperation STENCIL_KEEP
				.SetStencilZFailOperation STENCIL_KEEP

				.PopFilterMag!
				.PopFilterMin!

				-- Let's enter the abyss.
				do
					ltsx, ltsy = _\LocalToScreen 0, 0
					ltsv = Vector ltsx, ltsy, 0
					v = Vector w/3, h / 1.5, 0

					m = Matrix!
					m\Translate ltsv
					m\Translate v
					m\Rotate Angle 0, (math.sin(math.rad(CurTime! * 1200))) * 2, 0
					m\Translate -v
					m\Translate -ltsv

					cam.PushModelMatrix m, true
					surface.SetMaterial MAT_DISCUSS.yes_crewLeft
					surface.DrawTexturedRect -w*0.15, h/2-h*0.125, w/2 + w*0.1, h/2+h*0.2
					cam.PopModelMatrix!

				-- Let's enter the abyss one more time.
				do
					ltsx, ltsy = _\LocalToScreen 0, 0
					ltsv = Vector ltsx, ltsy, 0
					v = Vector w/2 + w/4, h / 2 + h/3, 0

					m = Matrix!
					m\Translate ltsv
					m\Translate v
					m\Rotate Angle 0, (math.cos(math.rad(CurTime! * 1200))) * 2, 0
					m\Translate -v
					m\Translate -ltsv

					cam.PushModelMatrix m, true
					surface.SetMaterial MAT_DISCUSS.yes_crewRight
					surface.DrawTexturedRect w/2, h/2-h*0.05, w/2 + w*0.2, h/2+h*0.2
					cam.PopModelMatrix!

				.SetStencilEnable false

				surface.SetMaterial MAT_DISCUSS.border
				surface.DrawTexturedRect 0, 0, w, h

	-- And finally, something simple.
	-- The "Discuss!" text.
	with discussText = @Add "DPanel"
		size = 0.8 * math.min @GetTall!, @GetWide!
		\SetSize size, size * 0.3
		\SetPos @GetWide!/2 - size/2, -size * 0.2
		\SetZPos 31
		\MoveTo @GetWide!/2 - size/2, @GetTall! * 0.15, 0.3, 0
		\SetAlpha 0
		\AlphaTo 255, 0.3, 0
		\AlphaTo 0, 0.1, 3, ->
			\Remove!

		.Image = MAT_DISCUSS.text
		.Paint = GAMEMODE.Render.DermaFitImage

--- Apply the player vote, and make his "I Voted" badge pop up.
-- @param playerTable The player table.
meeting.ApplyVote = (playerTable) =>
	if btn = @buttons[playerTable.id]
		if playerTable.entity ~= LocalPlayer!
			surface.PlaySound "au/notification.wav"

		btn.voted\AlphaTo 255, 0.1

--- Ends the vote.
-- @param results The table of results.
meeting.End = (results = {}) =>
	@proceeding = {
		StartTime: SysTime!
		EndTime: SysTime! + GAMEMODE.ConVarSnapshots.VotePostTime\GetInt!
	}

	@DisableAllButtons!

	@skipArea\AlphaTo 255, 0.25, 0, ->
		for _, result in pairs results
			outputPanel = @buttons[result.targetid].output

			continue unless outputPanel

			-- Display a mini-crewmate icon for each player that voted against this person.
			for i, voter in ipairs result.votes
				with outputPanel\Add "DPanel"
					\SetWide outputPanel\GetTall!
					\Dock LEFT
					\SetAlpha 0
					\AlphaTo 255, 0.1, i * 0.5 - .35

					layers = {}
					for i = 1, 2
						with layers[i] = \Add "AmongUsCrewmate"
							\SetSize outputPanel\GetTall! * 0.8, outputPanel\GetTall! * 0.8
							\SetPos outputPanel\GetTall! * 0.1, outputPanel\GetTall! * 0.1
							\SetFlipX true

							playerTable = GAMEMODE.GameData.Lookup_PlayerByID[voter]
							if playerTable
								\SetColor playerTable.color

					.Paint = ->

--- Starts the emergency.
-- @param playerTable The player who called the vote.
-- @param bodyColor In case this is a body report, the color of the body. Optional.
meeting.StartEmergency = (playerTable, bodyColor) =>
	if bodyColor
		surface.PlaySound "au/report_body.wav"
	else
		surface.PlaySound "au/alarm_emergencymeeting.wav"

	@PlayBackground ->
		with emergency_caller = @Add "DPanel"
			size = 0.7 * math.min @GetTall!, @GetWide!

			\SetSize size, size
			\SetPos @GetWide!/2 - size/2, @GetTall!/2 - size/2
			\AlphaTo 0, 0.1, 3, ->
				\Remove!
			.Paint = ->

			with upper = emergency_caller\Add "DPanel"
				\SetTall size/2
				\Dock TOP
				.Paint = ->

				\NewAnimation 0, 0, -1, ->
					layers = {}
					pics = if bodyColor
						MAT_BODY_LAYERS
					else
						MAT_EMERGENCY_LAYERS

					for i = #pics - 2, 1, -1
						with layers[i] = upper\Add "DPanel"
							\SetSize size / 2, size / 2
							\CenterHorizontal!
							\SetZPos (#pics + 1) - i
							.Image = pics[i]
							.Paint = GAMEMODE.Render.DermaFitImage

					if bodyColor
						layers[3].Color = bodyColor
					else
						layers[2].Color = playerTable.color
						layers[4].Color = playerTable.color

			with lower = emergency_caller\Add "DPanel"
				\SetTall size/2
				\Dock BOTTOM
				.Image = if bodyColor
					MAT_BODY_LAYERS[4]
				else
					MAT_EMERGENCY_LAYERS[5]

				.Paint = GAMEMODE.Render.DermaFitImage

-- zzz stuff
meeting.Init = =>
	@SetSize ScrW!, ScrH!

meeting.Close = => with @
	@AlphaTo 0, 0.25, 0, ->
		@Remove!

meeting.OnRemove = =>
	gui.EnableScreenClicker false

meeting.Paint = =>

return vgui.RegisterTable meeting, "DPanel"
