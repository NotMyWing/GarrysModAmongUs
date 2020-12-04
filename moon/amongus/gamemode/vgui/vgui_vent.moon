TRANSLATE = GM.Lang.GetEntry

surface.CreateFont "NMW AU Vent Text", {
	font: "Roboto"
	size: ScrW! * 0.014
	weight: 550
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
		with item = @Add "Panel"
			\SetTall size
			\DockMargin 0, size * 0.1, 0, 0
			\Dock TOP

			with button = \Add "DImage"
				\Dock RIGHT
				\SetWide size
				\SetMaterial ASSETS.button

				with \Add "DOutlinedLabel"
					\Dock FILL

					\SetFont "NMW AU Vent Text"
					\SetColor Color 255, 255, 255
					\SetText i
					\SetContentAlignment 5

			labelAspect = if texture = ASSETS.label\GetTexture "$basetexture"
				texture\GetMappingWidth! / texture\GetMappingHeight!
			else
				0

			with label = \Add "DImage"
				\Dock RIGHT
				\DockMargin 0, 0, size * 0.1, 0
				\SetSize size * labelAspect, size
				\SetMaterial ASSETS.label

				with \Add "DOutlinedLabel"
					\Dock FILL

					\SetFont "NMW AU Vent Text"
					\SetColor Color 255, 255, 255
					\SetText tostring TRANSLATE vent
					\SetContentAlignment 5
vent.Think = =>
	if not GAMEMODE or not GAMEMODE.GameData.Vented
		@Remove!

return vgui.RegisterTable vent, "Panel"
