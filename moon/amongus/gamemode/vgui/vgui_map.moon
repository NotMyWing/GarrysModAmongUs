surface.CreateFont "NMW AU Map Labels", {
	font: "Roboto"
	size: ScrH! * 0.035
	weight: 600
	outline: true
}

MAT_ASSETS = {
	close: Material "au/gui/closebutton.png", "smooth"
}

TRANSLATE = GM.Lang.GetEntryFunc

return vgui.RegisterTable {
	__color: Color 255, 255, 255
	__position: Vector 0, 0, 0
	__scale: 1
	__tracking: {}
	__labels: {}

	Init: =>
		@SetZPos 30000
		@SetSize ScrW!, ScrH!

		@__innerPanel = with @Add "DPanel"
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

						element\SetPos (pos.x - @__position.x) / (@__baseMatWidth * @__scale) * size - w/2,
							(@__position.y - pos.y) / (@__baseMatWidth * @__scale) * size - h/2
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

		size = 0.8 * math.max ScrH!, ScrW!
		w, h = GAMEMODE.Render.FitMaterial value, size, size
		with @__innerPanel
			\SetSize w, h
			\Center!

	SetPosition: (value) => @__position = value
	SetScale: (value) => @__scale = value
	SetLabels: (value) => @__labels = value

	SetupFromManifestEntry: (entry) => with entry
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

	Track: (entity, element, track = true) =>
		if IsValid(entity)
			if track
				@__tracking[entity] = element
				element\SetParent @__innerPanel
			else
				if IsValid @__tracking[entity]
					@__tracking[entity]\Remove!

				@__tracking[entity] = nil

	UnTrack: (entity) =>
		@Track entity, nil, false

	GetInnerSize: => math.min @__innerPanel\GetSize!

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
