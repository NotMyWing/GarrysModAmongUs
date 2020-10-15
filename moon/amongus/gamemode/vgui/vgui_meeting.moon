surface.CreateFont "NMW AU Meeting Nickname", {
	font: "Arial"
	size: ScreenScale 15
	weight: 500
}

surface.CreateFont "NMW AU Meeting Title", {
	font: "Arial"
	size: ScreenScale 25
	weight: 500
}

surface.CreateFont "NMW AU Meeting Time", {
	font: "Arial"
	size: ScreenScale 16
	weight: 500
}

meeting = {}

meeting.Init = =>
	@SetSize ScrW!, ScrH!

meeting.Paint = =>

VGUI_BG = Material "au/gui/meeting/bg.png"

discuss_splash_time = 3
post_vote_time = 5

meeting.PlayBackground = (callback) =>
	with bg = vgui.Create "DPanel", @
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
				surface.SetMaterial VGUI_BG
				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!
				surface.DisableClipping false
			cam.PopModelMatrix!

VGUI_EMERGENCY_LAYERS = {
	Material "au/gui/meeting/emergency/layer1.png"
	Material "au/gui/meeting/emergency/layer2.png"
	Material "au/gui/meeting/emergency/layer3.png"
	Material "au/gui/meeting/emergency/layer4.png"
	Material "au/gui/meeting/emergency/text.png"
}

VGUI_BODY_LAYERS = {
	Material "au/gui/meeting/body/layer1.png"
	Material "au/gui/meeting/body/layer2.png"
	Material "au/gui/meeting/body/layer3.png"
	Material "au/gui/meeting/body/layer4.png"
	Material "au/gui/meeting/body/text.png"
}

DISCUSS = {
	bg: Material "au/gui/meeting/discuss/yes_bg.png", "smooth"
	border: Material "au/gui/meeting/discuss/yes_border.png", "smooth"
	yes_crewLeft: Material "au/gui/meeting/discuss/yes_crewLeft.png", "smooth"
	yes_crewRight: Material "au/gui/meeting/discuss/yes_crewRight.png", "smooth"
	text: Material "au/gui/meeting/discuss/yes_discuss.png", "smooth"

	tablet: Material "au/gui/meeting/voting_screen.png", "smooth"
	skip: Material "au/gui/meeting/discuss/skip.png", "smooth"
	dead: Material "au/gui/meeting/kil.png", "smooth"
	voted: Material "au/gui/meeting/voted.png", "smooth"
	skipped: Material "au/gui/meeting/skipped.png", "smooth"
	megaphone: Material "au/gui/meeting/megaphone.png", "smooth"
}

circle = ( x, y, radius, seg ) ->
	cir = {}

	table.insert( cir, { :x, :y, u: 0.5, u: 0.5 } )
	for i = 0, seg
		a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x: x + math.sin( a ) * radius, y: y + math.cos( a ) * radius, u: math.sin( a ) / 2 + 0.5, v: math.cos( a ) / 2 + 0.5 } )

	a = math.rad( 0 ) -- This is needed for non absolute segment counts
	table.insert( cir, { x: x + math.sin( a ) * radius, y: y + math.cos( a ) * radius, u: math.sin( a ) / 2 + 0.5, v: math.cos( a ) / 2 + 0.5 } )

	return cir

CREW_LAYERS = {
	Material "au/gui/meeting/crewmate1.png", "smooth"
	Material "au/gui/meeting/crewmate2.png", "smooth"
}

CREW_MINI_LAYERS = {
	Material "au/gui/meeting/crewmate_mini1.png", "smooth"
	Material "au/gui/meeting/crewmate_mini2.png", "smooth"
}

meeting.PurgeConfirms = =>
	for _, btn in ipairs @buttons
		if IsValid btn.confirm
			btn.confirm\Remove!
		
		if IsValid btn.buttonOverlay
			btn.buttonOverlay\SetEnabled true

meeting.DisableAllButtons = =>
	for _, btn in ipairs @buttons
		if IsValid btn.confirm
			btn.confirm\Remove!

		if IsValid btn.buttonOverlay
			btn.buttonOverlay\Remove!

meeting.CanIVote = =>
	@GameData.ActivePlayersMap[LocalPlayer!] and not @GameData.DeadPlayers[LocalPlayer!]

meeting.OpenDiscuss = (caller) =>
	with @discussWindow = vgui.Create "DPanel", @
		time = discuss_splash_time + GAMEMODE.ConVars.VotePreTime\GetInt! + GAMEMODE.ConVars.VoteTime\GetInt! + 0.5
		
		endAnim = {
			StartTime: SysTime!
			EndTime: SysTime! + time
		}

		beginAnim = {
			StartTime: SysTime! + discuss_splash_time
			EndTime: SysTime! + discuss_splash_time + GAMEMODE.ConVars.VotePreTime\GetInt!
		}

		size = 0.95 * math.min @GetTall!, @GetWide!

		h = size
		w = @GetWide!

		texture = DISCUSS.tablet\GetTexture "$basetexture"
		width = texture\GetMappingWidth!
		height = texture\GetMappingHeight!
		vs = w / width
		hs = h / height
		scale = math.min vs, hs
		newWidth = scale * width
		newHeight = scale * height
	
		\SetSize newWidth, newHeight
		\SetPos @GetWide!/2 - newWidth/2, @GetTall!/2 - newHeight/2

		.Image = DISCUSS.tablet
		.Paint = GAMEMODE.Render.DermaFitImage
		\SetAlpha 0
		\AlphaTo 255, 0.1, 0

		buttons = {}
		@buttons = buttons
		@buttonsMapId = {}

		local skipButton
		with innerPanel = vgui.Create "DPanel", @discussWindow
			\SetSize (733/856) * newWidth, (506/590) * newHeight
			\SetPos newWidth * (37/856), newWidth * (37/856)
			.Paint = ->

			sw = innerPanel\GetWide! * 0.05
			sh = innerPanel\GetTall! * 0.2

			\DockPadding sw*0.5, 0, sw*0.5, 0

			with innerUpper = innerPanel\Add "DPanel"
				\Dock TOP
				\SetTall sh * 0.6
				.Paint = (_, w, h) ->
					draw.SimpleTextOutlined "Who Is The Imposter?", "NMW AU Meeting Title", 
						w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0)

			with innerLower = innerPanel\Add "DPanel"
				\Dock BOTTOM
				\SetTall sh * 0.6

				paintText = (w, h, text) ->
					draw.SimpleTextOutlined text, "NMW AU Meeting Time", 
						w, h/2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0)

				.Paint = (_, w, h) ->
					begin = beginAnim.EndTime - SysTime!

					if begin > 0
						paintText w, h, string.format "Voting Begins In: %ds ", math.max 0, math.floor beginAnim.EndTime - SysTime!
					elseif @proceeding
						paintText w, h, string.format "Proceeding In: %ds ", math.max 0, math.floor @proceeding.EndTime - SysTime!
					else
						paintText w, h, string.format "Voting Ends In: %ds ", math.max 0, math.floor endAnim.EndTime - SysTime!

				@skipArea = with skipArea = innerLower\Add "DPanel"
					\Dock FILL
					\SetAlpha 0
					.Paint = ->

					with glyph = \Add "DPanel"
						\SetWide sh * 0.6
						\Dock LEFT
						.Image = DISCUSS.skipped
						.Paint = GAMEMODE.Render.DermaFitImage

					skipArea.output = with \Add "DPanel"
						\DockMargin sh * 0.05, sh * 0.125, 0, sh * 0.125
						\Dock FILL
						.Paint = ->

				skipButton = with @skipButton = innerLower\Add "DButton"
					\SetText ""
					aspect = 27/112

					skipWidth = newWidth * 0.125
					skipHeight = aspect * skipWidth
					.Image = DISCUSS.skip
					.Paint = GAMEMODE.Render.DermaFitImage
					\SetEnabled false
					\NewAnimation 0, discuss_splash_time + GAMEMODE.ConVars.VotePreTime\GetInt!, 0, ->
						\SetEnabled true
					\SetSize skipWidth, skipHeight
					\SetPos skipWidth * 0.1, (sh * 0.6)/2 - skipHeight/2
					.DoClick = (_) ->
						if not \IsEnabled!
							return

						@PurgeConfirms!

						\SetEnabled false

						skipButton.confirm = with confirm = innerLower\Add "DPanel"
							surface.PlaySound "au/votescreen_avote.wav"

							@PurgeConfirms!

							\SetSize innerLower\GetWide!/2, sh*0.6
							\SetPos skipWidth * 0.2 + skipWidth, 0
							\SetZPos 40
							.Paint = ->
					
							with yes = \Add "DImageButton"
								\SetText ""
								\SetWide confirm\GetTall!
								\Dock LEFT
								\SetImage "au/gui/meeting/confirm_yes.png"
								\SetStretchToFit true
								.DoClick = ->
									surface.PlaySound "au/votescreen_lockin.wav"

									@DisableAllButtons!

									GAMEMODE\SendVote!

							with no = \Add "DImageButton"
								\SetText ""
								\DockMargin confirm\GetTall!*0.2, 0, 0, 0
								\SetWide confirm\GetTall!
								\Dock LEFT
								\SetImage "au/gui/meeting/confirm_no.png"
								\SetStretchToFit true
								.DoClick = -> @PurgeConfirms!

				table.insert buttons, skipButton
	
			with scroll = innerPanel\Add "DScrollPanel"
				\Dock FILL
				.Paint = ->
				\NewAnimation 0, 0, 0, ->
					with list = vgui.Create "DIconLayout", scroll
						\Dock( FILL )
						\SetSpaceY scroll\GetWide! * 0.0125
						\SetSpaceX scroll\GetTall! * 0.02

						table.sort GAMEMODE.GameData.ActivePlayers, (a, b) ->
							disconnected = not IsValid a.entity
							alive = not disconnected and not GAMEMODE.GameData.DeadPlayers[a]
							va = (alive and GAMEMODE.GameData.Imposters[a] and 1) or alive and 0.5 or 0
							
							disconnected = not IsValid b.entity
							alive = not disconnected and not GAMEMODE.GameData.DeadPlayers[b]
							vb = (alive and GAMEMODE.GameData.Imposters[b] and 1) or alive and 0.5 or 0

							return va > vb

						for _, ply in ipairs GAMEMODE.GameData.ActivePlayers or {}
							disconnected = not IsValid ply.entity
							alive = not disconnected and not GAMEMODE.GameData.DeadPlayers[ply]

							with container = list\Add "DPanel"
								\SetSize scroll\GetWide! * 0.475, scroll\GetTall! * 0.165
								.Paint = (_, w, h) ->

								innerItemSizeW, innerItemSizeH = container\GetSize!
								offset = innerItemSizeH * 0.075
								innerItemSizeW -= offset
								innerItemSizeH -= offset

								with shadow = \Add "DPanel"
									\SetPos offset, offset
									\SetSize innerItemSizeW, innerItemSizeH
									.Paint = (_, w, h) ->
										draw.RoundedBox 16, 0, 0, w, h, Color 0, 0, 0, 100

								table.insert buttons, with listItem = \Add "DPanel"
									@buttonsMapId[ply.id] = listItem
									listItem.ply = ply
									\SetSize innerItemSizeW, innerItemSizeH
									\SetZPos 10
							
									.Paint = (_, w, h) ->
										draw.RoundedBox 16, 0, 0, w, h, Color 255, 255, 255

										if ply == caller
											value = math.min 1, math.max 0, (beginAnim.StartTime + 1 - SysTime!)

											if value == 1
												return

											if value ~= 0
												surface.DisableClipping true

											mWidth, mHeight = GAMEMODE.Render.FitMaterial DISCUSS.megaphone, w, h

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
											surface.SetMaterial DISCUSS.megaphone
											surface.SetDrawColor Color 255, 255, 255, 255 * 1/value
											surface.DrawTexturedRect w - mWidth - mWidth * 0.25, 0, mWidth, mHeight
											cam.PopModelMatrix!
										
											if value ~= 0
												surface.DisableClipping false
										
									with crew = listItem\Add "DPanel"
										\SetSize listItem\GetTall!, listItem\GetTall!
										\Dock LEFT
										pad = \GetTall! * 0.05
										\DockPadding pad, pad, pad, pad
										.Paint = ->

										layers = {}
										for i = 1, 2
											with layers[i] = vgui.Create "DPanel", crew
												\SetSize crew\GetTall! * 0.8, crew\GetTall! * 0.8
												\SetPos crew\GetWide!/2 - \GetWide!/2, crew\GetTall!/2 - \GetTall!/2
												.Image = CREW_LAYERS[i]
												.Paint = GAMEMODE.Render.DermaFitImage
										layers[1].Color = ply.color

										with overlay = crew\Add "DPanel"
											\Dock FILL
											
											.Paint = (_, w, h) ->
												if not alive then
													value = math.min 1, math.max 0, (beginAnim.StartTime + 0.4 - SysTime!) / 0.4
													if value == 1
														return

													if value ~= 0
														surface.DisableClipping true

													surface.SetMaterial DISCUSS.dead
													surface.SetDrawColor Color 255, 255, 255, math.floor 255 * 1 / value
													
													surface.DrawTexturedRect -w * value, -h * value, w + w * 2 * value, h + h * 2 * value

													if value ~= 0
														surface.DisableClipping false

										listItem.voted = with crew\Add "DPanel"
											\SetAlpha 0
											.Paint = (_) ->
												w = crew\GetTall!

												surface.DisableClipping true
												surface.SetMaterial DISCUSS.voted
												surface.SetDrawColor Color 255, 255, 255
												surface.DrawTexturedRect -w/6, -w/6, w/2, w/2
												surface.DisableClipping false

									with upper = listItem\Add "DPanel"
										\SetTall listItem\GetTall! / 2
										clr = if GAMEMODE.GameData.Imposters[ply]
											Color 255, 30, 0
										else
											Color 255, 255, 255
										
										\Dock TOP
										.Paint = (_, w, h) ->
											draw.SimpleTextOutlined ply.nickname or "N/A", "NMW AU Meeting Nickname", 
												0, h/2, clr, nil, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0)
										

									listItem.output = with lower = listItem\Add "DPanel"
										\SetTall listItem\GetTall! / 2
										\Dock BOTTOM
										.Paint = ->

									with shadowOverlay = listItem\Add "DPanel"
										\SetSize listItem\GetWide!, listItem\GetTall!
										\SetAlpha 100
										if alive
											\AlphaTo 0, 0.25, discuss_splash_time + GAMEMODE.ConVars.VotePreTime\GetInt!, ->
												\SetZPos 20
										\SetZPos 40
										.Paint = (_, w, h) ->
											draw.RoundedBox 16, 0, 0, w, h, Color 0, 0, 0, 255

									listItem.buttonOverlay = with listItem\Add "DButton"
										\SetText ""
										\SetSize listItem\GetWide!, listItem\GetTall!
										\SetEnabled false
										\SetZPos 30
										.Paint = ->

										if alive
											\NewAnimation 0, discuss_splash_time + GAMEMODE.ConVars.VotePreTime\GetInt!, 0, ->
												\SetEnabled true

											.DoClick = ->
												surface.PlaySound "au/votescreen_avote.wav"
												listItem.buttonOverlay\SetEnabled false

												if IsValid skipButton.confirm
													skipButton\SetEnabled true
													skipButton.confirm\Remove!
												
												for _, btn in ipairs buttons
													if IsValid btn.confirm
														btn.buttonOverlay\SetEnabled true
														btn.confirm\Remove!

												confirm = with listItem.confirm = listItem.buttonOverlay\Add "DPanel"
													\DockPadding listItem\GetTall!*0.1, 0, listItem\GetTall!*0.1, 0
													\DockMargin 0, listItem\GetTall!*0.1, 0, listItem\GetTall!*0.1
													\SetWide listItem\GetWide!
													\Dock RIGHT
													.Paint = ->

													\NewAnimation 0, 0, 0, ->
														with no = confirm\Add "DImageButton"
															\SetText ""
															\DockMargin listItem\GetTall!*0.1, 0, 0, 0
															\SetWide confirm\GetTall!
															\Dock RIGHT
															\SetImage "au/gui/meeting/confirm_no.png"
															\SetStretchToFit true
															.DoClick = ->
																listItem.buttonOverlay\SetEnabled true
																confirm\Remove!
													
														with yes = confirm\Add "DImageButton"
															\SetText ""
															\SetWide confirm\GetTall!
															\Dock RIGHT
															\SetImage "au/gui/meeting/confirm_yes.png"
															\SetStretchToFit true
															.DoClick = ->
																surface.PlaySound "au/votescreen_lockin.wav"
																@DisableAllButtons!

																GAMEMODE\SendVote ply.id

	with discussAnim = vgui.Create "DPanel", @
		size = 0.8 * math.min @GetTall!, @GetWide!
		\SetSize size, size
		\SetPos @GetWide!/2 - size/2, @GetTall!/2 - size/2
		\SetZPos 30
		\SetAlpha 0
		\AlphaTo 255, 0.1, 0
		\AlphaTo 0, 0.1, 3, ->
			\Remove!

			@discussWindow\SetMouseInputEnabled true
			gui.EnableScreenClicker true

		.Paint = (_, w, h) ->
			if not _.circle
				_.circle = circle w/2, w/2, w*0.498, 64

			surface.SetMaterial DISCUSS.bg
			surface.SetDrawColor Color 255, 255, 255
			surface.DrawTexturedRect 0, 0, w, h

			with render
				.PushFilterMag TEXFILTER.ANISOTROPIC
				.PushFilterMin TEXFILTER.ANISOTROPIC
				.ClearStencil()

				.SetStencilEnable(true)
				.SetStencilTestMask(0xFF)
				.SetStencilWriteMask(0xFF)
				.SetStencilReferenceValue(0x01)

				.SetStencilCompareFunction(STENCIL_NEVER)
				.SetStencilFailOperation(STENCIL_REPLACE)
				.SetStencilZFailOperation(STENCIL_REPLACE)

				surface.DrawPoly _.circle

				.SetStencilCompareFunction(STENCIL_LESSEQUAL)
				.SetStencilFailOperation(STENCIL_KEEP)
				.SetStencilZFailOperation(STENCIL_KEEP)

				.PopFilterMag!
				.PopFilterMin!

				do
					ltsx, ltsy = _\LocalToScreen 0, 0
					ltsv = Vector ltsx, ltsy, 0
					v = Vector  w/4, h / 2 + h/3, 0

					m = Matrix!
					m\Translate ltsv
					m\Translate v
					m\Rotate Angle 0, (math.sin(math.rad(CurTime! * 1200))) * 2, 0
					m\Translate -v
					m\Translate -ltsv

					cam.PushModelMatrix m, true
					surface.SetMaterial DISCUSS.yes_crewLeft
					surface.DrawTexturedRect -w*0.1, h/2-h*0.1, w/2 + w*0.15, h/2+h*0.2
					cam.PopModelMatrix!

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
					surface.SetMaterial DISCUSS.yes_crewRight
					surface.DrawTexturedRect w/2, h/2-h*0.05, w/2 + w*0.2, h/2+h*0.2
					cam.PopModelMatrix!
 
				.SetStencilEnable(false)

				surface.SetMaterial DISCUSS.border
				surface.DrawTexturedRect 0, 0, w, h

	with discussText = vgui.Create "DPanel", @
		size = 0.8 * math.min @GetTall!, @GetWide!
		\SetSize size, size * 0.3
		\SetPos @GetWide!/2 - size/2, -size * 0.2
		\SetZPos 31 
		\MoveTo @GetWide!/2 - size/2, @GetTall! * 0.15, 0.3, 0
		\SetAlpha 0
		\AlphaTo 255, 0.3, 0
		\AlphaTo 0, 0.1, 3, ->
			\Remove! 
		.Image = DISCUSS.text
		.Paint = GAMEMODE.Render.DermaFitImage

meeting.ApplyVote = (ply) =>
	if @buttonsMapId and @buttonsMapId[ply.id]
		if ply.entity ~= LocalPlayer!
			surface.PlaySound "au/notification.wav"

		@buttonsMapId[ply.id].voted\AlphaTo 255, 0.05
		return

meeting.End = (results) =>
	@proceeding = {
		StartTime: SysTime!
		EndTime: SysTime! + GAMEMODE.ConVars.VotePostTime\GetInt!
	}

	if IsValid @skipButton
		@skipButton\Remove!
		if IsValid @skipButton.confirm
			@skipButton.confirm\Remove!
	
	if @buttons and GAMEMODE.GameData.ActivePlayersMap
		@skipArea\AlphaTo 255, 0.25, 0, ->
			for _, btn in ipairs @buttons
				if IsValid btn.confirm
					btn.confirm\Remove!

				if IsValid btn.buttonOverlay
					btn.buttonOverlay\Remove!

			for _, result in pairs results
				outputPanel = if result.targetid == 0
					@skipArea.output
				else
					@buttonsMapId[result.targetid].output

				if IsValid outputPanel
					with outputPanel
						for i, voter in ipairs result.votes
							with miniCrew = outputPanel\Add "DPanel"
								\SetWide outputPanel\GetTall!
								\Dock LEFT
								\SetAlpha 0
								\AlphaTo 255, 0.05, i * 0.5
								.Paint = ->
								layers = {}
								for i = 1, 2
									with layers[i] = vgui.Create "DPanel", miniCrew
										\SetSize outputPanel\GetTall! * 0.8, outputPanel\GetTall! * 0.8
										\SetPos outputPanel\GetTall! * 0.1, outputPanel\GetTall! * 0.1
										.Image = CREW_MINI_LAYERS[i]
										.Paint = GAMEMODE.Render.DermaFitImage
								
								aply = GAMEMODE.GameData.ActivePlayersMapId[voter]
								if aply
									layers[1].Color = aply.color

meeting.Close = => with @
	@AlphaTo 0, 0.25, 0, ->
		@Remove!

meeting.OnRemove = =>
	gui.EnableScreenClicker false

meeting.StartEmergency = (ply, bodyColor) =>
	if bodyColor
		surface.PlaySound "au/report_body.wav"
	else
		surface.PlaySound "au/alarm_emergencymeeting.wav"

	@PlayBackground ->
		with emergency_caller = vgui.Create "DPanel", @
			size = 0.7 * math.min @GetTall!, @GetWide!

			\SetSize size, size
			\SetPos @GetWide!/2 - size/2, @GetTall!/2 - size/2
			\AlphaTo 0, 0.1, 3, ->
				\Remove!
			.Paint = ->

			with upper = vgui.Create "DPanel", emergency_caller
				\SetTall size/2
				\Dock TOP
				.Paint = ->

				\NewAnimation 0, 0, -1, ->
					layers = {}
					pics = if bodyColor
						VGUI_BODY_LAYERS
					else
						VGUI_EMERGENCY_LAYERS

					for i = 4, 1, -1
						with layers[i] = vgui.Create "DPanel", upper
							\SetSize size / 2, size / 2
							\CenterHorizontal!
							\SetZPos 5 - i
							.Image = pics[i]
							.Paint = GAMEMODE.Render.DermaFitImage

					if bodyColor
						layers[3].Color = bodyColor
					else
						layers[2].Color = ply.color
						layers[4].Color = ply.color

			with lower = vgui.Create "DPanel", emergency_caller
				\SetTall size/2
				\Dock BOTTOM
				.Image = if bodyColor
					VGUI_BODY_LAYERS[5]
				else
					VGUI_EMERGENCY_LAYERS[5]

				.Paint = GAMEMODE.Render.DermaFitImage

return vgui.RegisterTable meeting, "DPanel"