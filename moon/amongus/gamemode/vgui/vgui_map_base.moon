MAT_ASSETS = {
	close: Material "au/gui/closebutton.png", "smooth"
}

TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Map Labels", {
	font: "Roboto"
	size: 0.03 * math.min ScrW!, ScrH!
	weight: 600
	outline: true
}

map = {
	__baseMatWidth: 0
	__baseMatHeight: 0
	__color: Color 255, 255, 255
	__position: Vector 0, 0, 0
	__scale: 1
	__labels: {}
	__overlayMatWidth: 1024
	__overlayMatHeight: 1024
	__resolution: 1

	Init: =>
		@SetZPos 30000
		@SetSize ScrW!, ScrH!

		@__innerPanel = with @Add "DPanel"
			size = 0.8 * math.min ScrH!, ScrW!
			\SetSize size, size
			\Center!

			white = Color 255, 255, 255

			.Paint = (_, w, h) ->
				shouldFilter = @__baseMat or @__overlayMat

				if shouldFilter
					render.PushFilterMag TEXFILTER.ANISOTROPIC
					render.PushFilterMin TEXFILTER.ANISOTROPIC

				if @__baseMat
					surface.SetAlphaMultiplier 0.85
					surface.SetDrawColor 255, 255, 255
					surface.SetMaterial @__baseMat
					surface.DrawTexturedRect 0, 0, w, h

				if @__overlayMat
					surface.SetAlphaMultiplier 0.925 + 0.05 * math.sin SysTime! * 2.5
					surface.SetDrawColor @__color
					surface.SetMaterial @__overlayMat
					surface.DrawTexturedRect 0, 0, w, h

				if shouldFilter
					render.PopFilterMag!
					render.PopFilterMin!

				surface.SetAlphaMultiplier 0.95
				for label in *@__labels
					x = label.Position.x * w
					y = label.Position.y * h

					draw.SimpleText tostring(TRANSLATE(label.Text)), "NMW AU Map Labels", x, y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

				surface.SetAlphaMultiplier 1

		@__closeButton = with @Add "DImageButton"
			\SetText ""
			\SetMaterial MAT_ASSETS.close
			\SetSize ScrH! * 0.09, ScrH! * 0.09

			x, y = @__innerPanel\GetPos!
			\SetPos x - \GetWide! * 1.1, y

			.DoClick = ->
				@Close!

	GetInnerPanel: => @__innerPanel
	GetCloseButton: => @__closeButton

	SetColor: (value) => @__color = value
	GetColor: => @__color

	SetBackgroundMaterial: (value) =>
		@__baseMatWidth, @__baseMatHeight = if texture = value\GetTexture "$basetexture"
			texture\GetMappingWidth!, texture\GetMappingHeight!
		else
			0, 0

		w, h = GAMEMODE.Render.FitMaterial value, 0.8 * ScrW!, 0.8 * ScrH!
		with @__innerPanel
			\SetSize w, h
			\Center!

			x, y = @__innerPanel\GetPos!
			with @__closeButton
				\SetPos x - \GetWide! * 1.1, y

		@__baseMat = value

	GetBackgroundMaterial: => @__baseMat
	GetBackgroundMaterialSize: => @__baseMatWidth, @__baseMatHeight

	SetOverlayMaterial: (value) => @__overlayMat = value
	GetOverlayMaterial: => @__overlayMat

	SetPosition: (value) => @__position = value
	GetPosition: => @__position

	SetScale: (value) => @__scale = value
	GetScale: => @__scale

	SetResolution: (value) => @__resolution = value
	GetResolution: => @__resolution

	SetLabels: (value) => @__labels = value
	GetLabels: => @__labels

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

			if @OnOpen
				@OnOpen!

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

			if @OnClose
				@OnClose!

	Paint: =>

}

vgui.Register "AmongUsMapBase", map, "DPanel"
