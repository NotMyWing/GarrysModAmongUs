{
	Duration: 8
	Init: (data) =>
		@__target = data.Target

		if data.Duration
			@Duration = data.Duration

	OnStart: =>
		@Base.OnStart @

		if SERVER
			for ent in *ents.FindByName @__target
				ent\Fire "Close"

			GAMEMODE.GameData.Timers[@GetVGUIID!] = true
			timer.Create @GetVGUIID!, @Duration, 1, ->
				for ent in *ents.FindByName @__target
					ent\Fire "Open"

				GAMEMODE.GameData.Timers[@GetVGUIID!] = nil
				@End!

}
