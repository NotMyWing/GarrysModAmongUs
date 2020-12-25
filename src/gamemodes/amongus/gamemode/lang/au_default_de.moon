with GM.Lang\Get "de"
	["tasks.totalCompleted"] = "AUFGABEN ABGESCHLOSSEN"
	["tasks.totalCompleted.sabotaged"] = "KOMMUNIKATION SABOTIERT"

	["tasks.commsSabotaged"] = "Kommunikation sabotiert"
	["tasks.lightsSabotaged"] = "Lichter reparieren (%d%%)"
	["tasks.reactorSabotaged"] = "Reaktorschmelze in %d s. (%d/%d)"
	["tasks.oxygenSabotaged"] = "Kein Sauerstoff mehr in %d s. (%d/%d)"

	areas = {
		["cafeteria"]:      "Cafeteria"
		["upperEngine"]:   "Oberer Motor"
		["reactor"]:        "Reaktor"
		["lowerEngine"]:   "Unterer Motor"
		["security"]:       "Sicherheit"
		["electrical"]:     "Technikraum"
		["medbay"]:         "Krankenzimmer"
		["storage"]:        "Lagerraum"
		["shields"]:        "Schilde"
		["communications"]: "Kommunikation"
		["navigation"]:     "Navigation"
		["o2"]:             "O2"
		["admin"]:          "Admin"
		["weapons"]:        "Waffen"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "Strom umleiten zu #{areaName}"
		["vent.#{area}"] = "Zu #{areaName} venten"

	taskNames = {
		"divertPower": "Strom umleiten"
		"alignEngineOutput": "Motorausgang ausrichten"
		"calibrateDistributor": "Verteiler kalibrieren"
		"chartCourse": "Kurs zeichnen"
		"cleanO2Filter": "O2-Filter reinigen"
		"clearAsteroids": "Asteroiden zerstören"
		"emptyGarbage": "Müll leeren"
		"emptyChute": "Schacht leeren"
		"fixWiring": "Verkabelung reparieren"
		"inspectSample": "Probe inspizieren"
		"primeShields": "Schilde aktivieren"
		"stabilizeSteering": "Steuerung stabilisieren"
		"startReactor": "Reactor starten"
		"submitScan": "Scan übermitteln"
		"swipeCard": "Karte durchziehen"
		"unlockManifolds": "Verteiler entriegeln"
		"uploadData": "Daten herunterladen"
		"uploadData.2": "Daten hochladen"
		"fuelEngines": "Motoren tanken"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "Crewmitglieder müssen"
		}, {
			text: string.format "%ds", time
			color: Color 255, 0, 0
		}, {
			text: "vor der nächsten Notfallsitzung warten"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "Crewmitglied %s hat", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "Notfallsitzungen übrig"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "NOTFALLSITZUNGEN KÖNNEN NICHT WÄHREND"
		}, {
			text: "KRISEN EINBERUFEN WERDEN"
		}
	}

	["task.clearAsteroids.destroyed"] = "Zerstört: %d"

	["eject.remaining"] = (remaining) ->
		string.format "%d Verräter übrig.", remaining

	["eject.reason.tie"]     = "Niemand wurde rausgeworfen. (Gleichstand)"
	["eject.reason.skipped"] = "Niemand wurde rausgeworfen. (Übersprungen)"
	["eject.reason.generic"] = "Niemand wurde rausgeworfen."

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				if total == 1
					"%s war der Verräter."
				else
					"%s war ein Verräter."
			else
				"%s war kein Verräter."
		else
			"%s wurde rausgeworfen."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "Abstimmung startet in: %ds", time
	["meeting.timer.ends"]       = (time) -> string.format "Abstimmung endet in: %ds", time
	["meeting.timer.proceeding"] = (time) -> string.format "Fortsetzen in: %ds", time
	["meeting.header"] = "Wer ist der Verräter?"

	["splash.victory"] = "Sieg"
	["splash.defeat"]  = "Niederlage"
	["splash.imposter"]  = "Verräter"
	["splash.spectator"] = "Zuschauer"
	["splash.crewmate"]  = "Crewmitglied"
	["splash.text"] = (isPlaying, imposterCount) ->
		amongSubtext = isPlaying and "uns" or "ihnen"

		return if imposterCount == 1
			"Es ist %s Verräter unter " .. amongSubtext
		else
			"Es sind %s Verräter unter " .. amongSubtext

	["hud.sabotageAndKill"] = "Sabotiere und töte alle."
	["hud.countdown"] = "Startet in %d"
	["hud.tasks"] = "Aufgaben:"
	["hud.fakeTasks"] = "Vortäusch-Aufgaben:"
	["hud.taskComplete"] = "Aufgabe erledigt!"
	["hud.cvar.disabled"] = "Deaktiviert"
	["hud.cvar.enabled"] = "Aktiviert"
	["hud.cvar.time"] = "%d s."

	["hud.cvar.au_taskbar_updates.0"] = "Immer"
	["hud.cvar.au_taskbar_updates.1"] = "Sitzungen"
	["hud.cvar.au_taskbar_updates.2"] = "Nie"

	cvars = {
		au_max_imposters:    "Max. Verräter"
		au_kill_cooldown:    "Tötungsabklingzeit"
		au_time_limit:       "Zeitlimit"
		au_killdistance_mod: "Tötungsreichweite"
		sv_alltalk:          "Alle sprechen"
		au_taskbar_updates:  "Aufgabenfortschritt aktualisieren"
		au_player_speed_mod: "Spielergeschwindigkeit"

		au_meeting_available: "Sitzungen pro Spieler"
		au_meeting_cooldown:  "Abklingzeit Notfallsitzungen"
		au_meeting_vote_time: "Abstimmungszeit"
		au_meeting_vote_pre_time:  "Zeit vor Abstimmung"
		au_meeting_vote_post_time: "Zeit nach Abstimmung"
		au_confirm_ejects:         "Abstimmungen bestätigen"
		au_meeting_anonymous: "Anonymes abstimmen"

		au_tasks_short:  "Kurze Aufgaben"
		au_tasks_long:   "Lange Aufgaben"
		au_tasks_common: "Gewöhnliche Aufgaben"
		au_tasks_enable_visual: "Sichtbare Aufgaben"
	}

	for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vote.voted"] = "%s hat abgestimmt. %s verbleiben."

	["prepare.admin"] = "Du bist ein Admin!"
	["prepare.spectator"] = "Du bist ein Zuschauer."
	["prepare.pressToStart"] = "Drücke [%s] um das Spiel zu starten."

	["prepare.invalidMap"] = "Ungültige Karte!"
	["prepare.invalidMap.subText"] = "Keine manifest-Datei für die Karte gefunden."

	["prepare.warmup"] = "Aufwärmzeit!"
	["prepare.waitingForPlayers"] = "Auf Spieler warten..."
	["prepare.waitingForAdmin"] = "Auf Admin warten, welcher das Spiel startet."
	["prepare.commencing"] = "Das Spiel startet in %d s."
	["prepare.imposterCount"] = (count) ->
		string.format (if count == 1
			"%d Verräter"
		else
			"%d Verräter"), count

	["connected.spectating"] = "%s ist als Zuschauer beigetreten."
	["connected.spawned"] = "%s ist bereit zum spielen."
	["connected.disconnected"] = "%s hat das Spiel verlassen!"

	["chat.noTalkingDuringGame"] = "Du kannst während der Runde nicht reden!"

	inspectSample = {
		eta:           "ETA %d."
		addingReagent: "REAGENZ HINZUFÜGEN."
		oneMore:       "1 MEHR."
		testComplete:  "TEST ABGESCHLOSSEN."
		pressToStart:  "DRÜCKE UM ZU STARTEN  -->"
		selectAnomaly: "ANOMALIE AUSWÄHLEN."
		hello:         "HALLO."
		badResult:     "FALSCHES ERGEBNIS."
		thankYou:      "DANKE!"
		randomText: table.Random {
			"DU MUSST NICHT WARTEN."
			"GEHE ETWAS ANDERES MACHEN."
			"MACH PAUSE."
			"HOL DIR EINEN KAFFEE."
		}
	}

	for key, value in pairs inspectSample
		["tasks.inspectSample.#{key}"] = value

	controls = {
		"map": "Öffne die Karte / Sabotage"
		"kill": "Töten"
		"use": "Benutzen"
		"report": "Leiche melden"
		"hideTasks": "Aufgabenliste verstecken"
		"toggleNoClip": "Geister-No-Clip umstellen"
		"showHelp": "Dieses Menü"
	}

	for key, value in pairs controls
		["help.controls.#{key}"] = value

	tabs = {
		"color": "Farbe"
		"settings": "Einstellungen"
		"game":  "Spiel"
		"controls": "Steuerung"
		"about": "Über"
	}

	for key, value in pairs tabs
		["help.tab.#{key}"] = value

	settingsCvars = {
		"au_spectator_mode": "Zuschauermodus"
		"au_debug_drawversion": "Zeige die aktuelle Version an"
	}

	for key, value in pairs settingsCvars
		["help.settings.#{key}"] = value
