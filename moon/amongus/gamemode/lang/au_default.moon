with GM.Lang\Get "en"
	["tasks.total_completed"] = "TOTAL TASKS COMPLETED"

	areas = {
		["cafeteria"]:      "Cafeteria"
		["upper_engine"]:   "Upper Engine"
		["reactor"]:        "Reactor"
		["lower_engine"]:   "Lower Engine"
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
		"divertPower": "Divert Power"
		"alignEngineOutput": "Align Engine Output"
		"calibrateDistributor": "Calibrate Distributor"
		"chartCourse": "Chart Course"
		"cleanO2Filter": "Clean O2 Filter"
		"clearAsteroids": "Clear Asteroids"
		"emptyGarbage": "Empty Garbage"
		"emptyChute": "Empty Chute"
		"fixWiring": "Fix Wiring"
		"inspectSample": "Inspect Sample"
		"primeShields": "Prime Shields"
		"stabilizeSteering": "Stabilize Steering"
		"startReactor": "Start Reactor"
		"submitScan": "Submit Scan"
		"swipeCard": "Swipe Card"
		"unlockManifolds": "Unlock Manifolds"
		"uploadData": "Download Data"
		"uploadData.2": "Upload Data"
		"fuelEngines": "Fuel Engines"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meeting_button.cooldown"] = (time) -> {
		{
			text: "Crewmates Must Wait"
		}, {
			text: string.format "%ds", time
			color: Color 255, 0, 0
		}, {
			text: "Before The Emergency"
		}
	}

	["meeting_button.default"] = (nickname, uses) -> {
		{
			text: string.format "Crewmember %s Has", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "Emergency Meetings Left"
		}
	}

	["task.clearAsteroids.destroyed"] = "Destroyed: %d"

	["eject.remaining"] = (remaining) ->
		if remaining == 1
			string.format "1 Imposter remains."
		else
			string.format "%d Imposters remain.", remaining

	["eject.reason.tie"]     = "Nobody was ejected. (Tie)"
	["eject.reason.skipped"] = "Nobody was ejected. (Skipped)"
	["eject.reason.generic"] = "Nobody was ejected."

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				if total == 1
					"%s was The Imposter."
				else
					"%s was An Imposter."
			else
				if total == 1
					"%s was not The Imposter."
				else
					"%s was not An Imposter."
		else
			"%s was ejected."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "Voting Begins In: %ds", time
	["meeting.timer.ends"]       = (time) -> string.format "Voting Ends In: %ds", time
	["meeting.timer.proceeding"] = (time) -> string.format "Proceeding In: %ds", time
	["meeting.header"] = "Who Is The Imposter?"

	["splash.victory"] = "Victory"
	["splash.defeat"]  = "Defeat"
	["splash.imposter"]  = "Imposter"
	["splash.spectator"] = "Spectator"
	["splash.crewmate"]  = "Crewmate"
	["splash.text"] = (isPlaying, imposterCount) ->
		amongSubtext = isPlaying and "us" or "them"

		return if imposterCount == 1
			"There is %s Imposter among " .. amongSubtext
		else
			"There are %s Imposters among " .. amongSubtext

	["hud.countdown"] = "Starting in %d"
	["hud.tasks"] = "Tasks:"
	["hud.fakeTasks"] = "Fake Tasks:"
	["hud.taskComplete"] = "Task Complete!"
