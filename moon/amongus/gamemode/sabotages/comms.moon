comms = {
	Init: (data) =>
		@Base.Init @, data

		if SERVER
			@SetMajor true
			@SetPersistent true

	OnStart: =>
		@Base.OnStart @
		if SERVER
			GAMEMODE\SetCommunicationsDisabled true

			local btn
			for ent in *ents.GetAll!
				if ent.GetSabotageName and ent\GetSabotageName! == @GetHandler!
					btn = ent
					break

			if btn
				@SetActivationButtons btn

	OnButtonUse: (playerTable, button) =>
		if SERVER
			GAMEMODE\Sabotage_OpenVGUI playerTable, @, button

	OnSubmit: =>
		@End!

	OnEnd: =>
		@Base.OnEnd @
		if SERVER
			GAMEMODE\SetCommunicationsDisabled false
			@SetActivationButtons!
}

if CLIENT
	with comms
		.CreateVGUI = =>
			base = vgui.Create "AmongUsSabotageBase"

			with base
				\SetSabotage @
				\Setup with vgui.Create "Panel"
					max_size = ScrH! * 0.7

					\SetSize max_size, max_size * 0.55

					\SetBackgroundColor Color 64, 64, 64
					with \Add "DButton"
						margin = ScrH! * 0.01
						\DockMargin margin * 4, 0, margin * 4, margin * 4
						\SetTall ScrH! * 0.05
						\SetFont "NMW AU PlaceholderText"
						\Dock BOTTOM
						\SetText "Submit"
						.DoClick = ->
							base\Submit!
				\Popup!

			return base

return comms
