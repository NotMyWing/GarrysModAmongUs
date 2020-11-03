TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Vent Text", {
	font: "Roboto"
	size: ScrW! * 0.017
	weight: 500
	outline: true
}

vent = {}

vent.Init = =>
	@SetZPos 30000

	offset = ScrW! * 0.025
	@SetSize ScrW! / 4, ScrH!
	@SetPos ScrW! - offset - @GetWide!, offset * 4

ASSETS = {
	button: Material "au/gui/vent/num.png"
	label: Material "au/gui/vent/label.png"
}

vent.ShowVents = (vents) =>
	size = ScrW! * 0.025
	for i, vent in ipairs vents
		with item = @Add "DPanel"
			\SetTall size
			\DockMargin 0, size * 0.1, 0, 0
			\Dock TOP
			.Paint = ->

			with button = \Add "DLabel"
				\SetFont "NMW AU Vent Text"
				\SetColor Color 255, 255, 255
				\SetText i
				\SetContentAlignment 5
				\SetWide size
				\Dock RIGHT
				.Image = ASSETS.button
				.Paint = GAMEMODE.Render.DermaFitImage

			labelAspect = if texture = ASSETS.label\GetTexture "$basetexture"
				texture\GetMappingWidth! / texture\GetMappingHeight!
			else
				0

			with label = \Add "DLabel"
				\SetFont "NMW AU Vent Text"
				\SetColor Color 255, 255, 255
				\SetSize size * labelAspect, size
				\DockMargin 0, 0, size * 0.1, 0
				\SetText tostring TRANSLATE vent
				\SetContentAlignment 5
				\Dock RIGHT
				.Image = ASSETS.label
				.Paint = GAMEMODE.Render.DermaFitImage

vent.Think = =>
	if not GAMEMODE or not GAMEMODE.GameData.Vented
		@Remove!

vent.Paint = ->

return vgui.RegisterTable vent, "DPanel"
