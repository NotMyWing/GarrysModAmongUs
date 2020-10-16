surface.CreateFont "NMW AU Role", {
	font: "Arial"
	size: ScreenScale 80
	weight: 500
}

surface.CreateFont "NMW AU Role Subtext", {
	font: "Arial"
	size: ScreenScale 20
	weight: 500
}

surface.CreateFont "NMW AU Splash Nickname", {
	font: "Arial"
	size: ScreenScale 12
	weight: 500
}

splash = {}

ASSETS = {
	no_bg: Material "au/gui/no/no_bg.png", "smooth"
	no_crew: Material "au/gui/no/no_crew.png", "smooth"
	no_hand: Material "au/gui/no/no_hand.png", "smooth"
	no_shh: Material "au/gui/no/no_shh.png", "smooth"
	circle: Material "au/gui/circle2.png", "smooth"
}

SHUT_TIME = 3

--- Displays the crewmate shhing at you.
splash.DisplayShush = =>
	@SetAlpha 0
	@AlphaTo 255, 0.25

	-- The spinning background, yo.
	with background = @Add "DPanel"
		size = math.min ScrW!, ScrH! * 0.8
		\SetSize size, size
		\SetPos (ScrW! / 2) - (size / 2), (ScrH! / 2) - (size / 2)
		\AlphaTo 0, 0.5, 2.5, ->
			@DisplayPlayers false
			\Remove!

		.Paint = (_, w, h) ->
			ltsx, ltsy = _\LocalToScreen 0, 0
			ltsv = Vector ltsx, ltsy, 0
			v = Vector w / 2, h / 2, 0

			-- I want to die.
			m = Matrix!
			m\Translate ltsv
			m\Translate v
			m\Rotate Angle 0, (CurTime! * 6) % 360, 0
			m\Translate -v
			m\Translate -ltsv

			cam.PushModelMatrix m, true
			do
				surface.SetDrawColor 255, 255, 255
				surface.SetMaterial ASSETS.no_bg
				surface.DrawTexturedRect 0, 0, w, h
			cam.PopModelMatrix!

		-- The crewmate sprite.
		with \Add "DPanel"
			bg_size = background\GetTall!
			crew_size = bg_size * 0.735

			\SetSize crew_size, crew_size
			\SetPos (bg_size / 2) - (crew_size / 2), (bg_size / 2) - (crew_size / 2)

			.Paint = (_, w, h) ->
				surface.SetDrawColor 255, 255, 255
				surface.SetMaterial ASSETS.no_crew

				shrink = w * 0.02

				time = (CurTime! - @__createTime) / SHUT_TIME

				if (time >= 0.3 and time <= 0.35)
					surface.DrawTexturedRect 0, 0, w, h
				else
					surface.DrawTexturedRect shrink, shrink, w - shrink * 2, h - shrink * 2

		-- The hand sprite.
		with \Add "DPanel"
			bg_size = background\GetTall!
			hand_size = bg_size * 0.45

			newWidth, newHeight = GAMEMODE.Render.FitMaterial ASSETS.no_hand, hand_size, hand_size

			\SetSize newWidth, newHeight
			\SetPos bg_size * 0.8, bg_size * 0.65

			\SetAlpha 0
			\AlphaTo 255, 0.5, 0

			finalPos = Vector (bg_size / 2) - (newWidth / 2),
				bg_size * 0.1 + (bg_size / 2) - (newHeight / 2)
			\MoveTo finalPos.x, finalPos.y, 0.5

			.Paint = (_, w, h) ->
				ltsx, ltsy = _\LocalToScreen 0, 0
				ltsv = Vector ltsx, ltsy, 0
				v = Vector w / 2, h / 2, 0
				th = 1 - (math.min 1, (CurTime! - @__createTime) / 0.5)

				m = Matrix!
				m\Translate ltsv
				m\Translate v
				m\Rotate Angle 0, 0 + th * 45, 0
				m\Translate -v
				m\Translate -ltsv

				cam.PushModelMatrix m, true
				do
					surface.DisableClipping true
					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial ASSETS.no_hand
					surface.DrawTexturedRect 0, 0, w, h
					surface.DisableClipping false
				cam.PopModelMatrix!

		-- The "SHHHHHH" text.
		with \Add "DPanel"
			bg_size = background\GetTall!
			shh_size = bg_size * 0.7

			newWidth, newHeight = GAMEMODE.Render.FitMaterial ASSETS.no_shh, shh_size, shh_size

			\SetSize newWidth, newHeight
			\SetPos (bg_size / 2) - (newWidth / 2), bg_size * 0.94 - (newHeight / 2)

			.Paint = (_, w, h) ->
				time = (CurTime! - @__createTime) / SHUT_TIME

				if time >= 0.3
					surface.DisableClipping true
					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial ASSETS.no_shh
					surface.DrawTexturedRect 0, 0, w, h
					surface.DisableClipping false

splash.DisplayPlayers = (reason) =>
	localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]

	displayTime = if reason
		8
	else
		(GAMEMODE.SplashScreenTime - SHUT_TIME)

	@AlphaTo 0, 0.25, displayTime, ->
		@Remove!

	with @crewmate_screen = vgui.Create "DPanel", @
		\SetSize @GetWide!, @GetTall!
		\SetAlpha 0
		.Paint = ->
		\AlphaTo 255, 0.25, 0, ->
			-- Are we an imposter, son?
			imposter = GAMEMODE.GameData.Imposters[localPlayerTable]

			-- Are we winning, son?
			victory = if reason
				(reason == GAMEMODE.GameOverReason.Imposter and imposter) or
					(reason == GAMEMODE.GameOverReason.Crewmate and not imposter)

			-- Are we coloring, son?
			theme_color = (imposter or reason == GAMEMODE.GameOverReason.Imposter) and (Color 255, 20, 0) or (Color 130, 250, 250)

			-- Play a contextual sound depending on why we're showing the screen.
			surface.PlaySound if reason
				if reason == GAMEMODE.GameOverReason.Imposter
					"au/victory_imposter.wav"
				elseif reason == GAMEMODE.GameOverReason.Crewmate
					"au/victory_crew.wav"
			else
				"au/start.wav"

			with @Add "DLabel"
				\SetSize @GetWide!, @GetTall! * 0.3
				\SetPos 0, @GetTall! * 0.05

				\SetContentAlignment 5
				\SetFont "NMW AU Role"
				\SetColor theme_color
				\SetText if reason
					victory and "Victory" or "Defeat"
				else
					localPlayerTable and (imposter and "Imposter" or "Crewmate") or "Spectator"

				\SetAlpha 0
				\AlphaTo 255, displayTime / 1.5

				\MoveTo 0, @GetTall! * 0.1, displayTime * 0.75

			-- Create the "N imposers among us" text if necessary.
			if not reason and not imposter
				amongSubtext = localPlayerTable and "us" or "them"

				text = if GAMEMODE.ImposterCount == 1
					"There is %s Imposter among " .. amongSubtext
				else
					"There are %s Imposters among " .. amongSubtext

				with \Add "DLabel"
					\SetSize @GetWide!, @GetTall! * 0.3
					\SetPos 0, @GetTall! * 0.2

					\SetContentAlignment 5
					\SetColor Color 255, 255, 255
					\SetText string.format text, GAMEMODE.ImposterCount
					\SetFont "NMW AU Role Subtext"

					\SetAlpha 0
					\AlphaTo 255, displayTime / 1.5, 0.5

					\MoveTo 0, @GetTall! * 0.225, displayTime * 0.6, 0.5

			-- This is dumb, but whatever.
			-- I'm basically using this as a timer.
			placeholder = with \Add "DPanel"
				\SetAlpha 0
				\AlphaTo 255, displayTime / 4, 0.5
				.Paint = ->

			-- Create a bar to contain all players.
			with playerBar = \Add "DPanel"
				size = (math.min @GetTall!, @GetWide!) * 0.4
				\SetSize @GetWide!, size
				\SetPos 0, @GetTall! * 0.15 + @GetTall!/2 - \GetTall!/2

				-- This atrocious thing paints the blurry background behind players.
				.Paint = (_, w, h) ->
					surface.DisableClipping true
					surface.SetDrawColor Color theme_color.r, theme_color.g, theme_color.b, 64
					surface.SetMaterial ASSETS.circle

					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC

					stretch = (w * 1.15) * (placeholder\GetAlpha! / 255)
					surface.DrawTexturedRect w/2 - stretch/2, 0, stretch, h
					render.PopFilterMag!
					render.PopFilterMin!

					surface.DisableClipping false

				mdl_size = size * 0.5

				-- Helper function that creates player model containers.
				create_mdl = (parent, color) ->
					return with mdl = parent\Add "DModelPanel"
						size = (math.min @GetTall!, @GetWide!) * 0.6
						\SetSize mdl_size, size
						\SetModel LocalPlayer!\GetModel!
						\SetFOV 32
						\SetCamPos \GetCamPos! - Vector 0, 0, 5
						if color
							\SetColor color
						with \GetEntity!
							\SetAngles Angle 0, 45, 0
							\SetPos \GetPos! + Vector 0, 0, 10
						.Think = ->
							\SetAlpha @GetAlpha!
						.LayoutEntity = ->

						oldPaint = .Paint
						.Paint = (_, w, h) ->
							oldPaint _, w, h

							draw.SimpleTextOutlined .Nickname or "", "NMW AU Splash Nickname",
								w/2, h/2 + w * 0.875, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color 0, 0, 0

				-- Now, add players to the table.
				-- In case it's a start splash screen, display our team
				-- In case it's a game over screen, display the winning team
				players = {}
				for _, playerTable in ipairs GAMEMODE.GameData.PlayerTables
					if playerTable.entity ~= LocalPlayer!
						-- Game Over
						if reason
							if reason == GAMEMODE.GameOverReason.Imposter and GAMEMODE.GameData.Imposters[playerTable]
								table.insert players, playerTable
							elseif reason == GAMEMODE.GameOverReason.Crewmate and not GAMEMODE.GameData.Imposters[playerTable]
								table.insert players, playerTable
						-- Game Start
						else
							if imposter and GAMEMODE.GameData.Imposters[playerTable]
								table.insert players, playerTable
							elseif not imposter
								table.insert players, playerTable

				barWidth = if localPlayerTable and (not reason or (reason and victory))
					\GetWide!/2 - mdl_size/2
				else
					\GetWide!/2

				-- Left side of the screen. Contains the first half of players.
				with leftBar = \Add "DPanel"
					\SetWide barWidth
					\Dock LEFT
					.Paint = ->

					width_mod = 1
					for i = 1, math.ceil #players / 2
						with create_mdl leftBar
							.Nickname = players[i].nickname
							dead = GAMEMODE.GameData.DeadPlayers[players[i]]
							\SetColor Color 0, 0, 0, dead and 127 or 255
							color = players[i].color
							if dead
								color.a = 127

							\ColorTo color, displayTime / 4, 0.5
							\Dock RIGHT
							\SetWide \GetWide! * width_mod
							\GetEntity!\SetAngles Angle 0, 45 + 15 * (1 - width_mod * 0.6), 0
							.Think = ->
								\SetAlpha @GetAlpha!

						width_mod *= 0.7

				-- Right side of the screen. Contains the other half of players.
				with rightBar = \Add "DPanel"
					\SetWide barWidth
					\Dock RIGHT
					.Paint = ->

					if #players ~= 1
						width_mod = 1
						for i = 1 + (math.ceil #players / 2), #players
							with create_mdl rightBar
								.Nickname = players[i].nickname
								dead = GAMEMODE.GameData.DeadPlayers[players[i]]
								\SetColor Color 0, 0, 0, dead and 127 or 255
								color = players[i].color
								if dead
									color.a = 127

								\ColorTo color, displayTime / 4, 0.5
								\Dock LEFT
								\SetWide \GetWide! * width_mod
								\GetEntity!\SetAngles Angle 0, 45 - 15 * (1 - width_mod * 0.6), 0
								.Think = ->
									\SetAlpha @GetAlpha!

							width_mod *= 0.7

				-- Now, if we're relevant, put us in the midle.
				if localPlayerTable and (not reason or (reason and victory))
					with middlePlayer = playerBar\Add "DPanel"
						\Dock FILL
						.Paint = ->
						color = localPlayerTable.color
						if GAMEMODE.GameData.DeadPlayers[localPlayerTable]
							color.a = 127

						with create_mdl middlePlayer, color
							.Nickname = localPlayerTable.nickname
							\Dock FILL
							\SetFOV 30

splash.DisplayGameOver = (reason) =>
	@SetAlpha 0
	@AlphaTo 255, 0.25
	@DisplayPlayers reason

splash.Init = =>
	@__createTime = CurTime!
	@SetPos 0, 0
	@SetSize ScrW!, ScrH!
	@SetZPos 32767

splash.Paint = (w, h) =>
	surface.SetDrawColor 0, 0, 0, 255
	surface.DrawRect 0, 0, w, h

return vgui.RegisterTable splash, "DPanel"