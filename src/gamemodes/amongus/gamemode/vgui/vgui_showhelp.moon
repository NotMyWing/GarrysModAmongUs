MAT_ASSETS = {
	close: Material "au/gui/closebutton.png", "smooth"
	floatingButton: Material "au/gui/floatingbutton.png", "smooth"
}

TRANSLATE = GM.Lang.GetEntry

return vgui.RegisterTable {
	Init: =>
		-- Hide the panel by default.
		@SetAlpha 0

		closeButtonSize = ScrH! * 0.09
		maxSize = 0.8 * math.min ScrW!, ScrH!

		-- Pad the panel on both sides to center it properly later.
		@SetSize maxSize + closeButtonSize * 2, maxSize * 0.8

		with closeButtonContainer = @Add "Panel"
			\SetWide closeButtonSize
			\Dock LEFT

			@__closeButton = with \Add "DImageButton"
				\SetSize closeButtonSize, closeButtonSize
				\Dock TOP

				\SetText ""
				\SetMaterial MAT_ASSETS.close

				.DoClick = ->
					@Hide!

		cornerRadiusBase = maxSize * 0.008

		buttonHeight = (90  / 1000) * maxSize

		-- Create default font for the rest of the code to use,
		-- based on the preferred button height.
		surface.CreateFont "NMW AU ShowHelp Common", {
			font: "Roboto"
			size: buttonHeight * 0.45
			weight: 550
			outline: true
			antialias: false
		}

		-- Create the tab list.
		-- The list of many tabs.
		local tabList
		tabList = with @Add "Panel"
			-- Set up the visuals.
			outerColor = Color 32, 48, 48
			innerColor = Color 170, 200, 170
			borderPadding = maxSize * 0.005
			.Paint = (_, w, h) ->
				-- Outer, (black) outline.
				draw.RoundedBox cornerRadiusBase, 0, 0, w, h, outerColor

				-- Inner, background.
				draw.RoundedBox cornerRadiusBase, borderPadding, borderPadding,
					w - borderPadding * 2, h - borderPadding * 2, innerColor

			tabListPadding     = (20 / 1000) * maxSize
			buttonListPadding  = (24 / 1000) * maxSize
			buttonMarginRight  = (9  / 1000) * maxSize

			\DockPadding tabListPadding, tabListPadding,
				tabListPadding, tabListPadding

			\SetWide maxSize
			\Dock LEFT

			buttonList = with \Add "Panel"
				\SetTall buttonHeight
				\Dock TOP
				\DockPadding 0, 0, 0, buttonListPadding
			.GetButtonList = -> buttonList

			tabContainer = with \Add "Panel"
				\Dock FILL
			.GetTabContainer = -> tabContainer

			buttonSelColor = Color 80, 100, 80
			buttonColor    = Color 130, 160, 140
			buttonWidth    = (180 / 1000) * maxSize

			tabs = {}
			currentTab   = nil
			isFirstPanel = true

			-- Switches to a tab.
			.SwitchTo = (_, name) ->
				return if name == currentTab

				if IsValid tabs[currentTab]
					tabs[currentTab]\Hide!

				currentTab = name
				if IsValid tabs[name]
					tabs[name]\Show!

			-- Adds a new tab.
			-- This is very similar to DPropertySheet:AddSheet, but not quite it.
			.AddTab = (_, name, panel) ->
				with buttonList\Add "DButton"
					\Dock LEFT
					\DockMargin 0, 0, buttonMarginRight, 0
					\SetWide buttonWidth

					\SetText tostring TRANSLATE "help.tab.#{name}"
					\SetFont "NMW AU ShowHelp Common"
					\SetContentAlignment 5
					\SetColor Color 255, 255, 255

					depressed = false
					.OnDepressed = -> depressed = true
					.OnReleased  = -> depressed = false

					depressedPadding = buttonWidth * 0.02

					-- yuge
					.Paint = (_, w, h) -> draw.RoundedBox cornerRadiusBase,
						depressed and depressedPadding or 0           , depressed and depressedPadding or 0           ,
						depressed and (w - depressedPadding * 2) or w , depressed and (h - depressedPadding * 2) or h ,
						currentTab == name and buttonSelColor or buttonColor

					.DoClick = ->
						tabList\SwitchTo name

				tabs[name] = panel

				if IsValid panel
					panel\SetParent tabContainer
					panel\Hide!

					if isFirstPanel
						isFirstPanel = false
						tabList\SwitchTo name

		@InvalidateLayout!

		-- This is literal fucking cancer.
		-- Is there seriously no other way to wait until everything is docked???
		@NewAnimation 0, 0, 0, -> @NewAnimation 0, 0, 0, ->
			tabContainer = tabList\GetTabContainer!

			separatorWidth = (35 / 1000) * maxSize
			modelViewWidth = tabContainer\GetWide! / 2 - separatorWidth / 2

			-- Setup the modelview.
			-- While it's currently used in one tab, this will change later.
			-- Customization and pets tabs both use the same panel, so why have
			-- multiple instances?
			modelView = with vgui.Create "DModelPanel"
				\SetWide modelViewWidth
				\Hide!

				\SetModel LocalPlayer!\GetModel!
				\SetFOV 50

				with \GetEntity!
					.GetPlayerColor = ->
						preferred = math.floor math.max 1, LocalPlayer!\GetInfoNum "au_preferred_color", 1

						(GAMEMODE.Colors[preferred] or GAMEMODE.Colors[1])\ToVector!

			-- Create a common function for drawing panel backgrounds.
			-- It doesn't make sense to keep copying this code over and over again.
			innerPanelColor = Color 120, 140, 120
			roundedPaint = (w, h) =>
				draw.RoundedBox cornerRadiusBase, 0, 0, w, h, innerPanelColor

			------------------
			--  COLORS TAB  --
			------------------
			tabList\AddTab "color", with vgui.Create "Panel"
				\Dock FILL

				modelViewContainer = with \Add "Panel"
					\SetWide modelViewWidth
					\Dock LEFT
					.Paint = roundedPaint

				-- Detour :Show to allow us to re-parent the model view.
				-- :Show is guaranteed to be called when switching tabs.
				oldShow = .Show
				.Show = =>
					oldShow @
					with modelView
						\Show!
						\SetParent modelViewContainer
						\Dock LEFT

				-- Create a list of all colors for the player to choose from.
				with \Add "DScrollPanel"
					\SetWide modelViewWidth
					\DockMargin separatorWidth, 0, 0, 0
					\Dock RIGHT
					.Paint = roundedPaint

					with \Add "DIconLayout"
						\Dock FILL
						\SetBorder modelViewWidth * 0.0425
						\SetSpaceX modelViewWidth * 0.0425
						\SetSpaceY modelViewWidth * 0.0425

						selected = nil
						preferred = LocalPlayer!\GetInfoNum "au_preferred_color", 0
						for i, color in ipairs GAMEMODE.Colors
							with container = \Add "DPanel"
								\SetBackgroundColor Color 32, 32, 32
								\SetSize modelViewWidth * 0.25, modelViewWidth * 0.25

								pad = modelViewWidth * 0.01
								\DockPadding pad, pad, pad, pad
								with \Add "DPanel"
									\Dock FILL
									\SetBackgroundColor color

									\DockPadding pad, pad, pad, pad
									container.img = with \Add "DImage"
										\Dock FILL
										\SetMaterial MAT_ASSETS.close
										\SetAlpha 64
										\Hide!

								-- Hidden button overlay.
								btn = with \Add "DButton"
									\SetText ""
									\Dock FILL
									.Paint = ->
									.DoClick = (_, dry = false) ->
										if IsValid selected
											selected.img\Hide!

										container.img\Show!
										if false == dry
											GetConVar("au_preferred_color")\SetInt i
											GAMEMODE\Net_UpdateMyColor!

										selected = container

								if preferred == i
									btn\DoClick true

				\InvalidateChildren!
				\InvalidateLayout!

			--------------------
			--  SETTINGS TAB  --
			--------------------
			tabList\AddTab "settings", with vgui.Create "DScrollPanel"
				\Dock FILL
				.Paint = roundedPaint

				\GetCanvas!\DockPadding separatorWidth, separatorWidth,
					separatorWidth, separatorWidth

				with \GetCanvas!
					cvars = { "au_spectator_mode", "au_debug_drawversion" }
					for cvar in *cvars
						with \Add "DCheckBoxLabel"
							\Dock TOP
							\SetConVar cvar
							\SetText tostring TRANSLATE "help.settings.#{cvar}"
							\SetFont "NMW AU ShowHelp Common"
							\SetTextColor Color 255, 255, 255

			-----------------------
			--  GAME CONVAR TAB  --
			-----------------------
			tabList\AddTab "game", with vgui.Create "DScrollPanel"
				\Dock FILL
				.Paint = roundedPaint

				entryColor  = Color 255, 255, 255, 64
				entryHeight = (50  / 1000) * maxSize
				buttonSelColor = Color 90, 255, 90
				buttonColor    = Color 130, 160, 140

				white = Color 255, 255, 255
				green = Color 32, 255, 32

				surface.CreateFont "NMW AU ShowHelp NumberWang", {
					font: "Roboto"
					size: entryHeight * 0.45
					weight: 550
				}

				with \GetCanvas!
					padding = separatorWidth * 0.25
					\DockPadding padding * 15, padding,
						padding * 15, padding

				-- Re-create this depending on the player's admin rights
				local oldAdmin
				oldShow = .Show
				.Show = (this) ->
					oldShow this

					-- The entirety of this section is not yet implemented.
					return if oldAdmin

					newAdmin = CAMI.PlayerHasAccess LocalPlayer!, GAMEMODE.PRIV_CHANGE_SETTINGS
					return if newAdmin == oldAdmin
					oldAdmin = newAdmin

					with \GetCanvas!
						\Clear!

						for categoryId, category in ipairs GAMEMODE.ConVarsDisplay
							with \Add "Panel"
								\Dock TOP
								\DockMargin 0, entryHeight * 0.25, 0, entryHeight

								\NewAnimation 0, 0, 0, ->
									\InvalidateLayout!
									\NewAnimation 0, 0, 0, ->
										\SizeToChildren false, true

								for conVarTable in *category.ConVars
									type   = conVarTable[1]
									conVar = GAMEMODE.ConVars[conVarTable[2]]

									conVarName = conVar\GetName!

									with \Add "DLabel"
										\Dock TOP
										\DockMargin 0, 0, 0, entryHeight * 0.2
										\SetTall entryHeight

										\SetColor Color 255, 255, 255
										\SetText "   " .. tostring TRANSLATE "cvar.#{conVarName}"
										\SetFont "NMW AU ShowHelp Common"
										\SetContentAlignment 4

										\SetMouseInputEnabled true
										\SetKeyboardInputEnabled true

										.Paint = (_, w, h) ->
											draw.RoundedBox cornerRadiusBase * 1.5, 0, 0, w, h, entryColor

										element = if CAMI.PlayerHasAccess LocalPlayer!, GAMEMODE.PRIV_CHANGE_SETTINGS
											-- Show the admin stuffs to admins.
											switch type
												when "Int", "Time", "Mod"
													with \Add "DNumberWang"
														\SetConVar conVarName
														\SetMin conVar\GetMin! or 0
														\SetMax conVar\GetMax! or 100
														\SetValue conVar\GetInt!
														\SetFont "NMW AU ShowHelp NumberWang"

														if type == "Mod"
															\SetInterval 0.25

												when "Bool"
													with \Add "DCheckBox"
														\SetConVar conVarName

														depressed = false
														.OnDepressed = -> depressed = true
														.OnReleased  = -> 
															depressed = false
															if conVarName == "sv_alltalk"
																-- sending value here to server because sv_alltalk doesn't callback on client (https://github.com/Facepunch/garrysmod-issues/issues/3503)
																net.Start "AU ChangeCvar"
																net.WriteString conVarName
																net.WriteString \GetChecked() and "0" or "1"
																net.SendToServer!

														.Paint = (_, w, h) ->
															depressedPadding = w * 0.025
															draw.RoundedBox cornerRadiusBase * 0.75,
																depressed and depressedPadding or 0           , depressed and depressedPadding or 0           ,
																depressed and (w - depressedPadding * 2) or w , depressed and (h - depressedPadding * 2) or h ,
																conVar\GetBool! and buttonSelColor or buttonColor
												when "Select"
													with \Add "DComboBox"
														\SetConVar conVarName
														\SetFont "NMW AU ShowHelp NumberWang"

														for i = conVar\GetMin!, conVar\GetMax!, 1
															\AddChoice TRANSLATE("hud.cvar.#{conVarName}.#{i}")!, i

														.OnSelect = (_, i, v, d) ->
															RunConsoleCommand conVarName, d
										else
											-- Show the non-admin stuffs to non-admins.
											with \Add "Panel"
												.Paint = (_, w, h) ->
													inProgress = (GAMEMODE\IsGameCommencing! or GAMEMODE\IsGameInProgress!)
													conVars = inProgress and
														GAMEMODE.ConVarSnapshots or GAMEMODE.ConVars

													conVar = conVars[conVarTable[2]]

													value = switch type
														when "Int"
															conVar\GetInt!
														when "Time"
															TRANSLATE("hud.cvar.time") conVar\GetInt!
														when "String"
															conVar\GetString!
														when "Bool"
															conVar\GetBool! and TRANSLATE("hud.cvar.enabled") or TRANSLATE("hud.cvar.disabled")
														when "Mod"
															"#{conVar\GetFloat!}x"
														when "Select"
															TRANSLATE("hud.cvar.#{conVarName}.#{conVar\GetInt!}")

													if value
														draw.SimpleText value, "NMW AU ShowHelp Common",
															w/2, h/2, inProgress and green or white,
															TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

										if IsValid element
											element\DockMargin 0, entryHeight * 0.2,
												entryHeight * 0.25, entryHeight * 0.2
											element\Dock RIGHT
											element\SetWide entryHeight * 3

			--------------------
			--  CONTROLS TAB  --
			--------------------
			tabList\AddTab "controls", with vgui.Create "DScrollPanel"
				\Dock FILL
				.Paint = roundedPaint

				\GetCanvas!\DockPadding separatorWidth, separatorWidth,
					separatorWidth, separatorWidth

				controls = {
					"+showscores": "map"
					"+menu": "kill"
					"+use": "use"
					"+reload": "report"
					"gmod_undo": "hideTasks"
					"noclip": "toggleNoClip"
					"gm_showhelp": "showHelp"
				}

				oldShow = .Show
				.Show = (this) ->
					oldShow this

					with \GetCanvas!
						\Clear!

						for key, description in pairs controls
							with \Add "Panel"
								\SetTall buttonHeight
								\Dock TOP
								\DockMargin 0, 0, 0, buttonHeight * 0.15

								pad = buttonHeight * 0.05
								\DockPadding pad, pad, pad, pad

								entryColor  = Color 255, 255, 255, 64
								.Paint = (_, w, h) ->
									draw.RoundedBox cornerRadiusBase * 1.5, 0, 0, w, h, entryColor

								with \Add "DImage"
									\Dock LEFT
									\SetWide buttonHeight - pad * 2
									\SetMaterial MAT_ASSETS.floatingButton

									with \Add "DLabel"
										\Dock FILL
										\DockMargin 0, 0, 0, buttonHeight * 0.28

										\SetFont "NMW AU ShowHelp Common"
										\SetColor Color 255, 255, 255
										\SetContentAlignment 5

										\SetText string.upper input.LookupBinding(key) or "???"

								with \Add "DLabel"
									\Dock FILL
									\DockMargin buttonHeight * 0.15, 0, 0, 0

									\SetFont "NMW AU ShowHelp Common"
									\SetColor Color 255, 255, 255
									\SetContentAlignment 4

									translatedDescription = tostring TRANSLATE "help.controls.#{description}"
									\SetText "#{translatedDescription} (#{key})"

			-------------------
			--  CREDITS TAB  --
			-------------------
			tabList\AddTab "about", with vgui.Create "DScrollPanel"
				\Dock FILL
				.Paint = roundedPaint

				with \GetCanvas!
					\DockPadding separatorWidth, separatorWidth,
						separatorWidth, separatorWidth

					with \Add "DLabel"
						\Dock TOP

						\SetColor Color 255, 255, 255

						\SetFont "NMW AU ShowHelp Common"
						\SetText "Thanks for playing Among Us for Garry's Mod!\nThis game mode is brought to you by:"
						\SetContentAlignment 5
						\SetWrap true
						\SetAutoStretchVertical true

					contributorColor  = Color 255, 255, 255, 64
					contributorHeight = (50  / 1000) * maxSize

					with contributorList = \Add "Panel"
						\Dock TOP
						\DockMargin 0, contributorHeight * 0.25, 0, 0
						\DockPadding contributorHeight * 0.25, 0, tabContainer\GetWide! * 0.5, 0

						link = "https://api.github.com/repos/NotMyWing/GarrysModAmongUs/contributors"

						onFailure = (err) ->
							\AlphaTo 0, 0.5, nil, ->
								\Clear!
								\DockPadding contributorHeight * 0.25, 0, 0, 0
								\NewAnimation 0.5, 0, 0, ->
									\SizeToChildren false, true
									\InvalidateLayout!
									\AlphaTo 255, 1

								with \Add "DLabel"
									\SetColor Color 255, 4, 4
									\Dock TOP
									\DockMargin 0, 0, 0, contributorHeight * 0.2
									\SetFont "NMW AU ShowHelp Common"
									\SetText "Couldn't fetch the contributor list: #{err}"
									\SetWrap true
									\SetAutoStretchVertical true

						onSuccess = (body, size, headers, code) ->
							if code == 403
								return onFailure "Rate limit exceeded."

							result = util.JSONToTable body
							if result
								\AlphaTo 0, 0.5, nil, ->
									\Clear!
									\NewAnimation 0.5, 0, 0, ->
										\SizeToChildren false, true
										\InvalidateLayout!
										\AlphaTo 255, 1

									for contributor in *result
										with \Add "Panel"
											\SetTall contributorHeight
											\Dock TOP
											\DockMargin 0, 0, 0, contributorHeight * 0.2
											.Paint = (_, w, h) -> draw.RoundedBox cornerRadiusBase * 1.5, 0, 0, w, h, contributorColor

											with \Add "DButton"
												\Dock FILL
												\DockMargin contributorHeight * 0.5, 0, 0, 0
												\SetColor Color 255, 255, 255
												\SetText contributor.login
												\SetFont "NMW AU ShowHelp Common"
												\SetContentAlignment 4
												.Paint = ->
												.DoClick = ->
													gui.OpenURL contributor.html_url


						http.Fetch link, onSuccess, onFailure

					with \Add "DLabel"
						\Dock TOP
						\DockMargin 0, contributorHeight * 1, 0, 0

						\SetColor Color 255, 255, 255

						\SetFont "NMW AU ShowHelp Common"
						\SetText "Code is licensed under the MIT License." ..
							"\nCustom assets are licensed under CC BY-NC-SA 4.0" ..
							"\nAmong Us texture and sound assets by InnerSloth." ..
							"\n\nFor more info please visit:"

						\SetContentAlignment 5
						\SetWrap true
						\SetAutoStretchVertical true

					with \Add "Panel"
						\SetTall contributorHeight
						\Dock TOP
						\DockMargin 0, contributorHeight * 0.25, 0, contributorHeight * 0.2
						.Paint = (_, w, h) -> draw.RoundedBox cornerRadiusBase * 1.5, 0, 0, w, h, contributorColor

						with \Add "DButton"
							\Dock FILL
							\DockMargin contributorHeight * 0.5, 0, 0, 0
							\SetColor Color 255, 255, 255
							\SetText "Garry's Mod Among Us on GitHub"
							\SetFont "NMW AU ShowHelp Common"
							\SetContentAlignment 4
							.Paint = ->
							.DoClick = ->
								gui.OpenURL "https://github.com/NotMyWing/GarrysModAmongUs"

	MakePopup: =>
		@BaseClass.MakePopup @

		@Center!
		@AlphaTo 220, 0.2

	Hide: =>
		if 0 == @GetAlpha!
			@BaseClass.Hide @
		else
			@AlphaTo 0, 0.1, 0, ->
				@BaseClass.Hide @

	Paint: =>

}, "DPanel"
