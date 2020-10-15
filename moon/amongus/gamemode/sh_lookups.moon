with GM
	.GameData or= {}

	with .GameData
		.KillCooldownRemainders or= {}
		.ActivePlayersMapId or= {}
		.ActivePlayersMap or= {}
		.ActivePlayers or= {}
		.KillCooldowns or= {}
		.DeadPlayers or= {}
		.Imposters or= {}

		if SERVER
			.Timers or= {}
			.VotesMap or= {}
			.Votes or= {}
			.Vented or= {}
			.VentCooldown or= {}

	.PurgeGameData = =>
		for key, dataTable in pairs @GameData
			if "table" == type dataTable
				table.Empty dataTable
			else
				@GameData[key] = nil