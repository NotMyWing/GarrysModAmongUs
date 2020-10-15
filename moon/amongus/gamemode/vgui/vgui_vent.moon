surface.CreateFont "NMW AU Vent Text", {
	font: "Arial"
	size: ScrH! * 0.03
	weight: 500
	outline: true
}

vent = {}

vent.Init = =>
	@SetZPos 30000

	offset = ScrW! * 0.025
	@DockMargin offset, offset * 4, 0, offset * 4
	@SetWide ScrW! / 5
	@Dock LEFT

ASSETS = {
	button: Material "au/gui/vent/num.png"
	label: Material "au/gui/vent/label.png"
}

labelAspect = 6/1

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
				\Dock LEFT
				.Image = ASSETS.button
				.Paint = GAMEMODE.Render.DermaFitImage

			with label = \Add "DLabel"
				\SetFont "NMW AU Vent Text"
				\SetColor Color 255, 255, 255
				\SetSize size * labelAspect, size
				\DockMargin size * 0.1, 0, 0, 0
				\SetText vent
				\SetContentAlignment 5
				\Dock LEFT
				.Image = ASSETS.label
				.Paint = GAMEMODE.Render.DermaFitImage

vent.Think = =>
	if not GAMEMODE or not GAMEMODE.GameData.Vented
		@Remove!

vent.Paint = ->

return vgui.RegisterTable vent, "DPanel"