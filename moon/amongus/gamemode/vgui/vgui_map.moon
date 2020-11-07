MAT_ASSETS = {
	close: Material "au/gui/closebutton.png", "smooth"
}

TRANSLATE = GM.Lang.GetEntry

return vgui.RegisterTable {
	__color: Color 255, 255, 255
	__position: Vector 0, 0, 0
	__scale: 1
	__tracking: {}
	__labels: {}
	__baseMatWidth: 1024
	__baseMatHeight: 1024
	__resolution: 1

	Init: =>
		@SetZPos 30000
		@SetSize ScrW!, ScrH!

		@__innerPanel = with @Add "DPanel"
			size = 0.8 * math.min ScrH!, ScrW!
			\SetSize size, size
			\Center!

			.Paint = (_, w, h) ->
				surface.SetAlphaMultiplier 0.85

				if @__outlineMat
					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial @__outlineMat
					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC
					surface.DrawTexturedRect 0, 0, w, h
					render.PopFilterMag!
					render.PopFilterMin!

				surface.SetAlphaMultiplier 0.925 + 0.05 * math.sin SysTime! * 2.5

				if @__baseMat
					surface.SetDrawColor @__color
					surface.SetMaterial @__baseMat
					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC
					surface.DrawTexturedRect 0, 0, w, h
					render.PopFilterMag!
					render.PopFilterMin!

				surface.SetAlphaMultiplier 0.95
				for label in *@__labels
					size = math.max w, h
					x = label.Position.x * size
					y = label.Position.y * size

					draw.SimpleText tostring(TRANSLATE(label.Text)), "NMW AU Map Labels", x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

				surface.SetAlphaMultiplier 1

			.Think = ->
				size = math.max \GetSize!

				for entity, element in pairs @__tracking
					if IsValid(entity) and IsValid(element)
						pos = entity\GetPos!
						w, h = element\GetSize!

						element\SetPos (pos.x - @__position.x) / (@__baseMatWidth * @__scale) * size * @__resolution - w/2,
							(@__position.y - pos.y) / (@__baseMatWidth * @__scale) * size * @__resolution - h/2
					else
						@UnTrack entity

		@NewAnimation 0, 0, 0, ->
			with @Add "DImageButton"
				\SetText ""
				\SetMaterial MAT_ASSETS.close
				\SetSize ScrH! * 0.09, ScrH! * 0.09

				x, y = @__innerPanel\GetPos!
				x -= ScrH! * 0.11
				\SetPos x, y

				.DoClick = ->
					@Close!

	SetColor: (value) => @__color = value
	SetBackgroundMaterial: (value) => @__outlineMat = value
	SetOverlayMaterial: (value) =>
		@__baseMat = value
		@__baseMatWidth, @__baseMatHeight = if texture = value\GetTexture "$basetexture"
			texture\GetMappingWidth!, texture\GetMappingHeight!
		else
			1, 1

		w, h = GAMEMODE.Render.FitMaterial value, 0.8 * ScrW!, 0.8 * ScrH!
		with @__innerPanel
			\SetSize w, h
			\Center!

	SetPosition: (value) => @__position = value
	SetScale: (value) =>
		@__scale = value
		surface.CreateFont "NMW AU Map Labels", {
			font: "Roboto"
			size: 0.03 * math.min ScrW!, ScrH!
			weight: 600
			outline: true
		}

	SetResolution: (value) => @__resolution = value

	SetLabels: (value) => @__labels = value

	SetupFromManifest: (manifest) =>
		if manifest.Map
			with map = manifest.Map.UI or manifest.Map
				if .OverlayMaterial
					@SetOverlayMaterial .OverlayMaterial

				if .BackgroundMaterial
					@SetBackgroundMaterial .BackgroundMaterial

				if .Scale
					@SetScale .Scale

				if .Position
					@SetPosition .Position

				if .Labels
					@SetLabels .Labels

				if .Resolution
					@SetResolution .Resolution

		if manifest.Sabotages
			with @sabotageOverlay = @__innerPanel\Add "DPanel"
				w, h = @__innerPanel\GetSize!
				\SetSize w, h
				\SetZPos 30000
				\Hide!
				.Paint = ->

				buttonSize = 0.085 * math.min w, h
				for id, sabotage in ipairs manifest.Sabotages
					if sabotage.UI
						with \Add "DImageButton"
							\SetMaterial sabotage.UI.Icon
							\SetSize buttonSize, buttonSize
							\SetPos w * sabotage.UI.Position.x - buttonSize/2, h * sabotage.UI.Position.y - buttonSize/2
							.DoClick = ->
								GAMEMODE\Net_SabotageRequest id

							.Think = ->
								instance = GAMEMODE.GameData.Sabotages[id]

								if instance
									enabled = \IsEnabled!
									canSetOff = not GAMEMODE\IsMeetingInProgress! and
										not GAMEMODE.UseHighlight and
										not GAMEMODE.GameData.Vented and
										instance\CanStart!

									if enabled and not canSetOff
										\SetEnabled false
									elseif not enabled and canSetOff
										\SetEnabled true

							with \Add "DLabel"
								\Dock FILL
								\SetContentAlignment 5
								\SetText "..."
								\SetFont "NMW AU Map Labels"
								\SetColor Color 255, 255, 255
								.Think = ->
									instance = GAMEMODE.GameData.Sabotages[id]
									if instance
										if instance\GetActive!
											\SetText "!"
										else
											time = if instance\GetCooldownOverride! ~= 0
												instance\GetCooldownOverride!
											else
												instance\GetNextUse! - CurTime!

											if not instance\GetDisabled! and time > 0
												\SetText math.floor time
											else
												\SetText ""

	Track: (entity, element, track = true) =>
		if IsValid entity
			if track
				@__tracking[entity] = element
				element\SetParent @__innerPanel
			else
				if IsValid @__tracking[entity]
					@__tracking[entity]\Remove!

				@__tracking[entity] = nil
		elseif IsValid element
			element\Remove!

	UnTrack: (entity) =>
		@Track entity, nil, false

	Popup: =>
		if @__opened or @__opening or @__closing
			return

		@__opened = true
		@__opening = true

		@MakePopup!
		@SetKeyboardInputEnabled false

		@SetPos 0, ScrH!
		@MoveTo 0, 0, 0.2, nil, nil, ->
			@__opening = false

		@SetAlpha 0
		@AlphaTo 255, 0.1, 0.01

		surface.PlaySound "au/panel_genericappear.wav"

	EnableSabotageOverlay: =>
		if IsValid @sabotageOverlay
			@sabotageOverlay\Show!

	Close: =>
		if not @__opened or @__opening or @__closing
			return

		@__opened = false
		@__closing = true

		@AlphaTo 0, 0.1
		@MoveTo 0, ScrH!, 0.1, 0, -1, ->
			@__closing = false
			surface.PlaySound "au/panel_genericdisappear.wav"
			@SetMouseInputEnabled false

	Paint: =>

}, "DPanel"
