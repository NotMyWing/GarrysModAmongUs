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

splash = {}

NO_BG = Material "au/gui/no/no_bg.png", "noclamp smooth"
NO_CREW = Material "au/gui/no/no_crew.png", "noclamp smooth"
NO_HAND = Material "au/gui/no/no_hand.png", "noclamp smooth"
NO_SHH = Material "au/gui/no/no_shh.png", "noclamp smooth"
CIRCLE = Material "au/gui/circle2.png", "noclamp smooth"

shutTime = 3

drawTexturedRectRotatedPoint = ( x, y, w, h, rot, x0, y0 ) =>
	c = math.cos( math.rad( rot ) )
	s = math.sin( math.rad( rot ) )
	
	newx = y0 * s - x0 * c
	newy = y0 * c + x0 * s
	
	surface.DrawTexturedRectRotated x + newx, y + newy, w, h, rot

splash.DisplayShush = =>
	@SetAlpha 0
	@AlphaTo 255, 0.25

	with @no = vgui.Create "DPanel", @
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
				surface.SetMaterial NO_BG
				surface.DrawTexturedRect 0, 0, w, h
			cam.PopModelMatrix!

	with @no_crew = vgui.Create "DPanel", @no
		bg_size = @no\GetTall!
		crew_size = bg_size * 0.735 

		aspect = 345 / 372

		\SetSize crew_size * aspect, crew_size
		\SetPos (bg_size / 2) - (crew_size * aspect / 2), (bg_size / 2) - (crew_size / 2)

		.Paint = (_, w, h) ->
			surface.SetDrawColor 255, 255, 255
			surface.SetMaterial NO_CREW

			shrink = w * 0.02

			time = (CurTime! - @__createTime) / shutTime

			if (time >= 0.3 and time <= 0.35)
				surface.DrawTexturedRect 0, 0, w, h
			else
				surface.DrawTexturedRect shrink, shrink, w - shrink * 2, h - shrink * 2

	with @no_hand = vgui.Create "DPanel", @no
		bg_size = @no\GetTall!
		hand_size = bg_size * 0.45

		texture = NO_HAND\GetTexture("$basetexture")
		aspect = 130 / 237

		\SetSize hand_size * aspect, hand_size
		
		finalPos = Vector (bg_size / 2) - (hand_size * aspect / 2), bg_size * 0.1 + (bg_size / 2) - (hand_size / 2)
		\SetPos bg_size * 0.8, bg_size * 0.65
		\SetAlpha 0
		\AlphaTo 255, 0.5, 0
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
				surface.SetMaterial NO_HAND
				surface.DrawTexturedRect 0, 0, w, h
				surface.DisableClipping false
			cam.PopModelMatrix!

	with @no_shh = vgui.Create "DPanel", @no
		bg_size = @no\GetTall!
		shh_size = bg_size * 0.7

		aspect = 103 / 394

		\SetSize shh_size, shh_size * aspect
		\SetPos (bg_size / 2) - (shh_size / 2), bg_size * 0.94 - (shh_size * aspect / 2)

		.Paint = (_, w, h) ->
			time = (CurTime! - @__createTime) / shutTime

			if time >= 0.3
				surface.DisableClipping true
				surface.SetDrawColor 255, 255, 255
				surface.SetMaterial NO_SHH
				surface.DrawTexturedRect 0, 0, w, h
				surface.DisableClipping false

splash.DisplayPlayers = (reason) =>
	localPlayerTable = GAMEMODE.ActivePlayersMap[LocalPlayer!]

	time = if reason
		8
	else
		(GAMEMODE.SplashScreenTime - shutTime)

	@AlphaTo 0, 0.25, time, ->
		@Remove!

	with @crewmate_screen = vgui.Create "DPanel", @
		\SetSize @GetWide!, @GetTall!
		\SetAlpha 0
		.Paint = ->
		\AlphaTo 255, 0.25, 0, ->
			imposter = GAMEMODE.Imposters[localPlayerTable]
			victory = if reason
				(reason == GAMEMODE.GameOverReason.Imposter and imposter) or
					(reason == GAMEMODE.GameOverReason.Crewmate and not imposter)
			theme_color = (imposter or reason == GAMEMODE.GameOverReason.Imposter) and (Color 255, 20, 0) or (Color 130, 250, 250)

			if reason
				if reason == GAMEMODE.GameOverReason.Imposter
					surface.PlaySound "au/victory_imposter.wav"
				elseif reason == GAMEMODE.GameOverReason.Crewmate
					surface.PlaySound "au/victory_crew.wav"
			else
				surface.PlaySound "au/start.wav"

			with @role_label = vgui.Create "DLabel", @
				\SetSize @GetWide!, @GetTall! * 0.3
				\SetPos 0, @GetTall! * 0.05
				if not reason
					\SetText localPlayerTable and (imposter and "Imposter" or "Crewmate") or "Spectator"
				else
					\SetText victory and "Victory" or "Defeat"
				\SetFont "NMW AU Role"
				\SetColor theme_color
				\MoveTo 0, @GetTall! * 0.1, time * 0.75
				\SetAlpha 0
				\AlphaTo 255, time / 1.5
				\SetContentAlignment 5

			amongSubtext = localPlayerTable and "us" or "them"

			text = if GAMEMODE.ImposterCount == 1
				"There is %s Imposter among " .. amongSubtext
			else
				"There are %s Imposters among " .. amongSubtext

			if not reason and not imposter
				with @role_subtext = vgui.Create "DLabel", @crewmate_screen
					\SetSize @GetWide!, @GetTall! * 0.3
					\SetPos 0, @GetTall! * 0.2
					\SetText string.format text, GAMEMODE.ImposterCount
					\SetFont "NMW AU Role Subtext"
					\SetColor Color 255, 255, 255
					\MoveTo 0, @GetTall! * 0.225, time * 0.6, 0.5
					\SetAlpha 0
					\AlphaTo 255, time / 1.5, 0.5
					\SetContentAlignment 5

			with @placeholder = vgui.Create "DPanel", @crewmate_screen
				\SetAlpha 0
				\AlphaTo 255, time / 4, 0.5
				.Paint = ->

			with @player_bar = vgui.Create "DPanel", @crewmate_screen
				size = (math.min @GetTall!, @GetWide!) * 0.4
				\SetSize @GetWide!, size
				\SetPos 0, @GetTall! * 0.15 + @GetTall!/2 - \GetTall!/2

				.Paint = (_, w, h) ->
					surface.DisableClipping true
					surface.SetDrawColor Color theme_color.r, theme_color.g, theme_color.b, 127

					surface.SetMaterial CIRCLE
					stretch = (w * 1.15) * (@placeholder\GetAlpha! / 255)
					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC
					surface.DrawTexturedRect w/2 - stretch/2, 0, stretch, h
					render.PopFilterMag!
					render.PopFilterMin!
					surface.DisableClipping false
				
				mdl_size = size * 0.5
				create_mdl = (parent, color) ->
					return with mdlPanel = vgui.Create "DModelPanel", parent
						size = (math.min @GetTall!, @GetWide!) * 0.6
						\SetSize mdl_size, size
						\SetModel LocalPlayer!\GetModel!
						\SetFOV 35
						\SetCamPos \GetCamPos! - Vector 0, 0, 5
						if color
							\SetColor color
						with \GetEntity!
							\SetAngles Angle 0, 45, 0
							\SetPos \GetPos! + Vector 0, 0, 10
						.Think = ->
							\SetAlpha @GetAlpha!
						.LayoutEntity = ->

				players = {}
				for _, playerTable in ipairs GAMEMODE.ActivePlayers
					if playerTable.entity ~= LocalPlayer!
						if reason
							if reason == GAMEMODE.GameOverReason.Imposter and GAMEMODE.Imposters[playerTable]
								table.insert players, playerTable
							elseif reason == GAMEMODE.GameOverReason.Crewmate and not GAMEMODE.Imposters[playerTable]
								table.insert players, playerTable
						else
							if imposter and GAMEMODE.Imposters[playerTable]
								table.insert players, playerTable
							elseif not imposter
								table.insert players, playerTable

				with @left_bar = vgui.Create "DPanel", @player_bar
					\SetWide if localPlayerTable and (not reason or (reason and victory))
						@player_bar\GetWide!/2 - mdl_size/2
					else
						@player_bar\GetWide!/2
					\Dock LEFT
					.Paint = ->

					width_mod = 1
					for i = 1, math.ceil #players / 2
						with create_mdl @left_bar
							dead = GAMEMODE.DeadPlayers[players[i]]
							\SetColor Color 0, 0, 0, dead and 127 or 255
							color = players[i].color
							if dead
								color.a = 127

							\ColorTo color, time / 4, 0.5
							\Dock RIGHT
							\SetWide \GetWide! * width_mod
							\GetEntity!\SetAngles Angle 0, 45 + 15, 0
							.Think = ->
								\SetAlpha @GetAlpha!

						width_mod *= 0.75

				with @right_bar = vgui.Create "DPanel", @player_bar
					\SetWide if localPlayerTable and (not reason or (reason and victory))
						@player_bar\GetWide!/2 - mdl_size/2
					else
						@player_bar\GetWide!/2
					\Dock RIGHT
					.Paint = ->
					if #players ~= 1
						width_mod = 1
						for i = 1 + (math.ceil #players / 2), #players
							with create_mdl @right_bar
								dead = GAMEMODE.DeadPlayers[players[i]]
								\SetColor Color 0, 0, 0, dead and 127 or 255
								color = players[i].color
								if dead
									color.a = 127

								\ColorTo color, time / 4, 0.5
								\Dock LEFT
								\SetWide \GetWide! * width_mod
								\GetEntity!\SetAngles Angle 0, 45 - 15, 0
								.Think = ->
									\SetAlpha @GetAlpha!

							width_mod *= 0.75

				if localPlayerTable and not reason or (reason and victory)
					with @middle_player = vgui.Create "DPanel", @player_bar
						\Dock FILL
						.Paint = ->
						color = localPlayerTable.color
						if GAMEMODE.DeadPlayers[localPlayerTable]
							color.a = 127

						with create_mdl @middle_player, color
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