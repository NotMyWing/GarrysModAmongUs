with GM
	.GameData or= {}

	with .GameData
		.Lookup_PlayerByID     or= {}
		.Lookup_PlayerByEntity or= {}
		
		.PlayerTables or= {}
		.DeadPlayers  or= {}
		.Imposters    or= {}

		if SERVER
			.Timers                 or= {}
			.VotesMap               or= {}
			.Votes                  or= {}
			.Vented                 or= {}
			.VentCooldown           or= {}
			.KillCooldownRemainders or= {}
			.KillCooldowns          or= {}

	.PurgeGameData = =>
		for key, dataTable in pairs @GameData
			if "table" == type dataTable
				table.Empty dataTable
			else
				@GameData[key] = nil