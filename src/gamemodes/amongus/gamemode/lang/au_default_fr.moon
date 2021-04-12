-- French translation by Azellio

with GM.Lang\Get "fr"
	["tasks.totalCompleted"] = "TOTAL DES TÂCHES ACCOMPLIES"
	["tasks.totalCompleted.sabotaged"] = "COMMUNICATION SABOTÉES"

	["tasks.commsSabotaged"] = "Communications sabotées"
	["tasks.lightsSabotaged"] = "Réparer l'électricité (%d%%)"
	["tasks.reactorSabotaged"] = "Surchauffe de réacteurs dans %d s. (%d/%d)"
	["tasks.oxygenSabotaged"] = "Oxygène épuisé dans %d s. (%d/%d)"

	areas = {
		["cafeteria"]:      "Cafeteria"
		["upperEngine"]:   "Upper Engine"
		["reactor"]:        "Reactor"
		["lowerEngine"]:   "Lower Engine"
		["security"]:       "Security"
		["electrical"]:     "Electrical"
		["medbay"]:         "Medbay"
		["storage"]:        "Storage"
		["shields"]:        "Shields"
		["communications"]: "Communications"
		["navigation"]:     "Navigation"
		["o2"]:             "O2"
		["admin"]:          "Admin"
		["weapons"]:        "Weapons"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "Divert Power to #{areaName}"
		["vent.#{area}"] = "Vent to #{areaName}"

	taskNames = {
		"divertPower": "Dévier l'énergie"
		"alignEngineOutput": "Aligner la sortie du moteur"
		"calibrateDistributor": "Calibrer le moteur"
		"chartCourse": "Régler le pilote automatique"
		"cleanO2Filter": "Nettoyer le filtre O2"
		"clearAsteroids": "Détruire les astéroïdes"
		"emptyGarbage": "Vider les déchets"
		"emptyChute": "Vider les conteneurs"
		"fixWiring": "Réparer les câbles"
		"inspectSample": "Inspecter les échantillons"
		"primeShields": "Réactiver les boucliers"
		"stabilizeSteering": "Stabiliser la direction"
		"startReactor": "Démarrer le réacteur"
		"submitScan": "Effectuer un scan"
		"swipeCard": "Glisser la carte"
		"unlockManifolds": "Débloquer les collecteurs"
		"uploadData": "Télécharger les données"
		"uploadData.2": "Uploader les données"
		"fuelEngines": "Remplir les moteurs"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "L'équipage doit attendre"
		}, {
			text: string.format "%ds", time
			color: Color 255, 0, 0
		}, {
			text: "avant l'urgence"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "Le membre %s a", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "bouton d'urgence restant"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "LE BOUTON D'URGENCE NE PEUT PAS"
		}, {
			text: "ÊTRE ACTIVÉE PENDANT UNE CRISE"
		}
	}

	["task.clearAsteroids.destroyed"] = "Détruit: %d"

	["eject.remaining"] = (remaining) ->
		if remaining == 1
			string.format "1 Imposteur restant."
		else
			string.format "%d Imposteurs restant.", remaining

	["eject.reason.tie"]     = "Personne n'a été éjecté. (égalité)"
	["eject.reason.skipped"] = "Personne n'a été éjecté. (passé)"
	["eject.reason.generic"] = "Personne n'a été éjecté."

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				if total == 1
					"%s était L'Imposteur."
				else
					"%s était un imposteur."
			else
				if total == 1
					"%s était pas L'Imposteur."
				else
					"%s n'était pas un imposteur."
		else
			"%s a été éjecté."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "Début du vote dans: %ds", time
	["meeting.timer.ends"]       = (time) -> string.format "Fin du vote dans: %ds", time
	["meeting.timer.proceeding"] = (time) -> string.format "Verdict dans: %ds", time
	["meeting.header"] = "Qui est l'imposteur ?"

	["splash.victory"] = "Victoire"
	["splash.defeat"]  = "Défaite"
	["splash.imposter"]  = "Imposteur"
	["splash.spectator"] = "Spectateur"
	["splash.crewmate"]  = "Équipage"
	["splash.text"] = (isPlaying, imposterCount) ->
		amongSubtext = isPlaying and "nous" or "eux"

		return if imposterCount == 1
			"Il y a %s Imposteur parmi " .. amongSubtext
		else
			"Il y a %s Imposteurs parmi " .. amongSubtext

	["hud.sabotageAndKill"] = "Sabotage and kill everyone."
	["hud.countdown"] = "Lancement dans %d"
	["hud.tasks"] = "Taches:"
	["hud.fakeTasks"] = "Fausses taches:"
	["hud.taskComplete"] = "Tâche terminée!"
	["hud.cvar.disabled"] = "Désactivé"
	["hud.cvar.enabled"] = "Activé"
	["hud.cvar.time"] = "%d s."

	["hud.cvar.au_taskbar_updates.0"] = "Toujours"
	["hud.cvar.au_taskbar_updates.1"] = "Réunion"
	["hud.cvar.au_taskbar_updates.2"] = "Jamais"

	cvars = {
		au_max_imposters:    "Max. Imposteurs"
		au_kill_cooldown:    "Délais de meurtre"
		au_time_limit:       "Limite de temps"
		au_killdistance_mod: "Distance de meurtre"
		sv_alltalk:          "Parler pendant la partie"
		au_taskbar_updates:  "Mise à jour de la barre des taches"
		au_player_speed_mod: "Vitesse des joueurs"

		au_meeting_available: "Bouton d'urgence par joueur"
		au_meeting_cooldown:  "Délais du bouton d'urgence"
		au_meeting_vote_time: "Temps de vote"
		au_meeting_vote_pre_time:  "Temps avant vote"
		au_meeting_vote_post_time: "Temps aprés vote"
		au_confirm_ejects:         "Confirmer les éjections"
		au_meeting_anonymous: "Vote anonyme"

		au_tasks_short:  "Taches courte"
		au_tasks_long:   "Tache longue"
		au_tasks_common: "Tache commune"
		au_tasks_enable_visual: "Tache visuelle"
	}

	for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vote.voted"] = "%s a voté. %s restant."

	["prepare.admin"] = "Vous êtes staff !"
	["prepare.spectator"] = "Vous êtes spectateur."
	["prepare.pressToStart"] = "Appuyer sur [%s] pour lancer la game."

	["prepare.invalidMap"] = "Map invalide!"
	["prepare.invalidMap.subText"] = "No map manifest file found."

	["prepare.warmup"] = "Temps de préparation!"
	["prepare.waitingForPlayers"] = "En attente de joueurs..."
	["prepare.waitingForAdmin"] = "En attente qu'un admin commence le jeu."
	["prepare.commencing"] = "La partie commence dans %d s."
	["prepare.imposterCount"] = (count) ->
		string.format (if count == 1
			"%d Imposteur"
		else
			"%d Imposteurs"), count

	["connected.spectating"] = "%s a rejoint en tant que spectateur."
	["connected.spawned"] = "%s est prêt à jouer."
	["connected.disconnected"] = "%s a quitter la partie!"

	["chat.noTalkingDuringGame"] = "Tu ne peux pas parler pendant la partie!"

	inspectSample = {
		eta:           "ETA %d."
		addingReagent: "AJOUT D'UN RÉACTIF."
		oneMore:       "1 ENCORE."
		testComplete:  "TEST COMPLET."
		pressToStart:  "APPUYER POUR COMMENCER  -->"
		selectAnomaly: "SÉLECTIONNER L'ANOMALIE."
		hello:         "BONJOUR."
		badResult:     "MAUVAIS RÉSULTAT."
		thankYou:      "MERCI!"
		randomText: table.Random {
			"VOUS N'AVEZ PAS BESOIN D'ATTENDRE."
			"ALLER FAIRE AUTRE CHOSE."
			"PRENEZ UNE PAUSE."
			"ALLER PRENDRE UN CAFÉ."
		}
	}

	for key, value in pairs inspectSample
		["tasks.inspectSample.#{key}"] = value

	controls = {
		"map": "Ouvrir la carte / sabotage"
		"kill": "Meurtre"
		"use": "Utiliser"
		"report": "Reporter le corp"
		"hideTasks": "Cache la barre des tâches"
		"toggleNoClip": "Toggle ghost no-clip"
		"showHelp": "Ce menu"
	}

	for key, value in pairs controls
		["help.controls.#{key}"] = value

	tabs = {
		"color": "Couleur"
		"settings": "Paramètres"
		"game":  "Jeu"
		"controls": "Contrôles"
		"about": "A propos"
	}

	for key, value in pairs tabs
		["help.tab.#{key}"] = value

	settingsCvars = {
		"au_spectator_mode": "Mode spectateur"
		"au_debug_drawversion": "Afficher la version actuelle"
	}

	for key, value in pairs settingsCvars
		["help.settings.#{key}"] = value

	["sabotage.reactor.hold"] = "Maintenir pour stopper fusion"
	["sabotage.reactor.waiting"] = "En attente du 2e utilisateur"
	["sabotage.reactor.nominal"] = "Réacteur minime"
