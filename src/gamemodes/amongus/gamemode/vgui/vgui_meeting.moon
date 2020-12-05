TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Meeting Nickname", {
	font: "Roboto"
	size: ScreenScale 15
	weight: 550
}

surface.CreateFont "NMW AU Meeting Chat", {
	font: "Roboto"
	size: ScreenScale 12
	weight: 550
}

surface.CreateFont "NMW AU Meeting Chat Nickname", {
	font: "Roboto"
	size: ScreenScale 14
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
	chat: Material "au/gui/meeting/chat.png", "smooth"
	chatOverlay: Material "au/gui/meeting/chatoverlay.png", "smooth"
	chatbump: Material "au/gui/meeting/chatbump.png", "smooth"
}

COLOR_WHITE = Color 255, 255, 255
COLOR_BLACK = Color 0, 0, 0

meeting = {}

DISCUSS_SPLASH_TIME = 3

ROTATION_MATRIX = Matrix!

--- Creates the famous pre-vote popup.
-- I had fun coming up with this one.
meeting.PlayBackground = (callback) =>
	local rot, shrinkAnim
	with bg = @Add "Panel"
		\SetSize @GetWide!, @GetTall!
		\SetPos 0, 0

		rot = 33
		\NewAnimation 0.1, 0, -1, ->
			rot = -33
			\NewAnimation 0.1, 0, -1, ->
				rot = 0
				if callback
					callback!
				\NewAnimation 3, 0, -1, ->
					shrinkAnim = \NewAnimation 0.35, 0

		aspect = 435/948

		.Paint = (_, w, h) ->
			ltsx, ltsy = _\LocalToScreen 0, 0
			v = Vector ltsx + w / 2, ltsy + h / 2, 0

			with ROTATION_MATRIX
				\Identity!
				\Translate v
				\Rotate Angle 0, rot, 0
				if rot ~= 0
					\Scale Vector 1.5, 1.5, 1.5
				if shrinkAnim
					\Scale Vector 1, ((shrinkAnim.EndTime - SysTime!) / (shrinkAnim.EndTime - shrinkAnim.StartTime)), 1

				\Translate -v

			cam.PushModelMatrix ROTATION_MATRIX, true
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

--- Disables all buttons. Duh.
meeting.DisableAllButtons = =>
	for id, voteItem in pairs @__voteItems
		if IsValid voteItem
			voteItem\SetEnabled false

meeting.CanIVote = =>
	localPlayer = LocalPlayer!
	return IsValid(localPlayer) and localPlayer\GetAUPlayerTable! and
		not localPlayer\IsDead!

--- Purges all existing confirms.
meeting.PurgeConfirms = =>
	for confirm in pairs @__confirms
		if IsValid confirm then confirm\Close!

	@__confirms = {}

--- Creates a confirm popup.
-- @param height Height.
-- @param id Player ID.
meeting.CreateConfirm = (height, id) =>
	@PurgeConfirms!

	return with confirm = vgui.Create "Panel"
		buttonSpacing = height * 0.2

		\SetAlpha 0
		\SetZPos 40
		\SetSize height * 2 + buttonSpacing, height

		.Close = =>
			@__closing = true

			@AlphaTo 0, 0.075, 0, ->
				@Remove!

		@__confirms[confirm] = true
		.OnRemove = -> @__confirms[confirm] = nil

		-- Yes
		with \Add "DImageButton"
			\SetText ""

			\Dock LEFT
			\SetWide height

			\SetImage "au/gui/meeting/confirm_yes.png"
			\SetStretchToFit true

			.DoClick = ->
				return if confirm.__closing

				surface.PlaySound "au/votescreen_lockin.ogg"

				@PurgeConfirms!
				@DisableAllButtons!

				GAMEMODE\Net_SendVote id

		-- No
		with \Add "DImageButton"
			\SetText ""

			\Dock LEFT
			\DockMargin height * 0.2, 0, 0, 0
			\SetWide height

			\SetImage "au/gui/meeting/confirm_no.png"
			\SetStretchToFit true

			.DoClick = ->
				return if confirm.__closing

				confirm\Close!

		\AlphaTo 255, 0.15, 0

COLOR_WHITE = Color 255, 255, 255

STATES = {
	begins: 1
	ends: 2
	proceeding: 3
}

meeting.OpenDiscuss = (caller, time) =>
	@__voteItems = {}
	@__currentState = STATES.begins

	-- Wait for the discuss splash to disappear.
	@NewAnimation DISCUSS_SPLASH_TIME, 0, 0, ->
		@__megaphoneAnimation = @NewAnimation 2, 0, 0
		@__kilAnimation = @NewAnimation 0.35, 0, 0

	@__currentAnimation = @NewAnimation time - SysTime!, 0, 0, ->
			-- Un-darken all buttons.
			for id, voteItem in pairs @__voteItems
				voteItem\SetEnabled true

				if voteItem.SetDark
					voteItem\SetDark false

			-- Let the timer know that now we're waiting for the panel to close.
			@__currentState = STATES.ends

			-- Lift off.
			@__currentAnimation = @NewAnimation GAMEMODE.ConVarSnapshots.VoteTime\GetInt!, 0, 0

	with @Add "EditablePanel"
		tabletWidth, tabletHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.tablet,
			@GetWide!, @GetTall!

		tabletHeight *= 0.9
		tabletWidth  *= 0.9
		maxSize = math.max tabletHeight, tabletWidth

		-- Position.
		\SetSize tabletWidth, tabletHeight
		\SetPos @GetWide!/2 - tabletWidth/2,
			@GetTall!/2 - tabletHeight/2

		-- Animate the translucency.
		\SetAlpha 0
		\AlphaTo 255, 0.1, 0

		-- Popup.
		\MakePopup!
		\SetKeyboardInputEnabled false
		gui.EnableScreenClicker true

		-- Paint the sprite.
		.Image = MAT_MEETING_TABLET.tablet
		.Paint = GAMEMODE.Render.DermaFitImage

		-- Optionally, paint the shatter overlay if the player is dead.
		if LocalPlayer!\IsDead!
			with \Add "DImage"
				\SetSize tabletWidth, tabletHeight
				\SetMaterial MAT_MEETING_TABLET.shatter
				\SetMouseInputEnabled false
				\SetKeyboardInputEnabled false
				\SetZPos 80

		innerPanelSizeX = (733 / 856) * tabletWidth
		innerPanelSizeY = (506 / 590) * tabletHeight
		innerPanelPosX  = (37  / 856) * tabletWidth
		innerPanelPosY  = (37  / 856) * tabletWidth
		innerPanelMargin = maxSize * 0.015

		headerHeight      = tabletHeight * 0.12
		footerMarginRight = headerHeight * 0.5
		chatButtonMargin  = headerHeight * 0.05

		-- Chat overlay.
		@__chatOverlay = with \Add "DImage"
			local textInput, chatArea

			chatOverlaySizeX, chatOverlaySizeY = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.chatOverlay,
				innerPanelSizeX, innerPanelSizeY

			chatOverlayInnerSizeX = 0.975 * chatOverlaySizeX
			chatOverlayInnerSizeY = 0.975 * chatOverlaySizeY
			\SetPos innerPanelPosX + chatOverlaySizeX / 2 - chatOverlayInnerSizeX / 2,
				innerPanelPosY + chatOverlaySizeY / 2 - chatOverlayInnerSizeY / 2

			chatOverlayInnerPadding = 0.0075 * chatOverlayInnerSizeX

			\SetMouseInputEnabled true
			\SetSize chatOverlayInnerSizeX, chatOverlayInnerSizeY
			\SetZPos 90

			\SetMaterial MAT_MEETING_TABLET.chatOverlay

			\SetAlpha 0
			\Hide!

			toggled = false
			.Toggle = ->
				toggled = not toggled
				if toggled
					@SetKeyboardInputEnabled true
					\Show!

					-- Scroll to the last child.
					\NewAnimation 0, 0, 0, ->
						textInput\RequestFocus!

						chatAreaChildren = chatArea\GetCanvas!\GetChildren!
						lastChild = chatAreaChildren[#chatAreaChildren]
						if IsValid lastChild
							chatArea\ScrollToChild lastChild

				\AlphaTo toggled and 255 or 0, 0.1, nil, ->
					if not toggled
						@SetKeyboardInputEnabled false
						\Hide!

			-- Inner area.
			innerArea = with \Add "EditablePanel"
				\DockPadding chatOverlayInnerPadding, chatOverlayInnerPadding,
					chatOverlayInnerPadding, chatOverlayInnerPadding

				innerChatAreaPosX =  (8   / 700) * chatOverlayInnerSizeX
				innerChatAreaPosY =  (8   / 486) * chatOverlayInnerSizeY
				innerChatAreaSizeX = (636 / 700) * chatOverlayInnerSizeX
				innerChatAreaSizeY = (480 / 486) * chatOverlayInnerSizeY

				\SetPos  innerChatAreaPosX , innerChatAreaPosX
				\SetSize innerChatAreaSizeX, innerChatAreaSizeY

				-- Chat messages area.
				chatArea = with \Add "DScrollPanel"
					\Dock FILL
					\DockMargin 0, 0, 0, chatOverlayInnerPadding

				-- Input box.
				textInput = with \Add "DTextEntry"
					\DockMargin 0, 0, 0, chatOverlayInnerPadding
					\SetTall ScreenScale 15
					\Dock BOTTOM

					\SetFont "NMW AU Meeting Chat"
					\SetTextColor Color 0, 0, 0

					.OnEnter = ->
						RunConsoleCommand "say", \GetValue!
						\SetText ""

						-- Scroll to the last child.
						\NewAnimation 0, 0, 0, ->
							\RequestFocus!

							chatAreaChildren = chatArea\GetCanvas!\GetChildren!
							lastChild = chatAreaChildren[#chatAreaChildren]
							if IsValid lastChild
								chatArea\ScrollToChild lastChild

			playerIconWidth  = tabletHeight * 0.07
			playerIconMargin = tabletHeight * 0.01

			shadowOffset = tabletHeight * 0.006
			with chatArea\GetCanvas!
				\DockPadding shadowOffset, shadowOffset,
					shadowOffset * 2, shadowOffset * 2

			shadowColor   = Color 0, 0, 0, 100
			itemColor     = Color 255, 255, 255
			itemColorDead = Color 220, 220, 220

			chatLineDockMargin = tabletHeight * 0.2

			paintVoteElement = (w, h) =>
				scissorX1, scissorY1 = chatArea\LocalToScreen 0, 0
				scissorX2 = scissorX1 + chatArea\GetWide!
				scissorY2 = scissorY1 + chatArea\GetTall!

				render.SetScissorRect scissorX1, scissorY1, scissorX2, scissorY2, true
				surface.DisableClipping true
				draw.RoundedBox 16, shadowOffset, shadowOffset, w, h, shadowColor
				surface.DisableClipping false
				render.SetScissorRect 0, 0, 0, 0, false

				draw.RoundedBox 16, 0, 0, w, h, @Color or itemColor

			-- Push new vote message to the chat overlay.
			.PushVote = (_, playerTable, remaining) ->
				with chatArea
					children = \GetCanvas!\GetChildren!
					if #children > 20
						children[1]\Remove!

					-- Container.
					with container = \Add "Panel"
						\Dock TOP
						\DockMargin chatLineDockMargin / 4, 0,
							chatLineDockMargin or 0, shadowOffset * 2

						\SetAlpha 0

						.Paint = paintVoteElement

						if playerTable
							-- Crewmate icon.
							with \Add "AmongUsCrewmate"
								\Dock LEFT
								margin = playerIconMargin * 0.6
								\DockMargin margin, margin,
									margin, margin

								\SetWide playerIconWidth * 0.6
								\SetColor playerTable.color

						-- Text label.
						with \Add "DOutlinedLabel"
							\Dock FILL
							\DockMargin shadowOffset, shadowOffset, shadowOffset, shadowOffset
							\SetColor Color 64, 220, 64

							\SetFont "NMW AU Meeting Chat"
							\SetText tostring TRANSLATE("vote.voted") (playerTable and playerTable.nickname) or "???", remaining
							\SetContentAlignment 4

						\SetTall 0.6 * (2 * playerIconMargin + playerIconWidth)
						\AlphaTo 255, 0.1

			.PushMessage = (_, dock, playerTable, msg, voted = false) ->
				with chatArea
					local nicknameLabel, textLabel

					children = \GetCanvas!\GetChildren!
					if #children > 20
						children[1]\Remove!

					targetColor = (playerTable and IsValid(playerTable.entity) and
						not GAMEMODE.GameData.DeadPlayers[playerTable]) and itemColor or itemColorDead

					-- Container.
					with container = \Add "Panel"
						\Dock TOP
						\DockMargin dock == RIGHT and chatLineDockMargin or 0, 0,
							dock == LEFT and chatLineDockMargin or 0, shadowOffset * 2

						\SetAlpha 0

						.Color = targetColor
						.Paint = paintVoteElement

						if playerTable
							-- Crewmate icon container.
							with \Add "Panel"
								\Dock LEFT
								\SetWide playerIconWidth
								\DockMargin playerIconMargin, playerIconMargin,
									playerIconMargin, playerIconMargin

								-- Crewmate icon.
								with \Add "AmongUsCrewmate"
									\Dock TOP
									\SetSize playerIconWidth, playerIconWidth
									\SetColor playerTable.color

									if targetColor ~= itemColor or voted
										-- Optional "modifier"-kind-of icon.
										with \Add "DImage"
											\SetMaterial if voted
												MAT_MEETING_TABLET.voted
											else
												MAT_MEETING_TABLET.dead

											\Dock FILL
											\DockMargin playerIconWidth * 0.02, playerIconWidth * 0.48,
												playerIconWidth * 0.48, playerIconWidth * 0.02

						-- Nickname label.
						nicknameLabel = with \Add "DOutlinedLabel"
							\Dock TOP
							\DockMargin shadowOffset, shadowOffset, shadowOffset, shadowOffset

							\SetColor if GAMEMODE.GameData.Imposters[playerTable]
								Color 255, 0, 0
							else
								Color 255, 255, 255

							\SetFont "NMW AU Meeting Chat Nickname"
							\SetText playerTable.nickname
							\SetTall ScreenScale 14
							\SetContentAlignment 4

						-- Text label.
						textLabel = with \Add "DLabel"
							\SetColor Color 0, 0, 0
							\SetFont "NMW AU Meeting Chat"
							\SetText msg
							\SetWrap true
							\SetAutoStretchVertical true

						-- https://youtu.be/z-JRdRXiNv4
						\NewAnimation 0, 0, 0, -> \NewAnimation 0, 0, 0, ->
							with textLabel
								\SetWide nicknameLabel\GetWide!
								\AlignLeft nicknameLabel\GetPos!
								\MoveBelow nicknameLabel
								\InvalidateLayout true

							\NewAnimation 0, 0, 0, ->
								\SizeToChildren false, true

								\AlphaTo 255, 0.1
								\NewAnimation 0, 0, 0, ->
									\SetTall \GetTall! + shadowOffset * 0.5
									chatArea\ScrollToChild container

			handle = "NMW AU MeetingChat"

			-- Append the chat text.
			hook.Add "OnPlayerChat", handle, (ply, text) ->
				if not IsValid chatArea
					hook.Remove "OnPlayerChat", handle
					return

				playerTable = IsValid(ply) and ply\GetAUPlayerTable!

				-- Sub the text if too long.
				textLen = #text
				text = string.sub text or "", 1, 100
				if #text > 100
					text ..= "..."

				@__chatButton\Bump!
				\PushMessage ply == LocalPlayer! and RIGHT or LEFT, playerTable,
					text, @__voted[playerTable]

			-- Close the chat overlay when clicked off.
			hook.Add "VGUIMousePressed", handle, (panel, mouseCode) ->
				if not IsValid chatArea
					hook.Remove "VGUIMousePressed", handle
					return

				if mouseCode == MOUSE_FIRST and toggled and
					panel ~= @__chatButton and not panel\HasParent innerArea
						\Toggle!

			-- We don't want the default chat to be drawn.
			hook.Add "HUDShouldDraw", handle, (element) ->
				if not IsValid chatArea
					hook.Remove "HUDShouldDraw", handle
					return

				return false if element == "CHudChat"

			.OnRemove = ->
				hook.Remove "OnPlayerChat"    , handle
				hook.Remove "VGUIMousePressed", handle
				hook.Remove "HUDShouldDraw"   , handle

		-- Create the inner panel.
		with innerPanel = \Add "EditablePanel"
			\SetSize innerPanelSizeX , innerPanelSizeY
			\SetPos  innerPanelPosX  , innerPanelPosY

			-- Header.
			-- Contains the "Who is the Imposter?" label and some buttons.
			with innerPanel\Add "DOutlinedLabel"
				\Dock TOP

				\SetTall headerHeight

				\SetContentAlignment 5
				\SetFont "NMW AU Meeting Title"
				\SetText tostring TRANSLATE "meeting.header"

				\SetColor Color 255, 255, 255

				@__chatButton = with \Add "DImageButton"
					\DockMargin chatButtonMargin, chatButtonMargin,
						chatButtonMargin, chatButtonMargin

					\InvalidateParent true

					boxSize = math.floor headerHeight - chatButtonMargin * 2
					chatButtonWidth, chatButtonHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.chat,
						boxSize, boxSize

					\Dock RIGHT
					\SetWide chatButtonWidth

					\SetMaterial MAT_MEETING_TABLET.chat

					redCircleSize = chatButtonHeight * 0.45
					redCircle = with \Add "DImage"
						\SetSize redCircleSize, redCircleSize
						\SetAlpha 0
						\SetPos -redCircleSize / 2, chatButtonHeight / 2 - redCircleSize / 2

						-- NoClipping DOES NOT WORK WITH DIMAGES.
						-- GOD DAMN IT.
						.Paint = (_, w, h) ->
							surface.DisableClipping true
							surface.SetDrawColor 255, 255, 255
							surface.SetMaterial MAT_MEETING_TABLET.chatbump
							render.PushFilterMag TEXFILTER.ANISOTROPIC
							render.PushFilterMin TEXFILTER.ANISOTROPIC
							surface.DrawTexturedRect 0, 0, w, h
							render.PopFilterMag!
							render.PopFilterMin!
							surface.DisableClipping false

					.Bump = ->
						return if @__chatOverlay\GetAlpha! > 0

						origin = chatButtonHeight / 2 - redCircleSize / 2

						redCircle\AlphaTo 255, 0.15
						redCircle\MoveTo -redCircleSize / 2, origin - redCircleSize * 0.75, 0.125, nil, nil, ->
								redCircle\MoveTo -redCircleSize / 2, origin, 0.125

					.DoClick = ->
						redCircle\AlphaTo 0, 0.15
						@__chatOverlay\Toggle!

			-- Footer.
			with footer = innerPanel\Add "DOutlinedLabel"
				\Dock BOTTOM
				\DockMargin innerPanelMargin, 0,
					footerMarginRight, 0

				\SetTall headerHeight

				\SetFont "NMW AU Meeting Time"
				\SetContentAlignment 6

				-- Is this dumb? Yes. Is this dumb? Yes.
				-- Is this dumb? Still yes.
				.GetText = ->
					time = math.max 0, @__currentAnimation.EndTime - SysTime!

					return tostring(switch @__currentState
						when STATES.begins
							TRANSLATE("meeting.timer.begins") time

						when STATES.proceeding
							TRANSLATE("meeting.timer.proceeding") time

						when STATES.ends
							TRANSLATE("meeting.timer.ends") time
					) .. " " -- yea

				-- Prepare the post-vote are that we can add voter icons to.
				with @__skipArea = \Add "Panel"
					\Dock FILL
					\InvalidateParent true
					\SetAlpha 0

					-- "Skipped Voting" icon.
					with \Add "Panel"
						\SetWide headerHeight
						\Dock LEFT
						.Image = MAT_MEETING_TABLET.skipped
						.Paint = GAMEMODE.Render.DermaFitImage

					-- The actual output.
					with .output = \Add "Panel"
						verticalMargin = @__skipArea\GetTall! / 3.75
						\DockMargin headerHeight * 0.05, verticalMargin,
							0, verticalMargin

						\Dock FILL

				-- Bogus skip button.
				@__voteItems[0] = with skipButton = \Add "DButton"
					\SetText ""

					aspect = if texture = MAT_MEETING_TABLET.skip\GetTexture "$basetexture"
						texture\GetMappingHeight! / texture\GetMappingWidth!
					else
						1

					skipWidth = headerHeight * 1.25
					skipHeight = aspect * skipWidth

					\SetSize skipWidth, skipHeight
					\SetPos  skipWidth * 0.1,
						headerHeight / 2 - skipHeight / 2

					\SetEnabled false

					.Image = MAT_MEETING_TABLET.skip
					.Paint = GAMEMODE.Render.DermaFitImage

					.DoClick = ->
						return unless @CanIVote!
						return if IsValid skipButton.confirm

						surface.PlaySound "au/votescreen_avote.ogg"

						skipButton.confirm = with @CreateConfirm headerHeight * 0.9
							\SetParent footer
							\SetPos skipWidth * 0.2 + skipWidth, 0
							\CenterVertical!

					.output = @__skipArea.output

			-- Middle.
			-- The actual voting board.
			with innerPanel\Add "DScrollPanel"
				\DockMargin innerPanelMargin, innerPanelMargin,
					innerPanelMargin, innerPanelMargin

				\Dock FILL

				-- Calculate ALL the things.
				scrollBarWidth = \GetVBar!\GetWide!
				innerPanelWidth = innerPanelSizeX - innerPanelMargin * 2 - scrollBarWidth

				itemsPerRow = 2

				voteItemWidth   = math.floor innerPanelWidth / itemsPerRow
				voteItemSpacing = math.floor voteItemWidth * 0.04
				voteItemWidth  -= voteItemSpacing

				voteItemHeight  = math.floor voteItemWidth * 0.18
				voteItemShadowOffset = math.floor voteItemHeight * 0.075

				voteItemInnerSizeX = voteItemWidth  - voteItemShadowOffset
				voteItemInnerSizeY = voteItemHeight - voteItemShadowOffset

				shadowColor = Color 0, 0, 0, 100
				itemColor   = Color 255, 255, 255

				megaphoneWidth, megaphoneHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.megaphone,
					voteItemInnerSizeX, voteItemInnerSizeY

				votedBadgeWidth  = voteItemInnerSizeY
				playerIconMargin = voteItemInnerSizeY * 0.05

				with \Add "DIconLayout"
					\Dock FILL
					\SetSpaceX voteItemSpacing
					\SetSpaceY voteItemSpacing

					-- Make a shallow copy of the player list.
					playerList = [ply for ply in *GAMEMODE.GameData.PlayerTables]

					-- Sort the list.
					-- Imposters get the highest priority, and dead people get the lowest priority.
					table.sort playerList, (a, b) ->
						alive = IsValid(a.entity) and not GAMEMODE.GameData.DeadPlayers[a]
						va = (alive and GAMEMODE.GameData.Imposters[a] and 1) or alive and 0.5 or 0

						alive = IsValid(b.entity) and not GAMEMODE.GameData.DeadPlayers[b]
						vb = (alive and GAMEMODE.GameData.Imposters[b] and 1) or alive and 0.5 or 0

						return va > vb

					-- Now, create a button per player.
					for playerTable in *playerList
						-- Container.
						with \Add "Panel"
							\SetSize voteItemWidth, voteItemHeight

							-- Shadow.
							with \Add "Panel"
								\SetPos voteItemShadowOffset, voteItemShadowOffset
								\SetSize voteItemInnerSizeX , voteItemInnerSizeY

								.Paint = (_, w, h) -> draw.RoundedBox 16, 0, 0, w, h, shadowColor

							-- Vote item.
							@__voteItems[playerTable.id] = with playerItem = \Add "Panel"
								\SetSize voteItemInnerSizeX, voteItemInnerSizeY

								.Paint = (_, w, h) ->
									draw.RoundedBox 16, 0, 0, w, h, itemColor

									if @__megaphoneAnimation
										-- Let's enter the cringe zone.
										-- This entire chunk of code is responsible for animating
										-- the megaphone akin to the base game.
										--
										-- We need to disable clipping there, but luckily not for too long.
										if playerTable == caller
											value = (@__megaphoneAnimation.EndTime - SysTime!) /
												(@__megaphoneAnimation.EndTime - @__megaphoneAnimation.StartTime)

											value = math.Clamp value, 0, 1

											if value == 1
												return

											mWidth, mHeight = GAMEMODE.Render.FitMaterial MAT_MEETING_TABLET.megaphone, w, h

											if value ~= 0
												surface.DisableClipping true

												ltsx, ltsy = _\LocalToScreen 0, 0
												v = Vector ltsx + w - mWidth * 1.25 + mWidth / 2, ltsy + h / 2, 0

												with ROTATION_MATRIX
													\Identity!
													\Translate v
													\Rotate Angle 0, (math.sin(math.rad(CurTime! * 1600))) * 24 * value, 0
													\Translate -v

												cam.PushModelMatrix ROTATION_MATRIX, true

											expW = mWidth  * value
											expH = mHeight * value

											surface.SetMaterial MAT_MEETING_TABLET.megaphone
											surface.SetDrawColor 255, 255, 255, 255 * (1 - value)
											surface.DrawTexturedRect w - mWidth * 1.25 - expW/2, -expH/2,
												mWidth + expW, mHeight + expH

											if value ~= 0
												cam.PopModelMatrix!
												surface.DisableClipping false

								.SetDark = (state) =>
									return if state and not IsValid(playerTable.entity) or
										GAMEMODE.GameData.DeadPlayers[playerTable]

									@button\AlphaTo state and 255 or 0, 0.5

								.SetEnabled = (state) =>
									return if state and not IsValid(playerTable.entity) or
										GAMEMODE.GameData.DeadPlayers[playerTable]

									@button\SetEnabled state

								-- Player icon.
								with \Add "AmongUsCrewmate"
									\SetWide voteItemInnerSizeY
									\Dock LEFT
									\DockMargin playerIconMargin, playerIconMargin,
										playerIconMargin, playerIconMargin

									\SetColor playerTable.color

									-- Create the red cross overlay if the player is kil.
									if not IsValid(playerTable.entity) or GAMEMODE.GameData.DeadPlayers[playerTable]
										.PaintOver = (_, w, h) ->
											return unless @__kilAnimation

											value = (@__kilAnimation.EndTime - SysTime!) /
												(@__kilAnimation.EndTime - @__kilAnimation.StartTime)

											value = math.Clamp value, 0, 1

											return if value == 1

											if value ~= 0
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
									playerItem.voted = with \Add "Panel"
										\SetAlpha 0

										.Paint = (_) ->
											surface.DisableClipping true
											surface.SetMaterial MAT_MEETING_TABLET.voted
											surface.SetDrawColor COLOR_WHITE
											surface.DrawTexturedRect -votedBadgeWidth/6, -votedBadgeWidth/6,
												votedBadgeWidth/2, votedBadgeWidth/2

											surface.DisableClipping false

								-- Container for the nickname and voter icons.
								with \Add "Panel"
									\Dock FILL

									-- Nickname.
									with \Add "DOutlinedLabel"
										\Dock TOP
										\SetTall voteItemInnerSizeY / 2

										\SetColor Color if GAMEMODE.GameData.Imposters[playerTable]
											255, 30, 0
										else
											255, 255, 255

										-- This is extremely fucking dumb, but outlined
										-- text gets clipped otherwise.
										\SetText " " .. playerTable.nickname
										\SetFont "NMW AU Meeting Nickname"
										\SetContentAlignment 4

									-- Output.
									with playerItem.output = \Add "Panel"
										\Dock BOTTOM
										\SetTall voteItemInnerSizeY / 2

								-- Button overlay.
								with playerItem.button = \Add "DButton"
									-- No visuals please.
									\SetText ""

									\SetSize voteItemInnerSizeX, voteItemInnerSizeY
									\SetEnabled false

									.Paint = (w, h) =>
										surface.SetAlphaMultiplier @GetAlpha! / 255
										draw.RoundedBox 16, 0, 0, w, h, shadowColor
										surface.SetAlphaMultiplier 1

									.DoClick = (this) ->
										return unless @CanIVote!
										return if IsValid playerItem.confirm

										surface.PlaySound "au/votescreen_avote.ogg"

										playerItem.confirm = with @CreateConfirm this\GetTall! - playerIconMargin * 2, playerTable.id
											\SetParent this
											\CenterVertical!
											\AlignRight playerIconMargin

	-- The two crewmates talking animation you see before the meeting screen appears.
	with discussAnim = @Add "Panel"
		size = 0.8 * math.min @GetTall!, @GetWide!
		\SetSize size, size
		\SetPos @GetWide!/2 - size/2, @GetTall!/2 - size/2

		\SetZPos 30
		\SetAlpha 0
		\AlphaTo 255, 0.1, 0
		\AlphaTo 0, 0.1, 3, ->
			\Remove!

		\MakePopup!
		\SetKeyboardInputEnabled false

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

				ltsx, ltsy = _\LocalToScreen 0, 0

				-- Let's enter the abyss.
				do
					v = Vector ltsx + w/3, ltsy + h / 1.5, 0

					with ROTATION_MATRIX
						\Identity!
						\Translate v
						\SetAngles Angle 0, (math.sin(math.rad(CurTime! * 1200))) * 2, 0
						\Translate -v

					cam.PushModelMatrix ROTATION_MATRIX, true
					surface.SetMaterial MAT_DISCUSS.yes_crewLeft
					surface.DrawTexturedRect -w*0.15, h/2-h*0.125, w/2 + w*0.1, h/2+h*0.2
					cam.PopModelMatrix!

				-- Let's enter the abyss one more time.
				do
					v = Vector ltsx + w/2 + w/4, ltsy + h / 2 + h/3, 0

					with ROTATION_MATRIX
						\Identity!
						\Translate v
						\SetAngles Angle 0, (math.cos(math.rad(CurTime! * 1200))) * 2, 0
						\Translate -v

					cam.PushModelMatrix ROTATION_MATRIX, true
					surface.SetMaterial MAT_DISCUSS.yes_crewRight
					surface.DrawTexturedRect w/2, h/2-h*0.05, w/2 + w*0.2, h/2+h*0.2
					cam.PopModelMatrix!

				.SetStencilEnable false

				surface.SetMaterial MAT_DISCUSS.border
				surface.DrawTexturedRect 0, 0, w, h

	-- And finally, something simple.
	-- The "Discuss!" text.
	with discussText = @Add "Panel"
		size = 0.8 * math.min @GetTall!, @GetWide!
		\SetSize size, size * 0.3
		\SetPos @GetWide!/2 - size/2, -size * 0.2
		\SetZPos 31
		\MoveTo @GetWide!/2 - size/2, @GetTall! * 0.15, 0.3, 0
		\SetAlpha 0
		\AlphaTo 255, 0.3, 0
		\AlphaTo 0, 0.1, 3, ->
			\Remove!

		\MakePopup!
		\SetKeyboardInputEnabled false

		.Image = MAT_DISCUSS.text
		.Paint = GAMEMODE.Render.DermaFitImage

--- Apply the player vote, and make his "I Voted" badge pop up.
-- @param playerTable The player table.
meeting.ApplyVote = (playerTable, remaining) =>
	@__voted[playerTable] = true
	@__chatButton\Bump!
	@__chatOverlay\PushVote playerTable, remaining

	if btn = @__voteItems[playerTable.id]
		if playerTable.entity ~= LocalPlayer!
			surface.PlaySound "au/notification.ogg"

		btn.voted\AlphaTo 255, 0.1

--- Ends the vote.
-- @param results The table of results.
meeting.End = (results = {}, time = 0) =>
	@__currentState = STATES.proceeding
	@__currentAnimation = @NewAnimation time - SysTime!, 0, 0

	@DisableAllButtons!
	@PurgeConfirms!

	-- Always the skip button.
	@__voteItems[0]\AlphaTo 0, 0.05

	@__skipArea\AlphaTo 255, 0.25, 0, ->
		for result in *results
			outputPanel = @__voteItems[result.targetid].output

			continue unless IsValid outputPanel

			crewMargin = outputPanel\GetTall! * 0.05
			-- Display a mini-crewmate icon for each player that voted against this person.
			for i, voter in ipairs result.votes
				with outputPanel\Add "Panel"
					\Dock LEFT
					\DockMargin 0, 0, 0, crewMargin

					\SetWide outputPanel\GetTall!

					\SetAlpha 0
					\AlphaTo 255, 0.1, i * 0.5 - .35

					with \Add "AmongUsCrewmate"
						\SetSize outputPanel\GetTall! * 0.8, outputPanel\GetTall! * 0.8
						\SetPos outputPanel\GetTall! * 0.1, outputPanel\GetTall! * 0.1
						\SetFlipX true

						playerTable = GAMEMODE.GameData.Lookup_PlayerByID[voter]
						if playerTable
							\SetColor playerTable.color

--- Starts the emergency.
-- @param playerTable The player who called the vote.
-- @param bodyColor In case this is a body report, the color of the body. Optional.
meeting.StartEmergency = (playerTable, bodyColor) =>
	if bodyColor
		surface.PlaySound "au/report_body.ogg"
	else
		surface.PlaySound "au/alarm_emergencymeeting.ogg"

	@PlayBackground ->
		with emergency_caller = @Add "Panel"
			size = 0.7 * math.min @GetTall!, @GetWide!

			\SetSize size, size
			\SetPos @GetWide!/2 - size/2, @GetTall!/2 - size/2
			\AlphaTo 0, 0.1, 3, ->
				\Remove!

			with upper = emergency_caller\Add "Panel"
				\SetTall size/2
				\Dock TOP

				\InvalidateParent true

				layers = {}
				pics = if bodyColor
					MAT_BODY_LAYERS
				else
					MAT_EMERGENCY_LAYERS

				for i = #pics - 2, 1, -1
					with layers[i] = upper\Add "Panel"
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

			with lower = emergency_caller\Add "Panel"
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

	@__voted = {}
	@__confirms = {}
	@__voteItems = {}

	gameevent.Listen "player_disconnect"
	hook.Add "player_disconnect", "NMW AU Meeting Disconnect", (data) ->
		if not IsValid @
			hook.Remove "player_disconnect", "NMW AU Meeting Disconnect"
			return

		entity = Player data.userid

		if IsValid entity
			playerTable = entity\GetAUPlayerTable!
			voteItem = playerTable and @__voteItems[playerTable.id]

			if IsValid voteItem
				voteItem\SetEnabled false
				voteItem\SetDark true

meeting.Close = => with @
	@AlphaTo 0, 0.25, 0, ->
		@Remove!

meeting.OnRemove = =>
	gui.EnableScreenClicker false

return vgui.RegisterTable meeting, "Panel"
